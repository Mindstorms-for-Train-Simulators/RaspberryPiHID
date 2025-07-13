import socket
import json
import time

PORT = 1337

def start_listener():
    print(f"Starting EV3 listener on port {PORT}...")

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('0.0.0.0', PORT))
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

                    msg = json.loads(data.decode())

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

# Main loop to restart listener when EV3 comes back
while True:
    try:
        start_listener()
    except Exception as e:
        print(f"Listener crashed: {e}")
    
    print("Waiting for EV3 to reconnect...")
    time.sleep(5)  # Wait before retrying
