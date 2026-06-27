from connection_lib.pixelated import Pixelated
from connection_lib.encode import encode
from connection_lib.serial import SerialConnection

from PIL import Image
import qoi

IMAGE_PATH = "/home/april/Pictures/icon.jpeg"
SERIAL_PORT = "/dev/ttyUSB0"

factory = Pixelated()

image = Image.open(IMAGE_PATH)

np_array = factory.process(image)

bytes = encode(np_array)

serial = SerialConnection(SERIAL_PORT)
serial.write(bytes)
