from PIL import Image
import numpy as np


class Pixelated:
    def __init__(self, height=32, max_width=120):
        self.height = int(height)
        self.max_width = int(max_width)

    def process(self, image: Image.Image) -> np.ndarray:
        """
        Convert the input image to RGB, scale it proportionally so that the height
        becomes `self.height`, and then set the resulting width to
        min(scaled_width, self.max_width). If the scaled width exceeds max_width,
        center-crop horizontally to `self.max_width`.

        Returns:
            numpy.ndarray: the processed image as an array with dtype np.uint8 and
            shape (height, width, 3).
        """
        if image is None:
            raise ValueError("image must not be None")

        # Ensure RGB mode
        img = image.convert("RGB")

        orig_w, orig_h = img.size

        # compute new size keeping aspect ratio with target height
        scale = self.height / float(orig_h)
        scaled_w = max(1, int(round(orig_w * scale)))
        scaled_h = self.height

        # resize using a high-quality filter
        resized = img.resize((scaled_w, scaled_h), resample=Image.LANCZOS)

        # if width exceeds max_width, center-crop horizontally
        if scaled_w > self.max_width:
            left = (scaled_w - self.max_width) // 2
            right = left + self.max_width
            resized = resized.crop((left, 0, right, scaled_h))

        # Convert to numpy array with dtype int8
        arr = np.asarray(resized, dtype=np.uint8)

        return arr
