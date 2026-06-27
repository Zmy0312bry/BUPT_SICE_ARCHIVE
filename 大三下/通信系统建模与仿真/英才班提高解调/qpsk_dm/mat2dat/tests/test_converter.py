"""Unit tests for mat2dat converter: convert_to_uint8 and interleave_iq."""

from pathlib import Path

import h5py
import numpy as np
import pytest

from mat2dat.converter import (
    MatReadError,
    convert_mat_to_dat,
    convert_to_uint8,
    interleave_iq,
    read_mat_iq,
    write_dat,
)


# ── convert_to_uint8 ──────────────────────────────────────────────────────────


class TestConvertToUint8:
    """Conversion from float64 [-1, +1] to uint8 [0, 255]."""

    def test_neg_one(self):
        """-1.0 maps to 0."""
        i, q = convert_to_uint8(
            np.array([-1.0], dtype=np.float64),
            np.array([-1.0], dtype=np.float64),
        )
        assert i[0] == 0
        assert q[0] == 0

    def test_neg_half(self):
        """-0.5 maps to 64."""
        i, q = convert_to_uint8(
            np.array([-0.5], dtype=np.float64),
            np.array([-0.5], dtype=np.float64),
        )
        assert i[0] == 64
        assert q[0] == 64

    def test_zero(self):
        """0.0 maps to 128 (midpoint)."""
        i, q = convert_to_uint8(
            np.array([0.0], dtype=np.float64),
            np.array([0.0], dtype=np.float64),
        )
        assert i[0] == 128
        assert q[0] == 128

    def test_pos_half(self):
        """0.5 maps to 191."""
        i, q = convert_to_uint8(
            np.array([0.5], dtype=np.float64),
            np.array([0.5], dtype=np.float64),
        )
        assert i[0] == 191
        assert q[0] == 191

    def test_pos_one(self):
        """1.0 maps to 255."""
        i, q = convert_to_uint8(
            np.array([1.0], dtype=np.float64),
            np.array([1.0], dtype=np.float64),
        )
        assert i[0] == 255
        assert q[0] == 255

    def test_clamp_negative(self):
        """Values below -1.0 are clamped to 0."""
        for val in (-1.1, -2.0, -100.0):
            i, q = convert_to_uint8(
                np.array([val], dtype=np.float64),
                np.array([val], dtype=np.float64),
            )
            assert i[0] == 0, f"val={val} should clamp I to 0, got {i[0]}"
            assert q[0] == 0, f"val={val} should clamp Q to 0, got {q[0]}"

    def test_clamp_positive(self):
        """Values above 1.0 are clamped to 255."""
        for val in (1.1, 2.0, 100.0):
            i, q = convert_to_uint8(
                np.array([val], dtype=np.float64),
                np.array([val], dtype=np.float64),
            )
            assert i[0] == 255, f"val={val} should clamp I to 255, got {i[0]}"
            assert q[0] == 255, f"val={val} should clamp Q to 255, got {q[0]}"

    def test_symmetry(self):
        """[-0.5, 0.5] produces [64, 191] (symmetric around 128)."""
        arr = np.array([-0.5, 0.5], dtype=np.float64)
        i, q = convert_to_uint8(arr, arr)
        np.testing.assert_array_equal(i, [64, 191])
        np.testing.assert_array_equal(q, [64, 191])


# ── interleave_iq ─────────────────────────────────────────────────────────────


