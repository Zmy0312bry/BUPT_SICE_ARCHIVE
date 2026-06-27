"""mat2dat — MATLAB .mat to rtl_sdr .dat IQ sample converter.

Conversion formula:
    uint8 = clamp(round((val + 1.0) * 127.5), 0, 255)

This evenly distributes 256 levels across [-1, +1] with zero at exactly 128.
"""

from pathlib import Path

import h5py
import numpy as np

CONVERSION_SCALE: float = 127.5
CONVERSION_OFFSET: int = 128
DTYPE_OUTPUT: type = np.uint8

type IQArray = np.ndarray


class Mat2DatError(Exception):
    pass


class MatReadError(Mat2DatError):
    pass


_EXPECTED_DTYPE = np.dtype([("real", "<f8"), ("imag", "<f8")])
_Z_PATH = "#refs#/z"
_P_PATH = "#refs#/p"


def read_mat_iq(
    filepath: str | Path,
) -> tuple[np.ndarray, np.ndarray, float | None]:
    """Read IQ samples from a MATLAB .mat (HDF5) file. Returns (i, q, fs|None)."""
    path = Path(filepath)
    if not path.exists():
        raise FileNotFoundError(f"File not found: {path}")

    try:
        with h5py.File(path, "r") as f:
            if _Z_PATH not in f:
                raise MatReadError(f"Missing key '{_Z_PATH}' in {path.name}")

            z = f[_Z_PATH]

            if z.dtype != _EXPECTED_DTYPE:
                raise MatReadError(
                    f"Unexpected dtype for '{_Z_PATH}': "
                    f"got {z.dtype}, expected {_EXPECTED_DTYPE}"
                )

            if z.ndim == 2:
                return _read_2d(f, z)
            elif z.ndim == 1:
                return _read_1d(z)
            else:
                raise MatReadError(
                    f"Unexpected ndim={z.ndim} for '{_Z_PATH}' in {path.name}"
                )

    except (OSError,) as exc:
        if isinstance(exc, (FileNotFoundError, MatReadError)):
            raise
        raise MatReadError(f"Cannot open {path.name}: {exc}") from exc


def _read_2d(
    f: h5py.File,
    z: h5py.Dataset,
) -> tuple[np.ndarray, np.ndarray, float | None]:
    n_blocks, block_size = z.shape
    total = n_blocks * block_size
    i_arr = np.empty(total, dtype=np.float64)
    q_arr = np.empty(total, dtype=np.float64)

    for blk_idx in range(n_blocks):
        block = z[blk_idx]
        offset = blk_idx * block_size
        i_arr[offset : offset + block_size] = block["real"]
        q_arr[offset : offset + block_size] = block["imag"]

    sample_rate: float | None = None
    if _P_PATH in f:
        p_flat = f[_P_PATH][:].ravel()
        if len(p_flat) > 1:
            dt = float(np.mean(np.diff(p_flat)))
            if dt > 0:
                sample_rate = block_size / dt

    return i_arr, q_arr, sample_rate


def _read_1d(
    z: h5py.Dataset,
) -> tuple[np.ndarray, np.ndarray, None]:
    i_arr = z["real"][:].astype(np.float64)
    q_arr = z["imag"][:].astype(np.float64)
    return i_arr, q_arr, None


def convert_to_uint8(
    i_arr: np.ndarray,
    q_arr: np.ndarray,
) -> tuple[np.ndarray, np.ndarray]:
    """Scale float64 [-1, +1] IQ arrays to uint8 [0, 255].

    Formula: round((val + 1.0) * 127.5), clipped to [0, 255].
    Values outside [-1, +1] are clamped (handles minor overshoot).
    """
    i_u8 = np.clip(np.round((i_arr + 1.0) * CONVERSION_SCALE), 0, 255).astype(
        DTYPE_OUTPUT
    )
    q_u8 = np.clip(np.round((q_arr + 1.0) * CONVERSION_SCALE), 0, 255).astype(
        DTYPE_OUTPUT
    )
    return i_u8, q_u8


def interleave_iq(
    i_u8: np.ndarray,
    q_u8: np.ndarray,
) -> np.ndarray:
    """Interleave I and Q uint8 arrays as IQIQIQ... sequence."""
    output = np.empty(2 * len(i_u8), dtype=DTYPE_OUTPUT)
    output[0::2] = i_u8
    output[1::2] = q_u8
    return output


def write_dat(interleaved: np.ndarray, output_path: str | Path) -> None:
    """Write interleaved uint8 IQ data as raw binary .dat file (no header)."""
    interleaved.tofile(str(output_path))


def convert_mat_to_dat(
    input_mat: str | Path,
    output_dat: str | Path,
    sample_rate: float | None = None,
) -> tuple[int, float | None]:
    """Convert a MATLAB .mat IQ recording to rtl_sdr-compatible .dat format.

    Returns (num_samples, sample_rate_or_None).
    Sample rate is informational only — cannot be embedded in .dat files.
    """
    i_arr, q_arr, auto_fs = read_mat_iq(input_mat)
    fs = sample_rate if sample_rate is not None else auto_fs
    i_u8, q_u8 = convert_to_uint8(i_arr, q_arr)
    interleaved = interleave_iq(i_u8, q_u8)
    write_dat(interleaved, output_dat)
    return len(i_arr), fs
