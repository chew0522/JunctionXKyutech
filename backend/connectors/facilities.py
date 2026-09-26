import json
from pathlib import Path

import bookings_log
import current_time

DATA_FILE = Path(__file__).resolve().parent.parent.parent / "data" / "facilities.json"


GET_FACILITIES_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_facilities",
        "description": "List bookable school facilities: category 'event' (halls, auditorium) or 'sports' (courts, gym).",
        "parameters": {
            "type": "object",
            "properties": {"category": {"type": "string", "enum": ["event", "sports"]}},
        },
    },
}


def get_facilities(category: str | None = None) -> list[dict]:
    facilities = json.loads(DATA_FILE.read_text())
    if category:
        facilities = [f for f in facilities if f["category"] == category]
    return facilities


def book_facility(facility_id: str, date: str | None = None, time: str | None = None) -> dict:
    facilities = json.loads(DATA_FILE.read_text())
    facility = next((f for f in facilities if f["id"] == facility_id), None)

    if facility is None:
        return {"success": False, "message": f"No facility found with id {facility_id}."}
    if not facility["available"]:
        return {"success": False, "message": f"{facility['name']} is not available."}

    facility["available"] = False
    DATA_FILE.write_text(json.dumps(facilities, indent=2))

    now = current_time.now()
    bookings_log.record_booking(
        kind="facility",
        title=facility["name"],
        subtitle=facility["location"],
        date=date or now.strftime("%Y-%m-%d"),
        time=time or now.strftime("%H:%M"),
    )
    return {"success": True, "message": f"{facility['name']} booked."}
