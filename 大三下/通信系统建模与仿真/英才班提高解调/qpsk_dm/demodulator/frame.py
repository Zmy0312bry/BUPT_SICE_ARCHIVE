from dataclasses import dataclass
from math import ceil
import re

import numpy as np

from demodulator.constants import (
    DATA_SYMBOLS_PER_PILOT,
    PILOT_SYMBOLS_PER_INSERTION,
    PREAMBLE_SYMBOLS,
    REFERENCE_SYMBOLS,
)


@dataclass
class DecodedFrame:
    start_symbol: int
    end_symbol: int
    correlation: float
    groups: int
    text: str
    payload_symbols: np.ndarray
    compensated_data_symbols: np.ndarray
    channel_pilot_positions: np.ndarray
    channel_pilot_values: np.ndarray
    bit_errors: int | None = None
    bit_count: int | None = None


def estimate_frame_length(frame_starts: np.ndarray) -> int:
    diffs = np.diff(frame_starts)
    median_diff = np.median(diffs)
    valid = diffs[np.abs(diffs - median_diff) <= max(2, 0.02 * median_diff)]
    return int(round(np.mean(valid)))


def group_character_count(base_data_len: int) -> int:
    return base_data_len + 4


def group_symbol_count(
    base_data_len: int,
    data_symbols_per_pilot: int,
    pilot_symbols_per_insertion: int,
) -> int:
    chars = group_character_count(base_data_len)
    data_syms = chars * 4
    insertions = ceil(data_syms / data_symbols_per_pilot)
    return data_syms + insertions * pilot_symbols_per_insertion


def estimate_groups_per_frame(
    frame_length_symbols: int,
    base_data_len: int,
    data_symbols_per_pilot: int,
    pilot_symbols_per_insertion: int,
) -> int:
    payload_length = frame_length_symbols - PREAMBLE_SYMBOLS.size
    per_group = group_symbol_count(
        base_data_len, data_symbols_per_pilot, pilot_symbols_per_insertion
    )
    groups = int(round(payload_length / per_group))
    if groups < 1 or payload_length != groups * per_group:
        raise ValueError(
            f"Payload length {payload_length} not divisible by per-group {per_group}"
        )
    return groups


