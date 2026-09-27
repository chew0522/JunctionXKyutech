"""Slot-level availability for rooms and facilities. A resource is never 'booked out' as a
whole: only specific 30-minute slots are taken, either by other students (data/booked_slots.json)
or by this student's own earlier booking of that exact slot."""

import json
from datetime import datetime, timedelta
from pathlib import Path

import bookings_log
import current_time

BOOKED_FILE = Path(__file__).resolve().parent.parent / "data" / "booked_slots.json"
TIMETABLE_FILE = Path(__file__).resolve().parent.parent / "data" / "timetable.json"
_DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
BOOKING_MINUTES = 60  # assumed length of a room/facility booking when checking for class clashes
TRAVEL_BUFFER = 10


def taken_by_others(resource_id: str, date: str) -> set[str]:
    booked = json.loads(BOOKED_FILE.read_text())["booked"]
    return set(booked.get(resource_id, {}).get(date, []))


def slot_free(resource_id: str, name: str, date: str, time: str) -> bool:
    if time in taken_by_others(resource_id, date):
        return False
    return not any(b["title"] == name and b["date"] == date and b["time"] == time for b in bookings_log.get_bookings())


def classes_on(day: datetime) -> list[dict]:
    from connectors.academic import get_courses

    courses = {c["id"]: c for c in get_courses()}
    out = []
    for e in json.loads(TIMETABLE_FILE.read_text()):
        if e["day"] != _DAYS[day.weekday()]:
            continue
        start = datetime.strptime(f"{day:%Y-%m-%d} {e['start']}", "%Y-%m-%d %H:%M")
        end = datetime.strptime(f"{day:%Y-%m-%d} {e['end']}", "%Y-%m-%d %H:%M")
        c = courses[e["course_id"]]
        out.append({"label": f"{c['code']} {c['name']}", "code": c["code"], "start": start, "end": end,
                    "where": f"{e['location']} {e['room']}"})
    return sorted(out, key=lambda c: c["start"])


def clash_with(start: datetime, end: datetime, classes: list[dict]) -> dict | None:
    buf = timedelta(minutes=TRAVEL_BUFFER)
    return next((c for c in classes if start < c["end"] + buf and end + buf > c["start"]), None)


def class_clash(date: str, time: str, minutes: int = BOOKING_MINUTES) -> dict | None:
    """The class (if any) that a booking starting at date/time for `minutes` would run into."""
    start = datetime.strptime(f"{date} {time}", "%Y-%m-%d %H:%M")
    return clash_with(start, start + timedelta(minutes=minutes), classes_on(start))


def free_now(resource_id: str, name: str) -> bool:
    now = current_time.now()
    minutes = now.hour * 60 + now.minute
    if not 8 * 60 <= minutes <= 22 * 60:
        return False
    slot = minutes - minutes % 30
    return slot_free(resource_id, name, now.strftime("%Y-%m-%d"), f"{slot // 60:02d}:{slot % 60:02d}")
