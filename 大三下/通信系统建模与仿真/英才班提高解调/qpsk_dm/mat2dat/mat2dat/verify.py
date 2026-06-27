"""Module for verifying .dat file integrity and I/Q balance."""

import os

import numpy as np

MAX_IQ_IMBALANCE: float = 10.0


def verify_dat(filepath: str) -> dict[str, bool | str | int | float]:
    """Verify a .dat file's integrity and I/Q channel balance.

    Args:
        filepath: Path to the .dat file.

    Returns:
        Dict with keys: size_even, value_range_ok, iq_balance_ok,
        num_samples, i_mean, q_mean. On error, includes error info.
    """
    result: dict[str, bool | str | int | float] = {}

    if not os.path.exists(filepath):
        result["error"] = f"File not found: {filepath}"
        return result

    file_size = os.path.getsize(filepath)
    result["size_even"] = file_size % 2 == 0

    try:
        data = np.fromfile(filepath, dtype=np.uint8)
    except Exception as e:
        result["error"] = f"Cannot read file: {e}"
        return result

    result["num_samples"] = len(data) // 2
    result["value_range_ok"] = bool(np.all((data >= 0) & (data <= 255)))

    i_samples = data[0::2].astype(np.float64)
    q_samples = data[1::2].astype(np.float64)
    i_mean = float(np.mean(i_samples))
    q_mean = float(np.mean(q_samples))
    result["i_mean"] = i_mean
    result["q_mean"] = q_mean
    result["iq_balance_ok"] = abs(i_mean - q_mean) < MAX_IQ_IMBALANCE

    return result


def format_verify_result(result: dict[str, bool | str | int | float]) -> str:
    """Format verification result as a human-readable tree string."""
    if "error" in result:
        error_msg = str(result.get("error", ""))
        return f"Verification Error: {error_msg}"

    size_ok = bool(result.get("size_even", False))
    size_str = f"File size (even: {'OK' if size_ok else 'FAIL'})"
    lines = [f"├── {size_str}"]

    range_ok = bool(result.get("value_range_ok", False))
    range_str = f"Value range: [0, 255] ({'OK' if range_ok else 'FAIL'})"
    lines.append(f"├── {range_str}")

    i_mean = float(result.get("i_mean", 0.0))
    q_mean = float(result.get("q_mean", 0.0))
    iq_ok = bool(result.get("iq_balance_ok", False))
    iq_diff = abs(i_mean - q_mean)
    iq_str = (
        f"I/Q balance: I_mean={i_mean:.1f}, Q_mean={q_mean:.1f}, "
        f"diff={iq_diff:.1f} ({'OK' if iq_ok else 'FAIL'})"
    )
    lines.append(f"├── {iq_str}")

    checks = ("size_even", "value_range_ok", "iq_balance_ok")
    all_ok = all(bool(result.get(k, False)) for k in checks)
    status = "ALL CHECKS PASSED" if all_ok else "SOME CHECKS FAILED"
    lines.append(f"└── Result: {status}")

    return "Verification Results\n" + "\n".join(lines)