def _pilot_layout(
    groups: int,
    base_data_len: int,
    data_symbols_per_pilot: int,
    pilot_symbols_per_insertion: int,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    assert pilot_symbols_per_insertion == 1
    group_len = group_symbol_count(
        base_data_len, data_symbols_per_pilot, pilot_symbols_per_insertion
    )
    pilot_positions: list[int] = []
    data_positions: list[int] = []
    expected_pilots: list[complex] = []
    for g in range(groups):
        base = g * group_len
        data_remaining = group_character_count(base_data_len) * 4
        pos = 0
        pilot_idx = 0
        while data_remaining > 0:
            chunk = min(data_symbols_per_pilot, data_remaining)
            for i in range(chunk):
                data_positions.append(base + pos + i)
            data_remaining -= chunk
            pos += chunk
            pilot_positions.append(base + pos)
            expected_pilots.append(
                REFERENCE_SYMBOLS[pilot_idx % len(REFERENCE_SYMBOLS)]
            )
            pilot_idx += 1
            pos += 1
    return (
        np.array(pilot_positions, dtype=np.intp),
        np.array(expected_pilots, dtype=np.complex128),
        np.array(data_positions, dtype=np.intp),
    )


def pilot_aided_compensate(
    payload: np.ndarray,
    groups: int,
    base_data_len: int,
    data_symbols_per_pilot: int,
    pilot_symbols_per_insertion: int,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    pilot_positions, expected_pilots, data_positions = _pilot_layout(
        groups, base_data_len, data_symbols_per_pilot, pilot_symbols_per_insertion
    )
    received_pilots = payload[pilot_positions]
    channel_at_pilots = received_pilots / expected_pilots
    all_positions = np.arange(payload.size)
    channel_real = np.interp(all_positions, pilot_positions, channel_at_pilots.real)
    channel_imag = np.interp(all_positions, pilot_positions, channel_at_pilots.imag)
    channel = channel_real + 1j * channel_imag
    safe_channel = np.where(np.abs(channel) < 1e-10, 1e-10, channel)
    compensated = payload / safe_channel
    return (
        compensated[data_positions],
        pilot_positions,
        channel_at_pilots,
        data_positions,
    )


def qpsk_symbols_to_bits(symbols: np.ndarray) -> np.ndarray:
    i_part = symbols.real
    q_part = symbols.imag
    bits = np.empty(2 * symbols.size, dtype=np.uint8)
    bits[0::2] = np.where(
        (i_part >= 0) & (q_part >= 0),
        0,
        np.where(
            (i_part < 0) & (q_part < 0), 1, np.where((i_part >= 0) & (q_part < 0), 1, 0)
        ),
    )
    bits[1::2] = np.where(
        (i_part >= 0) & (q_part >= 0),
        0,
        np.where(
            (i_part < 0) & (q_part >= 0), 1, np.where((i_part < 0) & (q_part < 0), 1, 0)
        ),
    )
    return bits


def bits_to_text(bits: np.ndarray) -> str:
    trimmed = bits[: len(bits) // 8 * 8]
    if trimmed.size == 0:
        return ""
    byte_vals = trimmed.reshape(-1, 8).dot(
        np.array([128, 64, 32, 16, 8, 4, 2, 1], dtype=np.uint8)
    )
    return byte_vals.tobytes().decode("ascii", errors="replace")


def text_to_bits(text: str) -> np.ndarray:
    return np.unpackbits(np.frombuffer(text.encode("ascii"), dtype=np.uint8))


def decode_frames_from_filtered(
    filtered: np.ndarray,
    frame_sample_starts: np.ndarray,
    correlation_scores: np.ndarray,
    sps: int,
    frame_length_symbols: int,
    groups: int,
    base_data_len: int,
    data_symbols_per_pilot: int,
    pilot_symbols_per_insertion: int,
) -> list[DecodedFrame]:
    frames: list[DecodedFrame] = []
    for sample_start, score in zip(frame_sample_starts, correlation_scores):
        sample_end = sample_start + frame_length_symbols * sps
        if sample_end > filtered.size:
            continue
        frame_symbols = filtered[sample_start:sample_end:sps]
        payload = frame_symbols[PREAMBLE_SYMBOLS.size :]
        compensated_data, pilot_pos, channel_vals, data_pos = pilot_aided_compensate(
            payload,
            groups,
            base_data_len,
            data_symbols_per_pilot,
            pilot_symbols_per_insertion,
        )
        bits = qpsk_symbols_to_bits(compensated_data)
        text = bits_to_text(bits)
        start_symbol = sample_start // sps
        end_symbol = sample_end // sps
        frames.append(
            DecodedFrame(
                start_symbol=start_symbol,
                end_symbol=end_symbol,
                correlation=float(score),
                groups=groups,
                text=text,
                payload_symbols=payload,
                compensated_data_symbols=compensated_data,
                channel_pilot_positions=pilot_pos,
                channel_pilot_values=channel_vals,
            )
        )
    return frames


def infer_base_data(frames: list[DecodedFrame], base_data_len: int) -> str | None:
    if not frames:
        return None
    pattern = rf"(.{{{base_data_len}}})\d{{3}}\n"
    candidates: list[str] = []
    for frame in frames:
        m = re.search(pattern, frame.text)
        if m:
            candidates.append(m.group(1))
    if not candidates:
        return None
    values, counts = np.unique(candidates, return_counts=True)
    return str(values[np.argmax(counts)])


def expected_frame_text(base_data: str, groups: int) -> str:
    return "".join(f"{base_data}{i:03d}\n" for i in range(1, groups + 1))


def calculate_ber(
    frames: list[DecodedFrame],
    base_data: str | None,
    groups: int,
) -> tuple[int, int, float | None]:
    if base_data is None:
        return 0, 0, None
    expected_bits = text_to_bits(expected_frame_text(base_data, groups))
    total_errors = 0
    total_bits = 0
    for frame in frames:
        received_bits = qpsk_symbols_to_bits(frame.compensated_data_symbols)
        count = min(received_bits.size, expected_bits.size)
        total_errors += int(np.sum(received_bits[:count] != expected_bits[:count]))
        total_bits += count
    ber = total_errors / total_bits if total_bits > 0 else None
    return total_errors, total_bits, ber
