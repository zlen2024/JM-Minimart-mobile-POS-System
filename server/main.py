import json
import sqlite3
from typing import Dict
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from datetime import datetime

app = FastAPI(title="IoT System Server")

# Initialize database
def init_db():
    conn = sqlite3.connect("heartbeats.db")
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS heartbeats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT NOT NULL,
            uptime_ms INTEGER,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

init_db()

# Connection manager for WebSockets
class ConnectionManager:
    def __init__(self):
        # Maps device_id to its WebSocket connection
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, device_id: str):
        await websocket.accept()
        self.active_connections[device_id] = websocket
        print(f"Device connected: {device_id}")

    def disconnect(self, device_id: str):
        if device_id in self.active_connections:
            del self.active_connections[device_id]
            print(f"Device disconnected: {device_id}")

    async def send_personal_message(self, message: str, device_id: str):
        if device_id in self.active_connections:
            await self.active_connections[device_id].send_text(message)

manager = ConnectionManager()

@app.websocket("/ws/{device_id}")
async def websocket_endpoint(websocket: WebSocket, device_id: str):
    await manager.connect(websocket, device_id)
    try:
        while True:
            data = await websocket.receive_text()
            print(f"Received from {device_id}: {data}")

            try:
                msg = json.loads(data)

                # Check for heartbeat
                if msg.get("type") == "heartbeat":
                    uptime = msg.get("uptime_ms")
                    conn = sqlite3.connect("heartbeats.db")
                    cursor = conn.cursor()
                    cursor.execute(
                        "INSERT INTO heartbeats (device_id, uptime_ms) VALUES (?, ?)",
                        (msg.get("id", device_id), uptime)
                    )
                    conn.commit()
                    conn.close()
                    print(f"Logged heartbeat for {device_id}")

                # Check if it's a command meant for a specific device
                elif "cmd" in msg and "id" in msg:
                    target_id = msg["id"]
                    if target_id in manager.active_connections:
                         await manager.send_personal_message(data, target_id)
                         print(f"Routed command to {target_id}: {msg['cmd']}")
                    else:
                         print(f"Target device {target_id} not connected")

            except json.JSONDecodeError:
                print(f"Invalid JSON received: {data}")

    except WebSocketDisconnect:
        manager.disconnect(device_id)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
