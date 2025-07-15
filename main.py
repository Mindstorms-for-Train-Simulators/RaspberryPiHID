import socket
import json
import time

PORT = 1337

# HID keycodes
hid_codes = {
    # Letters
    "A": 0x04, "B": 0x05, "C": 0x06, "D": 0x07, "E": 0x08, "F": 0x09,
    "G": 0x0A, "H": 0x0B, "I": 0x0C, "J": 0x0D, "K": 0x0E, "L": 0x0F,
    "M": 0x10, "N": 0x11, "O": 0x12, "P": 0x13, "Q": 0x14, "R": 0x15,
    "S": 0x16, "T": 0x17, "U": 0x18, "V": 0x19, "W": 0x1A, "X": 0x1B,
    "Y": 0x1C, "Z": 0x1D,

    # Misc
    "Enter": 0x28, "Space": 0x2C,
    "Left": 0x50, "Right": 0x4F, "Up": 0x52, "Down": 0x51,
}

# Modifier bits
mod_bit = {
    "Ctrl": 0x01, "Shift": 0x02, "Alt": 0x04, "Meta": 0x08  # Meta = Windows / Command
}

def parse_combo(combo):
    """Parse a combo like Shift+Ctrl+O or T+U into modifier byte + list of keycodes"""
    modifiers = 0
    keys = []

    for part in combo.split("+"):
        part = part.strip()
        if part in mod_bit:
            modifiers |= mod_bit[part]
        elif part.upper() in hid_codes:
            keys.append(hid_codes[part.upper()])
        elif part.capitalize() in hid_codes:
            keys.append(hid_codes[part.capitalize()])
    return modifiers, keys

def send_report(hid, modifiers, keys):
    # HID report structure: [modifiers, reserved, key1, key2, key3, key4, key5, key6]
    report = bytearray(8)
    report[0] = modifiers
    for i in range(min(6, len(keys))):
        report[2 + i] = keys[i]
    hid.write(report)
    hid.flush()
    # Send key-up
    hid.write(b'\x00' * 8)
    hid.flush()

def start_listener():
    print(f"Starting EV3 HID listener on port {PORT}...")

    try:
        hid = open("/dev/hidg0", "wb")
        print("HID device opened.")
    except Exception as e:
        print(f"Failed to open /dev/hidg0: {e}")
        hid = None

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('0.0.0.0', PORT))
        s.listen()
        conn, addr = s.accept()
        print(f"🔌 Connected by {addr}")

        with conn:
            while True:
                try:
                    data = conn.recv(4096)
                    if not data:
                        print("EV3 disconnected.")
                        break

                    msg = json.loads(data.decode())

                    if msg.get("type") == "CONFIG":
                        print(f"[CONFIG] Mode: {msg.get('config')}")
                    elif msg.get("type") == "DATA":
                        buttons = msg.get("buttons", [])
                        print(f"[DATA] Buttons: {buttons}")

                        if hid:
                            # Support nested button lists or flat list
                            combos = []
                            for item in buttons:
                                combos.extend(item if isinstance(item, list) else [item])
                            for combo in combos:
                                modifiers, keys = parse_combo(combo)
                                if keys:
                                    send_report(hid, modifiers, keys)
                                else:
                                    print(f"⚠Unknown key combo: {combo}")

                    elif msg.get("type") == "END":
                        print("[END] EV3 shut down program.")
                        break
                    else:
                        print(f"[UNKNOWN] {msg}")

                except Exception as e:
                    print(f"Runtime error: {e}")
                    break

while True:
    try:
        start_listener()
    except Exception as e:
        print(f"Listener crashed: {e}")
    print("Waiting for EV3 to reconnect...")
    time.sleep(5)
