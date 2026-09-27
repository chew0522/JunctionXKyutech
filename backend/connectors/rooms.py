import json
from pathlib import Path

import availability
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
    """'available' means free at this moment; every room can still be booked for a later slot."""
    rooms = json.loads(DATA_FILE.read_text())
    for r in rooms:
        r["available"] = availability.free_now(r["id"], r["name"])
    return rooms


def book_study_room(room_id: str, date: str | None = None, time: str | None = None, force: bool = False) -> dict:
    room = next((r for r in json.loads(DATA_FILE.read_text()) if r["id"] == room_id), None)

    if room is None:
        return {"success": False, "message": f"No room found with id {room_id}."}
    if date and time and not force and (clash := availability.class_clash(date, time)):
        return {"success": False, "needs_confirmation": True,
                "message": (f"Heads up: you have {clash['label']} ({clash['start']:%H:%M}-{clash['end']:%H:%M}) "
                            f"around then. Do you still want to book it?")}
    if date and time and not availability.slot_free(room_id, room["name"], date, time):
        return {"success": False, "message": f"{room['name']} is already taken at {time} on {date}."}

    now = current_time.now()
    bookings_log.record_booking(
        kind="room",
        title=room["name"],
        subtitle=f"{room['building']}, Floor {room['floor']}",
        date=date or now.strftime("%Y-%m-%d"),
        time=time or now.strftime("%H:%M"),
        resource_id=room_id,
    )
    return {"success": True, "message": f"{room['name']} booked."}
