"""mat2dat — CLI entry point for MATLAB .mat to rtl_sdr .dat conversion."""

import argparse
import sys

from mat2dat.converter import Mat2DatError, convert_mat_to_dat
from mat2dat.verify import format_verify_result, verify_dat


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert MATLAB .mat IQ recordings to rtl_sdr-compatible .dat files."
    )
    parser.add_argument("input", help="Input .mat file path")
    parser.add_argument("output", help="Output .dat file path")
    parser.add_argument(
        "-r",
        "--sample-rate",
        type=float,
        dest="sample_rate",
        help="Sample rate in Hz (overrides auto-detection)",
    )
    parser.add_argument(
        "-v",
        "--verify",
        action="store_true",
        help="Verify the output .dat file after conversion",
    )

    args = parser.parse_args()

    try:
        num_samples, fs = convert_mat_to_dat(args.input, args.output, args.sample_rate)
    except (Mat2DatError, FileNotFoundError, Exception) as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    if fs is not None:
        print(f"Converted {num_samples} samples to {args.output} @ {fs} Hz")
    else:
        print(f"Converted {num_samples} samples to {args.output}")

    if args.verify:
        result = verify_dat(args.output)
        print(format_verify_result(result))


if __name__ == "__main__":
    main()
