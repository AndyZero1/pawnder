from typing import Dict
from fastapi import WebSocket

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        self.active_connections[user_id] = websocket

    def disconnect(self, user_id: str):
        self.active_connections.pop(user_id, None)

    def is_online(self, user_id: str) -> bool:
        return user_id in self.active_connections

    async def send_personal_message(self, message: dict, user_id: str) -> bool:
        if user_id in self.active_connections:
            await self.active_connections[user_id].send_json(message)
            return True
        return False

manager = ConnectionManager()