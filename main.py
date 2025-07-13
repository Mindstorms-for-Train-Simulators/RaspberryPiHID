import socket
import json

print(f"Starting EV3 listener on port {PORT}...")

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind(('0.0.0.0', 1337))  # Accepts connections from any IP
    s.listen()
    conn, addr = s.accept()
    print(f"Connected by {addr}")

    with conn:
        while True:
            try:
                data = conn.recv(4096)
                if not data:
                    print("EV3 disconnected.")
                    break

                # Decode and parse JSON
                msg = json.loads(data.decode())

                # Handle message types
                if msg.get("type") == "CONFIG":
                    print(f"[CONFIG] Mode: {msg.get('config')}")
                elif msg.get("type") == "DATA":
                    levers = msg.get("levers", [])
                    buttons = msg.get("buttons", [])
                    print(f"[DATA] Levers: {levers} | Buttons: {buttons}")
                elif msg.get("type") == "END":
                    print("[END] EV3 shut down program.")
                    break
                else:
                    print(f"[UNKNOWN] {msg}")

            except json.JSONDecodeError:
                print("Received malformed JSON.")
            except Exception as e:
                print(f"Error: {e}")
                break
