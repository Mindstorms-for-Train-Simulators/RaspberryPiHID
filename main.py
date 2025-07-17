import socket
import json
import time

PORT = 1337

def start_listener():
    print(f"Starting EV3 data listener on port {PORT}...")

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
                    msg_type = msg.get("type")

                    if msg_type == "CONFIG":
                        print(f"[CONFIG] {msg.get('config')}")
                    elif msg_type == "DATA":
                        print(f"[DATA] Levers: {msg.get('levers')}")
                        print(f"[DATA] Buttons: {msg.get('buttons')}")
                    elif msg_type == "END":
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