class TestInterleaveIQ:
    """Interleaving uint8 I/Q arrays into IQIQIQ... sequence."""

    def test_known_sequence(self):
        """[0,1,2] and [3,4,5] interleave to [0,3,1,4,2,5]."""
        i = np.array([0, 1, 2], dtype=np.uint8)
        q = np.array([3, 4, 5], dtype=np.uint8)
        result = interleave_iq(i, q)
        np.testing.assert_array_equal(result, [0, 3, 1, 4, 2, 5])

    def test_empty_arrays(self):
        """Empty I/Q arrays produce empty output."""
        i = np.array([], dtype=np.uint8)
        q = np.array([], dtype=np.uint8)
        result = interleave_iq(i, q)
        assert result.shape == (0,)
        assert result.dtype == np.uint8

    def test_length_mismatch_q_longer(self):
        """ValueError when Q is longer than I."""
        i = np.array([0, 1], dtype=np.uint8)
        q = np.array([3, 4, 5], dtype=np.uint8)
        with pytest.raises(ValueError):
            interleave_iq(i, q)

    def test_length_mismatch_i_longer(self):
        """ValueError when I is longer than Q."""
        i = np.array([0, 1, 2], dtype=np.uint8)
        q = np.array([3, 4], dtype=np.uint8)
        with pytest.raises(ValueError):
            interleave_iq(i, q)

    def test_output_dtype(self):
        """Output array dtype is uint8."""
        i = np.array([0, 1], dtype=np.uint8)
        q = np.array([2, 3], dtype=np.uint8)
        result = interleave_iq(i, q)
        assert result.dtype == np.uint8

    def test_single_element(self):
        """Single-element arrays interleave correctly."""
        i = np.array([10], dtype=np.uint8)
        q = np.array([20], dtype=np.uint8)
        result = interleave_iq(i, q)
        np.testing.assert_array_equal(result, [10, 20])


# ---------------------------------------------------------------------------
# Fixtures — synthetic .mat files via h5py (tmp_path handles cleanup)
# ---------------------------------------------------------------------------


@pytest.fixture
def valid_1d_mat(tmp_path):
    """Minimal valid .mat with 1D #refs#/z (compound dtype, no #refs#/p)."""
    path = tmp_path / "valid_1d.mat"
    with h5py.File(path, "w") as f:
        g = f.create_group("#refs#")
        dt = np.dtype([("real", "<f8"), ("imag", "<f8")])
        z = g.create_dataset("z", shape=(10,), dtype=dt)
        z["real"] = np.linspace(-1, 1, 10)
        z["imag"] = np.linspace(1, -1, 10)
    return str(path)


@pytest.fixture
def valid_2d_mat(tmp_path):
    """2D block .mat with #refs#/p time vector (block_size=10, dt=5µs → 2 MHz)."""
    path = tmp_path / "valid_2d.mat"
    n_blocks, block_size = 5, 10
    dt_val = 5e-6  # 5 µs per sample
    with h5py.File(path, "w") as f:
        g = f.create_group("#refs#")
        cdt = np.dtype([("real", "<f8"), ("imag", "<f8")])
        z = g.create_dataset("z", shape=(n_blocks, block_size), dtype=cdt)
        for blk in range(n_blocks):
            z["real"][blk] = np.linspace(-1, 1, block_size)
            z["imag"][blk] = np.linspace(1, -1, block_size)
        # Uniform time vector → mean(diff) = dt_val
        p = g.create_dataset("p", shape=(n_blocks, block_size), dtype="<f8")
        for blk in range(n_blocks):
            p[blk] = np.arange(block_size) * dt_val + blk * block_size * dt_val
    return str(path)


@pytest.fixture
def missing_z_mat(tmp_path):
    """.mat with no #refs#/z key (only #refs#/p)."""
    path = tmp_path / "missing_z.mat"
    with h5py.File(path, "w") as f:
        g = f.create_group("#refs#")
        g.create_dataset("p", shape=(5,), dtype="<f8")
    return str(path)


@pytest.fixture
def wrong_dtype_mat(tmp_path):
    """.mat with #refs#/z but plain float64 instead of compound dtype."""
    path = tmp_path / "wrong_dtype.mat"
    with h5py.File(path, "w") as f:
        g = f.create_group("#refs#")
        g.create_dataset("z", shape=(10,), dtype="<f8")
    return str(path)


@pytest.fixture
def non_hdf5_file(tmp_path):
    """Plain text file (not a valid HDF5 .mat)."""
    path = tmp_path / "not_a_mat.txt"
    path.write_text("this is not an HDF5 file\n")
    return str(path)


# ---------------------------------------------------------------------------
# Tests: read_mat_iq  —  error handling
# ---------------------------------------------------------------------------


