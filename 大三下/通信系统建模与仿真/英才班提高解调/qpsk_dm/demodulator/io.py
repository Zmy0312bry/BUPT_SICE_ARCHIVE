"""File I/O: .dat IQ sample loading and YAML config parsing."""

from pathlib import Path

import numpy as np
import yaml


def load_dat(filepath: str | Path) -> np.ndarray:
    """Load rtl_sdr .dat file (uint8 IQIQ interleaved) as complex128 array.

    Conversion: complex[n] = (I[n] - 127.5) / 127.5 + j * (Q[n] - 127.5) / 127.5
    """
    filepath = Path(filepath)
    if not filepath.exists():
        raise FileNotFoundError(f"Data file not found: {filepath}")

    raw = np.fromfile(filepath, dtype=np.uint8)
    i_samples = raw[0::2].astype(np.float64)
    q_samples = raw[1::2].astype(np.float64)

    return (i_samples - 127.5) / 127.5 + 1j * (q_samples - 127.5) / 127.5


def load_yaml_config(yaml_path: str | Path) -> dict:

    yaml_path = Path(yaml_path)
    with open(yaml_path) as f:
        raw = yaml.safe_load(f)

    dat_path = raw["protocol"].removeprefix("file://")
    if not Path(dat_path).exists():
        raise FileNotFoundError(f"Data file not found: {dat_path}")

    return {
        "dat_path": dat_path,
        "span": int(raw["span"]),
        "sps": int(raw["sps"]),
        "alpha": float(raw["alpha"]),
        "basedata": str(raw["basedata"]),
        "verbose": bool(raw["verbose"]),
    }
