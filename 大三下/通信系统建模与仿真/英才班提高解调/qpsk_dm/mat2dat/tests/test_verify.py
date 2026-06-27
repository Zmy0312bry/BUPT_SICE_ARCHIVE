"""Tests for mat2dat verify module: verify_dat and format_verify_result."""

import numpy as np
import pytest

from mat2dat.verify import MAX_IQ_IMBALANCE, format_verify_result, verify_dat


class TestVerifyDat:
    """Tests for verify_dat() — .dat file integrity and I/Q balance checks."""

    # ── helpers ──────────────────────────────────────────────────────────────

    @staticmethod
    def _write_dat(path, data: np.ndarray) -> str:
        """Write raw uint8 data to a .dat file and return its path as str."""
        data.tofile(str(path))
        return str(path)

    @staticmethod
    def _balanced_iq(n_samples: int = 100) -> np.ndarray:
        """Create interleaved IQIQIQ... with balanced I and Q (both ~128)."""
        rng = np.random.default_rng(42)
        i = rng.integers(100, 156, size=n_samples, dtype=np.uint8)
        q = rng.integers(100, 156, size=n_samples, dtype=np.uint8)
        interleaved = np.empty(2 * n_samples, dtype=np.uint8)
        interleaved[0::2] = i
        interleaved[1::2] = q
        return interleaved

    # ── happy path ───────────────────────────────────────────────────────────

    def test_valid_dat_all_checks_true(self, tmp_path):
        """Valid .dat file with balanced I/Q → all checks True."""
        path = tmp_path / "valid.dat"
        n_samples = 200
        data = self._balanced_iq(n_samples)
        self._write_dat(path, data)

        result = verify_dat(str(path))

        assert result["size_even"] is True
        assert result["value_range_ok"] is True
        assert result["iq_balance_ok"] is True
        assert result["num_samples"] == n_samples
        assert "error" not in result

    def test_value_range_ok_with_extremes(self, tmp_path):
        """Values exactly at 0 and 255 boundaries → value_range_ok=True."""
        path = tmp_path / "extremes.dat"
        data = np.array([0, 255, 0, 255, 128, 128], dtype=np.uint8)
        self._write_dat(path, data)

        result = verify_dat(str(path))

        assert result["value_range_ok"] is True
        assert result["size_even"] is True

    def test_num_samples_correct(self, tmp_path):
        """num_samples == half the file byte count."""
        path = tmp_path / "count.dat"
        n_samples = 73
        data = self._balanced_iq(n_samples)
        self._write_dat(path, data)

        result = verify_dat(str(path))

        assert result["num_samples"] == n_samples
        # file should be 2 * n_samples bytes
        assert path.stat().st_size == 2 * n_samples

    # ── size checks ──────────────────────────────────────────────────────────

    def test_odd_byte_count_size_even_false(self, tmp_path):
        """Odd number of bytes → size_even=False."""
        path = tmp_path / "odd.dat"
        # 3 bytes — odd, can't be valid IQIQ
        data = np.array([10, 20, 30], dtype=np.uint8)
        self._write_dat(path, data)

        result = verify_dat(str(path))

        assert result["size_even"] is False
        assert "error" not in result

    def test_empty_file_size_even_true(self, tmp_path):
        """Empty file (0 bytes, even) → size_even=True."""
        path = tmp_path / "empty.dat"
        data = np.array([], dtype=np.uint8)
        self._write_dat(path, data)

        result = verify_dat(str(path))

        assert result["size_even"] is True
        assert result["num_samples"] == 0

    # ── I/Q balance ──────────────────────────────────────────────────────────

    def test_imbalanced_iq_iq_balance_ok_false(self, tmp_path):
        """Artificially imbalanced I/Q (I=0, Q=255) → iq_balance_ok=False."""
        path = tmp_path / "imbalanced.dat"
        n_samples = 100
        i = np.zeros(n_samples, dtype=np.uint8)  # I_mean = 0
        q = np.full(n_samples, 255, dtype=np.uint8)  # Q_mean = 255
        interleaved = np.empty(2 * n_samples, dtype=np.uint8)
        interleaved[0::2] = i
        interleaved[1::2] = q
        self._write_dat(path, interleaved)

        result = verify_dat(str(path))

        assert result["iq_balance_ok"] is False
        assert result["i_mean"] == pytest.approx(0.0)
        assert result["q_mean"] == pytest.approx(255.0)
        # Diff should be >> MAX_IQ_IMBALANCE
        assert abs(result["i_mean"] - result["q_mean"]) > MAX_IQ_IMBALANCE

    def test_slightly_imbalanced_iq_still_ok(self, tmp_path):
        """I/Q means differ by less than threshold → iq_balance_ok=True."""
        path = tmp_path / "barely_balanced.dat"
        n_samples = 100
        # I_mean ~ 128, Q_mean ~ 128 + 5 (diff=5 < 10)
        i = np.full(n_samples, 128, dtype=np.uint8)
        q = np.full(n_samples, 133, dtype=np.uint8)
        interleaved = np.empty(2 * n_samples, dtype=np.uint8)
        interleaved[0::2] = i
        interleaved[1::2] = q
        self._write_dat(path, interleaved)

        result = verify_dat(str(path))

        assert result["iq_balance_ok"] is True
        assert abs(result["i_mean"] - result["q_mean"]) < MAX_IQ_IMBALANCE

    # ── error handling ───────────────────────────────────────────────────────

    def test_non_existent_file_returns_error(self):
        """Non-existent file → error key in result dict (no exception)."""
        result = verify_dat("/nonexistent/path/to/file.dat")

        assert "error" in result
        assert "File not found" in result["error"]

    def test_non_existent_file_no_crash(self):
        """verify_dat does not raise an exception for missing files."""
        # Should return a dict, not raise
        result = verify_dat("/tmp/_definitely_not_a_file_.dat")
        assert isinstance(result, dict)

    # ── type checks ──────────────────────────────────────────────────────────

    def test_result_has_expected_keys(self, tmp_path):
        """Result dict contains all expected keys on success."""
        path = tmp_path / "keys.dat"
        data = self._balanced_iq(50)
        self._write_dat(path, data)

        result = verify_dat(str(path))

        expected_keys = {
            "size_even",
            "value_range_ok",
            "iq_balance_ok",
            "num_samples",
            "i_mean",
            "q_mean",
        }
        assert expected_keys.issubset(result.keys())