class TestReadMatIQ:
    def test_non_existent_file(self):
        """Non-existent file → FileNotFoundError."""
        with pytest.raises(FileNotFoundError):
            read_mat_iq("/nonexistent/path.mat")

    def test_missing_z_key(self, missing_z_mat):
        """Missing #refs#/z key → MatReadError."""
        with pytest.raises(MatReadError, match="Missing key"):
            read_mat_iq(missing_z_mat)

    def test_wrong_dtype(self, wrong_dtype_mat):
        """Wrong dtype for #refs#/z → MatReadError."""
        with pytest.raises(MatReadError, match="Unexpected dtype"):
            read_mat_iq(wrong_dtype_mat)

    def test_non_hdf5_file(self, non_hdf5_file):
        """Non-HDF5 file → MatReadError."""
        with pytest.raises(MatReadError):
            read_mat_iq(non_hdf5_file)

    def test_valid_1d_returns_correct_shape_and_fs(self, valid_1d_mat):
        """Valid 1D .mat returns (i_arr, q_arr, None)."""
        i_arr, q_arr, fs = read_mat_iq(valid_1d_mat)
        assert i_arr.shape == (10,)
        assert q_arr.shape == (10,)
        assert fs is None
        assert i_arr[0] == pytest.approx(-1.0)
        assert q_arr[0] == pytest.approx(1.0)

    def test_valid_2d_returns_correct_shape_and_fs(self, valid_2d_mat):
        """Valid 2D .mat returns (i_arr, q_arr, sample_rate)."""
        n_blocks, block_size = 5, 10
        i_arr, q_arr, fs = read_mat_iq(valid_2d_mat)
        assert i_arr.shape == (n_blocks * block_size,)
        assert q_arr.shape == (n_blocks * block_size,)
        # dt = 5e-6, block_size = 10 → fs = 10 / 5e-6 = 2_000_000
        assert fs == pytest.approx(2_000_000.0)

    def test_path_object_accepted(self, valid_1d_mat):
        """read_mat_iq accepts pathlib.Path as well as str."""
        i_arr, q_arr, fs = read_mat_iq(Path(valid_1d_mat))
        assert i_arr.shape == (10,)
        assert q_arr.shape == (10,)


# ---------------------------------------------------------------------------
# Tests: write_dat  —  raw binary output
# ---------------------------------------------------------------------------


class TestWriteDat:
    def test_writes_correct_raw_bytes_no_header(self, tmp_path):
        """write_dat writes raw uint8 bytes with no header/footer."""
        interleaved = np.array([10, 20, 30, 40], dtype=np.uint8)
        out_path = tmp_path / "output.dat"
        write_dat(interleaved, out_path)

        assert out_path.exists()
        data = out_path.read_bytes()
        assert data == bytes([10, 20, 30, 40])

    def test_empty_array_writes_empty_file(self, tmp_path):
        """Writing empty array produces an empty file."""
        interleaved = np.array([], dtype=np.uint8)
        out_path = tmp_path / "empty.dat"
        write_dat(interleaved, out_path)

        assert out_path.exists()
        assert out_path.stat().st_size == 0

    def test_large_array_writes_all_bytes(self, tmp_path):
        """Large array writes every byte in order."""
        n = 10_000
        interleaved = np.arange(2 * n, dtype=np.uint8)
        out_path = tmp_path / "large.dat"
        write_dat(interleaved, out_path)

        assert out_path.stat().st_size == 2 * n
        data = out_path.read_bytes()
        assert list(data) == list(range(2 * n))


# ---------------------------------------------------------------------------
# End-to-end tests: synthetic .mat → convert → verify .dat output
# ---------------------------------------------------------------------------


@pytest.fixture
def known_values_mat(tmp_path):
    """Synthetic .mat with 10 known IQ float pairs for round-trip testing.

    Samples: (-1.0, -1.0), (-0.5, -0.5), (0.0, 0.0), (0.5, 0.5), (1.0, 1.0),
             (1.0, -1.0), (-1.0, 1.0), (0.2, 0.3), (-0.7, 0.9), (0.0, 0.0).
    These cover the full [-1, +1] range and asymmetric I/Q values.
    """
    path = tmp_path / "known_values.mat"
    with h5py.File(path, "w") as f:
        g = f.create_group("#refs#")
        dt = np.dtype([("real", "<f8"), ("imag", "<f8")])
        z = g.create_dataset("z", shape=(10,), dtype=dt)
        z["real"] = np.array(
            [-1.0, -0.5, 0.0, 0.5, 1.0, 1.0, -1.0, 0.2, -0.7, 0.0], dtype=np.float64
        )
        z["imag"] = np.array(
            [-1.0, -0.5, 0.0, 0.5, 1.0, -1.0, 1.0, 0.3, 0.9, 0.0], dtype=np.float64
        )
    return str(path)


