import qoi
import numpy as np


def encode(image: np.ndarray) -> bytes:
    """
    Encode a numpy array image using the QOI format.

    Args:
        image (numpy.ndarray): The image to encode, expected to be an array of
            shape (height, width, 3) with dtype np.uint8.

    Returns:
        bytes: The encoded QOI image data.
    """
    if image is None:
        raise ValueError("image must not be None")
    if image.dtype != np.uint8:
        raise ValueError("image must have dtype np.uint8")
    if image.ndim != 3 or image.shape[2] != 3:
        raise ValueError("image must have shape (height, width, 3)")

    return qoi.encode(image)
