from math import ceil
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np

plt.style.use("ggplot")
plt.rcParams.update({
    "axes.facecolor": "white",
    "figure.facecolor": "white",
    "axes.edgecolor": "#333333",
    "grid.alpha": 0.15,
    "grid.color": "#CCCCCC",
    "font.sans-serif": ["PingFang SC", "Heiti SC", "Arial Unicode MS"],
    "axes.unicode_minus": False,
})

QPSK_REFS = np.array([1 + 1j, -1 + 1j, -1 - 1j, 1 - 1j])


def _limit(values: np.ndarray, count: int) -> np.ndarray:
    if values.size <= count:
        return values
    return values[np.linspace(0, values.size - 1, count).astype(int)]


def _save(fig: plt.Figure, path: Path, dpi: int) -> None:
    import warnings
    with warnings.catch_warnings():
        warnings.filterwarnings("ignore", message=".*tight_layout.*")
        fig.tight_layout(pad=1.2)
    fig.savefig(str(path), dpi=dpi, bbox_inches="tight")
    plt.close(fig)


def _draw_constellation(ax: plt.Axes, symbols: np.ndarray, max_points: int, title: str) -> None:
    data = _limit(symbols, max_points)
    ax.scatter(data.real, data.imag, s=5, c="#2166AC", alpha=0.6,
               edgecolors="none", linewidth=0, zorder=2)
    ax.scatter(QPSK_REFS.real, QPSK_REFS.imag, c="#E74C3C", marker="D", s=50,
               edgecolors="white", linewidths=1.5, zorder=5, label="理想 QPSK 星座点")
    ax.set_title(title, fontsize=11, fontweight="bold")
    ax.set_xlabel("同相分量 I", fontsize=9)
    ax.set_ylabel("正交分量 Q", fontsize=9)
    ax.set_aspect("equal")
    ax.axhline(y=0, color="#999999", linewidth=0.5, alpha=0.5)
    ax.axvline(x=0, color="#999999", linewidth=0.5, alpha=0.5)
    ax.set_xlim(-2.5, 2.5)
    ax.set_ylim(-2.5, 2.5)
    ax.grid(True, alpha=0.15)


def plot_received_signal(
    samples: np.ndarray,
    sample_rate_hz: float,
    path: Path,
    dpi: int,
) -> None:
    fig = plt.figure(figsize=(12, 7))
    gs = fig.add_gridspec(2, 1, height_ratios=[1, 1.2], hspace=0.3)

    ax_time = fig.add_subplot(gs[0])
    skip = int(sample_rate_hz * 0.001)
    n = min(3000, len(samples) - skip)
    offset = skip
    time_ms = np.arange(n) / sample_rate_hz * 1e3
    ax_time.plot(time_ms, samples[offset:offset + n].real, linewidth=0.7, alpha=0.85, label="I 路")
    ax_time.plot(time_ms, samples[offset:offset + n].imag, linewidth=0.7, alpha=0.85, label="Q 路")
    ax_time.fill_between(time_ms, samples[offset:offset + n].real, alpha=0.06, color="C0")
    ax_time.fill_between(time_ms, samples[offset:offset + n].imag, alpha=0.06, color="C1")
    ax_time.set_xlabel("时间 (ms)", fontsize=9)
    ax_time.set_ylabel("幅度", fontsize=9)
    ax_time.set_title("接收信号 — 时域", fontsize=11, fontweight="bold")
    ax_time.legend(loc="upper right", fontsize=8, framealpha=0.8)
    ax_time.grid(True, alpha=0.2)

    ax_psd = fig.add_subplot(gs[1])
    ax_psd.psd(samples, NFFT=4096, Fs=sample_rate_hz, sides="twosided",
               linewidth=0.8, alpha=0.9)
    ax_psd.set_xlabel("频率 (MHz)", fontsize=9)
    ax_psd.set_ylabel("功率谱密度 (dB/Hz)", fontsize=9)
    ax_psd.set_title("接收信号 — 功率谱密度", fontsize=11, fontweight="bold")
    ax_psd.grid(True, alpha=0.2)
    ax_psd.xaxis.set_major_formatter(ticker.FuncFormatter(lambda v, _: f"{v/1e6:.1f}"))

    _save(fig, path, dpi)


