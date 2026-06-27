"""Frame constants: preamble, reference sequence, QPSK Gray mapping."""

import numpy as np

# 63-bit m-sequence used as BPSK preamble (1 -> 1+1j, -1 -> -1-1j)
PREAMBLE_BITS = np.array(
    [
        1,
        1,
        1,
        1,
        1,
        1,
        -1,
        -1,
        -1,
        -1,
        -1,
        1,
        -1,
        -1,
        -1,
        -1,
        1,
        1,
        -1,
        -1,
        -1,
        1,
        -1,
        1,
        -1,
        -1,
        1,
        1,
        1,
        1,
        -1,
        1,
        -1,
        -1,
        -1,
        1,
        1,
        1,
        -1,
        -1,
        1,
        -1,
        -1,
        1,
        -1,
        1,
        1,
        -1,
        1,
        1,
        1,
        -1,
        1,
        1,
        -1,
        -1,
        -1,
        1,
        1,
        -1,
        1,
        -1,
        1,
    ],
    dtype=float,
)

PREAMBLE_SYMBOLS = PREAMBLE_BITS + 1j * PREAMBLE_BITS

# Reference sequence indices: 0, 1, 3, 2, 1, 0, 2, 3, 3, 2, 0, 1, 2, 3, 1, 0
REFERENCE_INDICES = np.array(
    [0, 1, 3, 2, 1, 0, 2, 3, 3, 2, 0, 1, 2, 3, 1, 0],
    dtype=np.uint8,
)

# Gray mapping: 00->1+1j, 01->-1+1j, 10->1-1j, 11->-1-1j
QPSK_BY_INTEGER = np.array([1 + 1j, -1 + 1j, 1 - 1j, -1 - 1j])
REFERENCE_SYMBOLS = QPSK_BY_INTEGER[REFERENCE_INDICES]

# Frame format constants
DATA_SYMBOLS_PER_PILOT = 4
PILOT_SYMBOLS_PER_INSERTION = 1
