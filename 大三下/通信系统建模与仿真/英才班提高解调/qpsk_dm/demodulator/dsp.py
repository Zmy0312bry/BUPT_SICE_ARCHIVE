import numpy as np
import scipy.signal

from demodulator.constants import PREAMBLE_SYMBOLS


def remove_dc(samples: np.ndarray) -> np.ndarray:
    return samples - np.mean(samples)


def estimate_carrier_offset_qpsk(
    samples: np.ndarray,
    sample_rate_hz: float,
    max_samples: int = 1_000_000,
) -> float:
    if len(samples) > max_samples:
        mid = len(samples) // 2
        half = max_samples // 2
        work = samples[mid - half : mid + half]
    else:
        work = samples

    work = remove_dc(work)
    nfft = 1 << int(np.ceil(np.log2(max(1024, len(work)))))
    window = np.hanning(len(work))
    spectrum = np.fft.fftshift(np.fft.fft(work**4 * window, nfft))
    freqs = np.fft.fftshift(np.fft.fftfreq(nfft, d=1.0 / sample_rate_hz))
    f_peak = freqs[np.argmax(np.abs(spectrum))]
    return f_peak / 4.0


def correct_frequency(
    samples: np.ndarray,
    sample_rate_hz: float,
    offset_hz: float,
) -> np.ndarray:
    n = np.arange(len(samples))
    return samples * np.exp(-2j * np.pi * offset_hz * n / sample_rate_hz)


def root_raised_cosine(alpha: float, span_symbols: int, sps: int) -> np.ndarray:
    t = np.arange(-span_symbols * sps / 2, span_symbols * sps / 2 + 1) / sps
    taps = np.zeros_like(t, dtype=float)

    for i, ti in enumerate(t):
        if abs(ti) < 1e-12:
            taps[i] = 1 - alpha + 4 * alpha / np.pi
        elif alpha > 0 and abs(abs(ti) - 1 / (4 * alpha)) < 1e-12:
            taps[i] = (alpha / np.sqrt(2)) * (
                (1 + 2 / np.pi) * np.sin(np.pi / (4 * alpha))
                + (1 - 2 / np.pi) * np.cos(np.pi / (4 * alpha))
            )
        else:
            numerator = np.sin(np.pi * ti * (1 - alpha)) + 4 * alpha * ti * np.cos(
                np.pi * ti * (1 + alpha)
            )
            denominator = np.pi * ti * (1 - (4 * alpha * ti) ** 2)
            taps[i] = numerator / denominator

    taps /= np.sqrt(np.sum(taps**2))
    return taps


def matched_filter(samples: np.ndarray, taps: np.ndarray) -> np.ndarray:
    return scipy.signal.lfilter(taps, [1.0], samples)


def normalized_preamble_correlation(
    symbols: np.ndarray,
    preamble: np.ndarray,
) -> np.ndarray:
    correlation = scipy.signal.correlate(symbols, preamble, mode="valid", method="fft")
    energy = scipy.signal.correlate(
        np.abs(symbols) ** 2,
        np.ones(preamble.size),
        mode="valid",
        method="fft",
    )
    denominator = np.sqrt(np.maximum(energy, 0) * np.sum(np.abs(preamble) ** 2))
    return np.abs(correlation) / (denominator + 1e-12)


def select_best_timing_phase(
    filtered: np.ndarray,
    sps: int,
    preamble: np.ndarray,
) -> tuple[int, np.ndarray, np.ndarray]:
    best_phase = 0
    best_symbols: np.ndarray = np.array([])
    best_correlation: np.ndarray = np.array([])
    best_peak = -1.0

    for phase in range(sps):
        symbols = filtered[phase::sps]
        correlation = normalized_preamble_correlation(symbols, preamble)
        peak = np.max(correlation)
        if peak > best_peak:
            best_peak = peak
            best_phase = phase
            best_symbols = symbols
            best_correlation = correlation

    return best_phase, best_symbols, best_correlation


def detect_preambles_all_phases(
    filtered: np.ndarray,
    sps: int,
    preamble: np.ndarray,
    threshold: float,
    min_distance_symbols: int,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    candidates: list[tuple[int, float, int, int]] = []
    per_phase_corrs: list[np.ndarray] = []

    for phase in range(sps):
        symbols = filtered[phase::sps]
        correlation = normalized_preamble_correlation(symbols, preamble)
        per_phase_corrs.append(correlation)

        peaks, properties = scipy.signal.find_peaks(
            correlation,
            height=threshold,
            distance=min_distance_symbols,
            prominence=max(0.05, threshold * 0.1),
        )
        for j, idx in enumerate(peaks):
            height = properties["peak_heights"][j]
            candidates.append((phase + sps * int(idx), float(height), phase, int(idx)))

    candidates.sort(key=lambda c: c[0])

    clusters: list[list[tuple[int, float, int, int]]] = []
    for c in candidates:
        if clusters and abs(c[0] - clusters[-1][-1][0]) <= 2 * sps:
            clusters[-1].append(c)
        else:
            clusters.append([c])

    selected = [max(cluster, key=lambda c: c[1]) for cluster in clusters]

    if selected:
        sample_starts = np.array([s[0] for s in selected], dtype=int)
        scores = np.array([s[1] for s in selected], dtype=float)
        phases = np.array([s[2] for s in selected], dtype=int)
    else:
        sample_starts = np.array([], dtype=int)
        scores = np.array([], dtype=float)
        phases = np.array([], dtype=int)

    min_len = min(len(c) for c in per_phase_corrs) if per_phase_corrs else 0
    if min_len > 0:
        stacked = np.stack([c[:min_len] for c in per_phase_corrs])
        combined_correlation = np.max(stacked, axis=0)
    else:
        combined_correlation = np.array([])

    return sample_starts, scores, phases, combined_correlation