def plot_matched_filter_spectra(
    before: np.ndarray,
    after: np.ndarray,
    sample_rate_hz: float,
    path: Path,
    dpi: int,
) -> None:
    fig, (ax_before, ax_after) = plt.subplots(2, 1, figsize=(12, 7), sharex=True)

    for ax, data, title, color in [
        (ax_before, before, "匹配滤波前", "C3"),
        (ax_after, after, "匹配滤波后", "C2"),
    ]:
        ax.psd(data, NFFT=4096, Fs=sample_rate_hz, sides="twosided",
               linewidth=0.8, alpha=0.85, color=color)
        ax.set_title(title, fontsize=11, fontweight="bold")
        ax.set_ylabel("功率谱密度 (dB/Hz)", fontsize=9)
        ax.grid(True, alpha=0.2)

    ax_after.set_xlabel("频率 (MHz)", fontsize=9)
    ax_after.xaxis.set_major_formatter(ticker.FuncFormatter(lambda v, _: f"{v/1e6:.1f}"))

    _save(fig, path, dpi)


def plot_timing_constellations(
    filtered: np.ndarray,
    sampled: np.ndarray,
    path: Path,
    dpi: int,
    max_points: int,
) -> None:
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5.5))
    _draw_constellation(ax1, filtered, max_points, "最佳采样前")
    _draw_constellation(ax2, sampled, max_points, "最佳采样后")
    _save(fig, path, dpi)