class TestFormatVerifyResult:
    """Tests for format_verify_result() — human-readable output."""

    def test_error_result(self):
        """Result with error key → Verification Error message."""
        result = {"error": "File not found: /foo.dat"}
        output = format_verify_result(result)
        assert "Verification Error" in output
        assert "File not found" in output

    def test_all_checks_passed(self):
        """All checks True → 'ALL CHECKS PASSED'."""
        result = {
            "size_even": True,
            "value_range_ok": True,
            "iq_balance_ok": True,
            "num_samples": 100,
            "i_mean": 128.0,
            "q_mean": 128.0,
        }
        output = format_verify_result(result)
        assert "ALL CHECKS PASSED" in output
        assert "OK" in output

    def test_some_checks_failed(self):
        """Some checks False → 'SOME CHECKS FAILED'."""
        result = {
            "size_even": False,
            "value_range_ok": True,
            "iq_balance_ok": True,
            "num_samples": 50,
            "i_mean": 128.0,
            "q_mean": 200.0,
        }
        output = format_verify_result(result)
        assert "SOME CHECKS FAILED" in output
        assert "FAIL" in output

    def test_format_contains_iq_means(self):
        """Formatted output includes I_mean and Q_mean values."""
        result = {
            "size_even": True,
            "value_range_ok": True,
            "iq_balance_ok": True,
            "num_samples": 100,
            "i_mean": 127.5,
            "q_mean": 128.0,
        }
        output = format_verify_result(result)
        assert "I_mean=127.5" in output
        assert "Q_mean=128.0" in output

    def test_empty_result_handled(self):
        """Empty/partial result does not crash."""
        result = {}
        output = format_verify_result(result)
        # Should not raise; some checks will fail since defaults are falsy
        assert isinstance(output, str)
        assert "SOME CHECKS FAILED" in output or "Verification" in output