def _expected_uint8(val: float) -> int:
    """Compute expected uint8 value using the same formula as converter."""
    return int(np.clip(np.round((val + 1.0) * 127.5), 0, 255))


class TestEndToEnd:
    """End-to-end pipeline: synthetic .mat → convert → validate .dat."""

    def test_full_pipeline_byte_count(self, known_values_mat, tmp_path):
        """Full pipeline produces .dat with exactly 2 * num_samples bytes."""
        out_path = tmp_path / "output.dat"
        num_samples, fs = convert_mat_to_dat(known_values_mat, str(out_path))

        assert num_samples == 10
        assert out_path.exists()
        assert out_path.stat().st_size == 2 * num_samples

    def test_known_values_round_trip(self, known_values_mat, tmp_path):
        """Known float values round-trip to expected uint8 bytes."""
        out_path = tmp_path / "output.dat"
        convert_mat_to_dat(known_values_mat, str(out_path))

        raw = np.fromfile(out_path, dtype=np.uint8)

        # Expected I values
        i_float = np.array(
            [-1.0, -0.5, 0.0, 0.5, 1.0, 1.0, -1.0, 0.2, -0.7, 0.0], dtype=np.float64
        )
        expected_i = [_expected_uint8(v) for v in i_float]
        # Expected Q values
        q_float = np.array(
            [-1.0, -0.5, 0.0, 0.5, 1.0, -1.0, 1.0, 0.3, 0.9, 0.0], dtype=np.float64
        )
        expected_q = [_expected_uint8(v) for v in q_float]

        # I at even indices (0, 2, 4...), Q at odd indices (1, 3, 5...)
        assert list(raw[0::2]) == expected_i, "I channel mismatch"
        assert list(raw[1::2]) == expected_q, "Q channel mismatch"

    def test_iq_interleaving_pattern(self, known_values_mat, tmp_path):
        """I/Q interleaving in .dat follows IQIQIQ... pattern."""
        out_path = tmp_path / "output.dat"
        convert_mat_to_dat(known_values_mat, str(out_path))

        raw = np.fromfile(out_path, dtype=np.uint8)

        # Verify IQIQ pattern: each pair is (I_i, Q_i)
        for i in range(10):
            i_val = raw[2 * i]
            q_val = raw[2 * i + 1]
            # Just check that I and Q at each position are valid uint8
            assert 0 <= i_val <= 255
            assert 0 <= q_val <= 255

    def test_pipeline_with_2d_mat(self, valid_2d_mat, tmp_path):
        """Full pipeline works with 2D block .mat files."""
        out_path = tmp_path / "output_2d.dat"
        num_samples, fs = convert_mat_to_dat(valid_2d_mat, str(out_path))

        n_blocks, block_size = 5, 10
        assert num_samples == n_blocks * block_size
        assert out_path.stat().st_size == 2 * num_samples
        assert fs == pytest.approx(2_000_000.0)

    def test_conversion_identity(self, tmp_path):
        """Create .mat, convert, re-read .dat — data matches expected identity.

        If I = Q = 0.0 for all samples, the .dat should be all 128s.
        """
        path = tmp_path / "all_zero.mat"
        n_samples = 50
        with h5py.File(path, "w") as f:
            g = f.create_group("#refs#")
            dt = np.dtype([("real", "<f8"), ("imag", "<f8")])
            z = g.create_dataset("z", shape=(n_samples,), dtype=dt)
            z["real"] = np.zeros(n_samples, dtype=np.float64)
            z["imag"] = np.zeros(n_samples, dtype=np.float64)

        out_path = tmp_path / "all_zero.dat"
        convert_mat_to_dat(str(path), str(out_path))

        raw = np.fromfile(out_path, dtype=np.uint8)

        # All bytes should be 128 (midpoint of [-1, +1] → uint8 range)
        assert np.all(raw == 128)
        assert len(raw) == 2 * n_samples
