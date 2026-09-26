"""Shared ledger of confirmed bookings across rooms/clinic/facilities — same pattern as
chat_log.py and nudges.py (a cross-cutting concern, not a connector). This exists
because "available: false" in each connector's own data file means "not bookable right
now" for lots of reasons (someone else has it, it's closed) — it does NOT mean "the
student booked it". Anything that wants to show "your appointments" needs an actual
record of what THIS student booked, which is what this module provides."""

import json
import uuid
from pathlib import Path

import current_time

LOG_FILE = Path(__file__).resolve().parent.parent / "data" / "my_bookings.json"


def record_booking(kind: str, title: str, subtitle: str, date: str, time: str) -> None:
    """kind is a short tag like 'room', 'clinic', 'facility' — used only for picking an
    icon client-side. date/time are the booked slot's own date/time, not the booking
    timestamp."""
    bookings = _load_all()
    bookings.append(
        {
            "id": str(uuid.uuid4())[:8],
            "kind": kind,
            "title": title,
            "subtitle": subtitle,
            "date": date,
            "time": time,
            "booked_at": current_time.now().isoformat(),
        }
    )
    LOG_FILE.write_text(json.dumps(bookings, indent=2))


def get_bookings() -> list[dict]:
    return _load_all()


def _load_all() -> list[dict]:
    if not LOG_FILE.exists():
        return []
    return json.loads(LOG_FILE.read_text())
