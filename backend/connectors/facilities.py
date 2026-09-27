import json
from pathlib import Path

import availability
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
    for f in facilities:
        f["available"] = availability.free_now(f["id"], f["name"])
    if category:
        facilities = [f for f in facilities if f["category"] == category]
    return facilities


def book_facility(facility_id: str, date: str | None = None, time: str | None = None, force: bool = False) -> dict:
    facility = next((f for f in json.loads(DATA_FILE.read_text()) if f["id"] == facility_id), None)

    if facility is None:
        return {"success": False, "message": f"No facility found with id {facility_id}."}
    if date and time and not force and (clash := availability.class_clash(date, time)):
        return {"success": False, "needs_confirmation": True,
                "message": (f"Heads up: you have {clash['label']} ({clash['start']:%H:%M}-{clash['end']:%H:%M}) "
                            f"around then. Do you still want to book it?")}
    if date and time and not availability.slot_free(facility_id, facility["name"], date, time):
        return {"success": False, "message": f"{facility['name']} is already taken at {time} on {date}."}

    now = current_time.now()
    bookings_log.record_booking(
        kind="facility",
        title=facility["name"],
        subtitle=facility["location"],
        date=date or now.strftime("%Y-%m-%d"),
        time=time or now.strftime("%H:%M"),
        resource_id=facility_id,
    )
    return {"success": True, "message": f"{facility['name']} booked."}
