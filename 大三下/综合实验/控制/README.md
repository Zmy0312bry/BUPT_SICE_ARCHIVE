```bash
bluetoothctl scan on
bluetoothctl devices | grep <name>
```
```text
Device 00:23:09:01:B0:2A <name>
```
```bash
bluetoothctl pair <MAC>
```
```bash
sudo rfcomm bind /dev/rfcomm0 00:23:09:01:B0:2A
```
