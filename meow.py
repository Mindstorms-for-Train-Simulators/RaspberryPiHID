with open("/dev/hidg0", "wb") as hid:
    hid.write(b'\x00\x00\x04\x00\x00\x00\x00\x00')  # Press 'A'
    hid.write(b'\x00' * 8)                          # Release