def plot_eye_diagrams(
    filtered: np.ndarray,
    sps: int,
    best_phase: int,
    path: Path,
    dpi: int,
) -> None:
    cols = 4
    rows = ceil(sps / cols)
    fig, axes = plt.subplots(rows, cols, figsize=(14, 2.8 * rows))
    axes_flat = axes.flatten() if hasattr(axes, "flatten") else [axes]

    num_symbols = min(80, len(filtered) // sps - 2)
    start = len(filtered) // 2
    window = filtered[start:start + (num_symbols + 2) * sps]
    reshaped = window.reshape(-1, sps)

    for phase in range(sps):
        ax = axes_flat[phase]
        shifted = np.roll(reshaped, -phase, axis=1)

        for i in range(min(num_symbols, shifted.shape[0] - 1)):
            segment_i = np.concatenate([shifted[i], shifted[i + 1]])
            t = np.arange(2 * sps)
            ax.plot(t, segment_i.real, color="#2166AC", alpha=0.45, linewidth=0.6,
                    label="I 路" if i == 0 else "")
            ax.plot(t, segment_i.imag, color="#B2182B", alpha=0.45, linewidth=0.6,
                    label="Q 路" if i == 0 else "")

        ax.axvline(x=sps - 0.5, color="#333333", linewidth=0.8, linestyle="--", alpha=0.3)

        ax.set_title(f"相位 {phase + 1}", fontsize=10)

        if phase == 0:
            ax.legend(loc="upper right", fontsize=7, framealpha=0.7, ncol=1)

        ax.set_xlim(0, 2 * sps - 1)
        ax.grid(True, alpha=0.2)
        ax.set_xticks([0, sps, 2 * sps - 1])
        ax.set_xticklabels(["0", "T", "2T"])
        ax.set_yticklabels([])

    for phase in range(sps, len(axes_flat)):
        axes_flat[phase].set_visible(False)

    _save(fig, path, dpi)


def plot_sync_correlation(
    correlation: np.ndarray,
    frame_starts: np.ndarray,
    path: Path,
    dpi: int,
) -> None:
    fig, ax = plt.subplots(figsize=(14, 4.5))

    if frame_starts.size >= 5:
        lo = max(0, int(frame_starts[0]) - 60)
        hi = min(len(correlation), int(frame_starts[4]) + 60)
    elif frame_starts.size >= 1:
        lo = max(0, int(frame_starts[0]) - 60)
        hi = min(len(correlation), int(frame_starts[-1]) + 60)
    else:
        lo, hi = 0, len(correlation)

    region = slice(lo, hi)
    x = np.arange(lo, hi)
    ax.plot(x, correlation[region], linewidth=0.9, color="#2C3E50", label="相关系数")
    ax.fill_between(x, correlation[region], alpha=0.08, color="#2C3E50")

    ax.axhline(y=0.75, color="gray", linewidth=1, linestyle="--", alpha=0.5, label="阈值 (0.75)")

    for fs in frame_starts:
        fs_int = int(fs)
        if lo <= fs_int < hi:
            local_lo = max(0, fs_int - 2)
            local_hi = min(len(correlation), fs_int + 3)
            local_peak = local_lo + np.argmax(correlation[local_lo:local_hi])
            ax.scatter(local_peak, correlation[local_peak], c="#E74C3C", s=35,
                       edgecolors="white", linewidth=1, zorder=5)
            ax.axvline(x=fs_int, ymin=0, ymax=0.15, color="#E74C3C",
                       linewidth=0.8, alpha=0.4, linestyle=":")

    visible_starts = [int(fs) for fs in frame_starts if lo <= int(fs) < hi]
    if len(visible_starts) >= 2:
        x1, x2 = visible_starts[0], visible_starts[1]
        mid = (x1 + x2) / 2
        spacing = x2 - x1
        ax.annotate("", xy=(x1, 0.76), xytext=(x2, 0.76),
                    arrowprops=dict(arrowstyle="<->", color="#E67E22", lw=1.5))
        ax.text(mid, 0.79, f"{spacing} 符号", ha="center", va="bottom",
                fontsize=9, color="#E67E22", fontweight="bold",
                bbox=dict(boxstyle="round,pad=0.25", facecolor="white", edgecolor="#E67E22", alpha=0.9))

    ax.set_xlabel("QPSK 符号索引", fontsize=10)
    ax.set_ylabel("归一化相关系数", fontsize=10)
    ax.set_title("前导码同步检测", fontsize=13, fontweight="bold")
    ax.legend(loc="upper right", fontsize=9, framealpha=0.8, ncol=1)
    ax.grid(True, alpha=0.2)
    ax.set_ylim(-0.05, 1.08)

    _save(fig, path, dpi)


def plot_channel_and_compensation(
    payload: np.ndarray,
    compensated: np.ndarray,
    pilot_positions: np.ndarray,
    channel_values: np.ndarray,
    symbol_rate_hz: float,
    path: Path,
    dpi: int,
    max_points: int,
) -> None:
    fig = plt.figure(figsize=(14, 10))
    gs = fig.add_gridspec(2, 2, hspace=0.35, wspace=0.3)

    ax_before = fig.add_subplot(gs[0, 0])
    _draw_constellation(ax_before, payload, max_points, "信道补偿前")

    ax_after = fig.add_subplot(gs[0, 1])
    _draw_constellation(ax_after, compensated, max_points, "信道补偿后")

    ax_time = fig.add_subplot(gs[1, 0])
    ax_time.plot(pilot_positions, np.abs(channel_values), color="#2166AC",
                 linewidth=1.5, marker="o", markersize=5, label="幅度 |h|")
    ax_time.set_xlabel("载荷符号索引", fontsize=9)
    ax_time.set_ylabel("幅度 |h|", fontsize=9, color="#2166AC")
    ax_time.tick_params(axis="y", labelcolor="#2166AC")
    ax_time.set_title("信道时域响应", fontsize=11, fontweight="bold")

    ax_phase = ax_time.twinx()
    ax_phase.plot(pilot_positions, np.unwrap(np.angle(channel_values)), color="#B2182B",
                  linewidth=1.5, marker="s", markersize=5, label="相位 ∠h")
    ax_phase.set_ylabel("相位 (rad)", fontsize=9, color="#B2182B")
    ax_phase.tick_params(axis="y", labelcolor="#B2182B")

    lines1, labels1 = ax_time.get_legend_handles_labels()
    lines2, labels2 = ax_phase.get_legend_handles_labels()
    ax_time.legend(lines1 + lines2, labels1 + labels2, loc="upper right", fontsize=8, framealpha=0.8)
    ax_time.grid(True, alpha=0.2)

    ax_freq = fig.add_subplot(gs[1, 1])
    if channel_values.size > 1:
        impulse = np.fft.ifft(channel_values)
        freq_response = np.fft.fftshift(np.fft.fft(impulse))
        freqs = np.fft.fftshift(np.fft.fftfreq(len(freq_response), d=1.0 / symbol_rate_hz))
        mag_db = 20 * np.log10(np.abs(freq_response) + 1e-12)
        ax_freq.plot(freqs, mag_db, linewidth=1.2, color="#2C3E50")
        ax_freq.fill_between(freqs, mag_db, -80, alpha=0.08, color="#2C3E50")
        ax_freq.set_xlabel("频率 (Hz)", fontsize=9)
        ax_freq.set_ylabel("幅度 (dB)", fontsize=9)
        ax_freq.set_ylim(max(np.min(mag_db) - 10, -60), max(np.max(mag_db) + 5, 0))
        ax_freq.axhline(y=0, color="gray", linewidth=0.5, alpha=0.3, linestyle="--")
    ax_freq.set_title("信道频域响应", fontsize=11, fontweight="bold")
    ax_freq.grid(True, alpha=0.2)

    _save(fig, path, dpi)
