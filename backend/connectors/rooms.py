import json
from pathlib import Path

import bookings_log
import current_time

DATA_FILE = Path(__file__).resolve().parent.parent.parent / "data" / "rooms.json"

GET_ROOMS_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_study_rooms",
        "description": "List study rooms and whether each is currently available.",
        "parameters": {"type": "object", "properties": {}},
    },
}

BOOK_ROOM_SCHEMA = {
    "type": "function",
    "function": {
        "name": "book_study_room",
        "description": "Book a study room by its id. Fails if the room is not available.",
        "parameters": {
            "type": "object",
            "properties": {
                "room_id": {"type": "string", "description": "e.g. room-201"},
            },
            "required": ["room_id"],
        },
    },
}


def get_study_rooms() -> list[dict]:
    return json.loads(DATA_FILE.read_text())


def book_study_room(room_id: str) -> dict:
    rooms = json.loads(DATA_FILE.read_text())
    room = next((r for r in rooms if r["id"] == room_id), None)

    if room is None:
        return {"success": False, "message": f"No room found with id {room_id}."}
    if not room["available"]:
        return {"success": False, "message": f"{room['name']} is not available."}

    room["available"] = False
    DATA_FILE.write_text(json.dumps(rooms, indent=2))

    now = current_time.now()
    bookings_log.record_booking(
        kind="room",
        title=room["name"],
        subtitle=f"{room['building']}, Floor {room['floor']}",
        date=now.strftime("%Y-%m-%d"),
        time=now.strftime("%H:%M"),
    )
    return {"success": True, "message": f"{room['name']} booked."}
