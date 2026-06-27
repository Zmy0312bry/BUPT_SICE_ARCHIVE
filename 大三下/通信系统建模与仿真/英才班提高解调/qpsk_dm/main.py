import argparse
import json
import sys
from pathlib import Path

import numpy as np

from demodulator.constants import (
    DATA_SYMBOLS_PER_PILOT,
    PILOT_SYMBOLS_PER_INSERTION,
    PREAMBLE_SYMBOLS,
)
from demodulator.dsp import (
    correct_frequency,
    detect_preambles_all_phases,
    estimate_carrier_offset_qpsk,
    matched_filter,
    remove_dc,
    root_raised_cosine,
    select_best_timing_phase,
)
from demodulator.frame import (
    calculate_ber,
    decode_frames_from_filtered,
    estimate_frame_length,
    estimate_groups_per_frame,
    infer_base_data,
)
from demodulator.io import load_dat, load_yaml_config
from demodulator.plots import (
    plot_channel_and_compensation,
    plot_eye_diagrams,
    plot_matched_filter_spectra,
    plot_received_signal,
    plot_sync_correlation,
    plot_timing_constellations,
)

OUTPUT_FRAME_INDEX = 1
PRINT_FRAME_COUNT = 3
PREAMBLE_THRESHOLD = 0.75
PREAMBLE_MIN_DISTANCE = 100
BER_MIN_DURATION = 2.0
MAX_CONSTELLATION_POINTS = 6000
FIGURE_DPI = 160
DEFAULT_SAMPLE_RATE_HZ = 2_400_000


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="QPSK demodulator for rtl_sdr .dat files"
    )
    parser.add_argument("config", type=Path, help="YAML config file path")
    parser.add_argument(
        "--sample-rate",
        type=float,
        default=DEFAULT_SAMPLE_RATE_HZ,
        dest="sample_rate_hz",
        help=f"Sample rate in Hz (default: {DEFAULT_SAMPLE_RATE_HZ})",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("output"),
        dest="output_dir",
        help="Output directory (default: output)",
    )
    parser.add_argument(
        "--frame-index",
        type=int,
        default=OUTPUT_FRAME_INDEX,
        dest="frame_index",
        help=f"Which frame to output as payload (1-based, default: {OUTPUT_FRAME_INDEX})",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    config = load_yaml_config(args.config)
    dat_path = Path(config["dat_path"])
    span = config["span"]
    sps = config["sps"]
    alpha = config["alpha"]
    base_data_len = len(config["basedata"])
    sample_rate_hz = args.sample_rate_hz

    output_dir = args.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 64)
    print(f"QPSK Demodulator — {dat_path.name}")
    print("=" * 64)
    print(f"  Config:   {args.config}")
    print(f"  Data:     {dat_path}")
    print(f"  Params:   alpha={alpha}, span={span}, sps={sps}")
    print(f"  BaseData: {config['basedata']!r} (len={base_data_len})")
    print(f"  SR:       {sample_rate_hz:.0f} Hz")

    samples = load_dat(dat_path)
    num_samples = len(samples)
    duration = num_samples / sample_rate_hz
    print(f"  Samples:  {num_samples}")
    print(f"  Duration: {duration:.3f} s")

    if duration < BER_MIN_DURATION:
        print(
            f"  WARNING: duration < {BER_MIN_DURATION}s, BER stats may be insufficient"
        )

    samples = remove_dc(samples)
    print(f"  DC offset removed")

    carrier_offset = estimate_carrier_offset_qpsk(samples, sample_rate_hz)
    print(f"  Carrier offset: {carrier_offset:.3f} Hz")
    samples = correct_frequency(samples, sample_rate_hz, carrier_offset)

    plot_received_signal(
        samples,
        sample_rate_hz,
        output_dir / "01_received_signal.png",
        FIGURE_DPI,
    )

    taps = root_raised_cosine(alpha, span, sps)
    filtered = matched_filter(samples, taps)
    print(f"  RRC filter: {len(taps)} taps (alpha={alpha}, span={span}, sps={sps})")

    plot_matched_filter_spectra(
        samples,
        filtered,
        sample_rate_hz,
        output_dir / "02_matched_filter_spectra.png",
        FIGURE_DPI,
    )

    best_phase, best_symbols, timing_corr = select_best_timing_phase(
        filtered,
        sps,
        PREAMBLE_SYMBOLS,
    )
    print(f"  Best timing phase: {best_phase + 1}/{sps}")
    print(f"  Max preamble correlation: {np.max(timing_corr):.6f}")

    plot_timing_constellations(
        filtered,
        best_symbols,
        output_dir / "03_timing_constellations.png",
        FIGURE_DPI,
        MAX_CONSTELLATION_POINTS,
    )
    plot_eye_diagrams(
        filtered,
        sps,
        best_phase,
        output_dir / "03_eye_diagrams.png",
        FIGURE_DPI,
    )

    frame_starts, peak_scores, frame_phases, combined_corr = (
        detect_preambles_all_phases(
            filtered,
            sps,
            PREAMBLE_SYMBOLS,
            PREAMBLE_THRESHOLD,
            PREAMBLE_MIN_DISTANCE,
        )
    )
    symbol_starts = np.rint(frame_starts / sps).astype(int)

    if len(frame_starts) < 2:
        print("ERROR: fewer than 2 preambles detected", file=sys.stderr)
        print("Check sample rate, RRC params, carrier offset, or preamble threshold")
        return 1

    print(f"  Detected frames: {len(frame_starts)}")
    print(f"  Max correlation: {peak_scores.max():.6f}")

    frame_len_samples = estimate_frame_length(frame_starts)
    frame_len_symbols = int(round(frame_len_samples / sps))
    print(f"  Frame length: {frame_len_symbols} QPSK symbols")

    plot_sync_correlation(
        combined_corr,
        symbol_starts,
        output_dir / "04_preamble_correlation.png",
        FIGURE_DPI,
    )

    groups = estimate_groups_per_frame(
        frame_len_symbols,
        base_data_len,
        DATA_SYMBOLS_PER_PILOT,
        PILOT_SYMBOLS_PER_INSERTION,
    )
    burst_time = groups
    print(f"  Groups per frame (burst_time): {burst_time}")

    frames = decode_frames_from_filtered(
        filtered,
        frame_starts,
        peak_scores,
        sps,
        frame_len_symbols,
        groups,
        base_data_len,
        DATA_SYMBOLS_PER_PILOT,
        PILOT_SYMBOLS_PER_INSERTION,
    )
    print(f"  Successfully decoded: {len(frames)} frames")

    base_data_inferred = infer_base_data(frames, base_data_len)
    if base_data_inferred:
        print(f"  Inferred base_data: {base_data_inferred!r}")
    else:
        print("  WARNING: could not infer base_data")

    bit_errors, bit_count, ber = calculate_ber(frames, base_data_inferred, groups)
    if ber is not None:
        print(f"  BER: {ber:.6e} ({bit_errors} errors / {bit_count} bits)")
    else:
        print("  BER: N/A (no reference)")

    frame_idx = args.frame_index - 1
    if frame_idx >= len(frames):
        print(
            f"  WARNING: frame {args.frame_index} not found ({len(frames)} total), using last"
        )
        frame_idx = len(frames) - 1
    if frames:
        payload_text = frames[frame_idx].text
        payload_path = output_dir / f"frame_{args.frame_index}_payload.txt"
        payload_path.write_text(payload_text, encoding="utf-8")
        print(f"\n  Frame {frame_idx + 1} payload ({payload_path}):")
        print("  " + "-" * 48)
        for line in payload_text.strip().split("\n"):
            print(f"    {line}")

    if frames:
        frame = frames[min(frame_idx, len(frames) - 1)]
        plot_channel_and_compensation(
            frame.payload_symbols,
            frame.compensated_data_symbols,
            frame.channel_pilot_positions,
            frame.channel_pilot_values,
            sample_rate_hz / sps,
            output_dir / "05_channel_compensation.png",
            FIGURE_DPI,
            MAX_CONSTELLATION_POINTS,
        )

    for i, frame in enumerate(frames[:PRINT_FRAME_COUNT]):
        print(
            f"  [FRAME {i + 1}] start={frame.start_symbol}, corr={frame.correlation:.6f}"
        )

    results = {
        "dat_path": str(dat_path),
        "num_samples": num_samples,
        "duration_s": duration,
        "sample_rate_hz": sample_rate_hz,
        "alpha": alpha,
        "span": span,
        "sps": sps,
        "carrier_offset_hz": carrier_offset,
        "best_timing_phase": best_phase,
        "max_preamble_corr": float(peak_scores.max()) if len(peak_scores) > 0 else None,
        "detected_frames": int(len(frame_starts)),
        "decoded_frames": len(frames),
        "frame_length_symbols": frame_len_symbols,
        "burst_time": burst_time,
        "base_data_len": base_data_len,
        "basedata_config": config["basedata"],
        "basedata_inferred": base_data_inferred,
        "ber": ber,
        "bit_errors": bit_errors,
        "bit_count": bit_count,
    }
    (output_dir / "results.json").write_text(
        json.dumps(results, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"\n  Output: {output_dir.resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
