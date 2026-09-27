"""Move an existing booking to a different date/time (rooms, facilities) or a different slot (clinic)."""

import json
from datetime import datetime
from pathlib import Path

import availability
import bookings_log
import current_time

CLINIC_FILE = Path(__file__).resolve().parent.parent / "data" / "clinic_slots.json"


def _warn(clash: dict) -> dict:
    return {"success": False, "needs_confirmation": True,
            "message": f"Heads up: you have {clash['label']} ({clash['start']:%H:%M}-{clash['end']:%H:%M}) around then. Do you still want to move it there?"}


def change_booking(booking_id: str, date: str | None = None, time: str | None = None,
                   slot_id: str | None = None, force: bool = False) -> dict:
    b = bookings_log.get_booking(booking_id)
    if b is None:
        return {"success": False, "message": "Booking not found."}
    if b["kind"] == "bus":
        return {"success": False, "message": "Bus trips can't be changed here."}

    if b["kind"] == "clinic":
        slots = json.loads(CLINIC_FILE.read_text())
        new = next((s for s in slots if s["id"] == slot_id), None)
        if new is None or not new["available"]:
            return {"success": False, "message": "That appointment slot isn't available."}
        if datetime.strptime(f"{new['date']} {new['time']}", "%Y-%m-%d %H:%M") <= current_time.now():
            return {"success": False, "message": "That appointment time has already passed."}
        clash = availability.class_clash(new["date"], new["time"], 30)
        if clash and not force:
            return _warn(clash)
        for s in slots:
            if s["id"] == b.get("resource_id"):
                s["available"] = True
            if s["id"] == new["id"]:
                s["available"] = False
        CLINIC_FILE.write_text(json.dumps(slots, indent=2))
        bookings_log.update_booking(booking_id, resource_id=new["id"], date=new["date"], time=new["time"],
                                    title=f"{new['type']} with {new['doctor']}")
        return {"success": True, "message": f"Moved to {new['date']} at {new['time']}."}

    if not (date and time and b.get("resource_id")):
        return {"success": False, "message": "Pick a new date and time."}
    if not availability.slot_free(b["resource_id"], b["title"], date, time):
        return {"success": False, "message": f"{b['title']} is already taken at {time} on {date}."}
    clash = availability.class_clash(date, time)
    if clash and not force:
        return _warn(clash)
    bookings_log.update_booking(booking_id, date=date, time=time)
    return {"success": True, "message": f"Moved to {date} at {time}."}
