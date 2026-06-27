"""Integration tests for mat2dat CLI via subprocess."""

import subprocess
from pathlib import Path

import h5py
import numpy as np
import pytest

PROJECT_ROOT = Path(__file__).resolve().parent.parent
MAIN_PY = PROJECT_ROOT / "main.py"


def run_cli(*args: str, timeout: int = 30) -> subprocess.CompletedProcess:
    """Run ``uv run main.py <args>`` from the project root."""
    cmd = ["uv", "run", str(MAIN_PY), *args]
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=PROJECT_ROOT,
        timeout=timeout,
    )


# ── Fixtures ──────────────────────────────────────────────────────────────


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
def missing_z_mat(tmp_path):
    """.mat with no #refs#/z key."""
    path = tmp_path / "missing_z.mat"
    with h5py.File(path, "w") as f:
        g = f.create_group("#refs#")
        g.create_dataset("p", shape=(5,), dtype="<f8")
    return str(path)


# ── Tests: --help ────────────────────────────────────────────────────────


def test_help_exit_zero():
    """--help prints usage and exits 0."""
    result = run_cli("--help")
    assert result.returncode == 0
    assert "usage" in result.stdout.lower()


# ── Tests: error paths ───────────────────────────────────────────────────


def test_no_args_nonzero_exit():
    """No args -> non-zero exit and stderr."""
    result = run_cli()
    assert result.returncode != 0
    assert result.stderr


def test_nonexistent_input(tmp_path):
    """Nonexistent input file -> non-zero exit, stderr mentions 'file'."""
    out = tmp_path / "out.dat"
    result = run_cli(str(tmp_path / "nonexistent.mat"), str(out))
    assert result.returncode != 0
    assert "file" in result.stderr.lower()


def test_missing_z_key(tmp_path, missing_z_mat):
    """.mat without #refs#/z key -> non-zero exit, stderr mentions error."""
    out = tmp_path / "out.dat"
    result = run_cli(missing_z_mat, str(out))
    assert result.returncode != 0
    assert result.stderr


# ── Tests: successful conversion ─────────────────────────────────────────


def test_valid_conversion(valid_1d_mat, tmp_path):
    """Valid .mat -> exit 0, .dat file created with content."""
    out = tmp_path / "output.dat"
    result = run_cli(valid_1d_mat, str(out))
    assert result.returncode == 0
    assert out.exists()
    assert out.stat().st_size > 0
    assert "samples" in result.stdout.lower()


def test_valid_with_verify(valid_1d_mat, tmp_path):
    """Valid .mat + --verify -> exit 0, verification output in stdout."""
    out = tmp_path / "output.dat"
    result = run_cli(valid_1d_mat, str(out), "--verify")
    assert result.returncode == 0
    assert out.exists()
    assert "samples" in result.stdout.lower()


def test_without_sample_rate(valid_1d_mat, tmp_path):
    """1D .mat without --sample-rate -> exit 0 (succeeds anyway)."""
    out = tmp_path / "output.dat"
    result = run_cli(valid_1d_mat, str(out))
    assert result.returncode == 0
    assert out.exists()
