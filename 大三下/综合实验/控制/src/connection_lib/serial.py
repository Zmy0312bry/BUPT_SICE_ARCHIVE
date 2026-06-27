from serial import Serial


class SerialConnection:
    def __init__(self, port, baudrate=115200,auto_open=True):
        self.serial = Serial(port, baudrate, timeout=10, write_timeout=10)
        # if auto_open:
        #     self.open()

    def open(self):
        self.serial.open()

    def close(self):
        self.serial.close()

    def read(self, size=1):
        return self.serial.read(size)

    def write(self, data):
        return self.serial.write(data)
