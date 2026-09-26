import json
from pathlib import Path

import bookings_log

DATA_FILE = Path(__file__).resolve().parent.parent.parent / "data" / "clinic_slots.json"

GET_SLOTS_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_clinic_slots",
        "description": "List school clinic appointment slots, optionally filtered by date (YYYY-MM-DD).",
        "parameters": {
            "type": "object",
            "properties": {
                "date": {"type": "string", "description": "Filter to this date, e.g. 2026-09-26"}
            },
        },
    },
}

BOOK_APPOINTMENT_SCHEMA = {
    "type": "function",
    "function": {
        "name": "book_clinic_appointment",
        "description": "Book a school clinic appointment slot by its id. Fails if the slot is not available.",
        "parameters": {
            "type": "object",
            "properties": {
                "slot_id": {"type": "string", "description": "e.g. slot-1"},
            },
            "required": ["slot_id"],
        },
    },
}


def get_clinic_slots(date: str | None = None) -> list[dict]:
    slots = json.loads(DATA_FILE.read_text())
    if date:
        slots = [s for s in slots if s["date"] == date]
    return slots


def book_clinic_appointment(slot_id: str) -> dict:
    slots = json.loads(DATA_FILE.read_text())
    slot = next((s for s in slots if s["id"] == slot_id), None)

    if slot is None:
        return {"success": False, "message": f"No slot found with id {slot_id}."}
    if not slot["available"]:
        return {"success": False, "message": f"That {slot['time']} slot with {slot['doctor']} is already booked."}

    slot["available"] = False
    DATA_FILE.write_text(json.dumps(slots, indent=2))

    bookings_log.record_booking(
        kind="clinic",
        title=f"{slot['type']} with {slot['doctor']}",
        subtitle="Health Center",
        date=slot["date"],
        time=slot["time"],
    )
    return {"success": True, "message": f"Appointment booked with {slot['doctor']} at {slot['time']} on {slot['date']}."}
