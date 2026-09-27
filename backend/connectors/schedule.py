import json
from datetime import datetime, timedelta
from pathlib import Path

import availability
import current_time
from connectors.academic import get_courses, get_next_class_overall
from connectors.booking_proposals import _parse_date, _parse_time

TIMETABLE_FILE = Path(__file__).resolve().parent.parent.parent / "data" / "timetable.json"
_DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

GET_SCHEDULE_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_my_schedule",
        "description": (
            "The student's class schedule: their NEXT class (course, time, building, room, "
            "minutes until it starts) and the classes on a given day (default today). Use for "
            "'what class do I have next', 'where is my class', 'what do I have today'."
        ),
        "parameters": {
            "type": "object",
            "properties": {"date": {"type": "string", "description": "Optional YYYY-MM-DD, default today"}},
        },
    },
}


def get_my_schedule(date: str | None = None) -> dict:

    day = datetime.strptime(date, "%Y-%m-%d") if date else current_time.now()
    weekday = _DAYS[day.weekday()]
    courses = {c["id"]: c for c in get_courses()}
    classes = [
        {"code": courses[e["course_id"]]["code"], "name": courses[e["course_id"]]["name"],
         "start": e["start"], "end": e["end"], "location": e["location"], "room": e["room"]}
        for e in json.loads(TIMETABLE_FILE.read_text()) if e["day"] == weekday
    ]
    classes.sort(key=lambda c: c["start"])
    return {"date": day.strftime("%Y-%m-%d"), "weekday": weekday, "classes": classes,
            "next_class": get_next_class_overall()}


CHECK_CLASS_SCHEMA = {
    "type": "function",
    "function": {
        "name": "check_class_at",
        "description": (
            "Check the student's timetable for a day and optionally a time: 'do I have a class then', "
            "'am I free Monday at 10am', 'what classes do I have on Tuesday'. Use it for any question "
            "about whether they have class at a given date/time or part of the day ('this afternoon', 'Monday morning'), "
            "including a time just proposed for a booking."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "when": {"type": "string", "description": "Day as said or YYYY-MM-DD, e.g. 'wednesday', '2026-09-30'. Omit for today."},
                "time": {"type": "string", "description": "Time like '3pm' or '15:00'. Omit to list the whole day."},
                "duration_minutes": {"type": "integer", "description": "How long they need, default 60"},
            },
        },
    },
}


def check_class_at(when: str | None = None, time: str | None = None, duration_minutes: int = 60) -> dict:
    now = current_time.now()
    day = _parse_date(when, now)
    if day is None:
        return {"summary": f"I didn't understand the day '{when}'.", "cards": []}
    classes = availability.classes_on(day)
    day_text = f"{day:%a %d %b}"
    listing = ", ".join(f"{c['code']} {c['start']:%H:%M}-{c['end']:%H:%M} in {c['where']}" for c in classes)

    part = next((w for w in ("morning", "afternoon", "evening") if w in (time or "").lower()), None)
    if part:
        lo, hi = {"morning": ("08:00", "12:00"), "afternoon": ("12:00", "17:00"), "evening": ("17:00", "22:00")}[part]
        lo_dt = datetime.strptime(f"{day:%Y-%m-%d} {lo}", "%Y-%m-%d %H:%M")
        hi_dt = datetime.strptime(f"{day:%Y-%m-%d} {hi}", "%Y-%m-%d %H:%M")
        lo_dt = max(lo_dt, now) if day.date() == now.date() else lo_dt
        inside = [c for c in classes if c["start"] < hi_dt and c["end"] > lo_dt]
        cursor, gaps = lo_dt, []
        for c in inside:
            if c["start"] > cursor:
                gaps.append(f"{cursor:%H:%M}-{c['start']:%H:%M}")
            cursor = max(cursor, c["end"])
        if cursor < hi_dt:
            gaps.append(f"{cursor:%H:%M}-{hi_dt:%H:%M}")
        busy = ", ".join(f"{c['code']} {c['start']:%H:%M}-{c['end']:%H:%M} in {c['where']}" for c in inside)
        head = f"{day_text} {part}"
        if not inside:
            return {"summary": f"You have no classes in the {part} on {day_text}; you're free {lo_dt:%H:%M}-{hi_dt:%H:%M}.", "cards": []}
        return {"summary": f"{head}: you have {busy}. Free: {', '.join(gaps) or 'no gaps'}.", "cards": []}

    hhmm = _parse_time(time)
    if hhmm is None or hhmm == "earliest":
        return {"summary": (f"On {day_text} you have: {listing}." if classes else f"You have no classes on {day_text}."), "cards": []}

    start = datetime.strptime(f"{day:%Y-%m-%d} {hhmm}", "%Y-%m-%d %H:%M")
    end = start + timedelta(minutes=duration_minutes)
    direct = next((c for c in classes if start < c["end"] and end > c["start"]), None)
    if direct:
        return {"summary": (f"At {hhmm} on {day_text} you have {direct['label']} "
                            f"({direct['start']:%H:%M}-{direct['end']:%H:%M}) in {direct['where']}, so you are not free then."), "cards": []}
    near = availability.clash_with(start, end, classes)
    if near:
        return {"summary": (f"You have no class at {hhmm} on {day_text}, but {near['code']} is right next to it "
                            f"({near['start']:%H:%M}-{near['end']:%H:%M}), so it would be tight."), "cards": []}
    extra = f" Your classes that day: {listing}." if classes else " You have no classes that day."
    return {"summary": f"You're free at {hhmm} on {day_text}.{extra}", "cards": []}


GET_CREDITS_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_credit_hours",
        "description": "Credit hours per enrolled course and the total. Use for 'how many credits do I have'.",
        "parameters": {"type": "object", "properties": {}},
    },
}


def get_credit_hours() -> dict:
    courses = [{"code": c["code"], "name": c["name"], "credits": c["credits"]} for c in get_courses()]
    return {"courses": courses, "total_credits": sum(c["credits"] or 0 for c in courses)}
