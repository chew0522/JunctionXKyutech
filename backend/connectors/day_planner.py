import json
from datetime import datetime, timedelta
from pathlib import Path

import availability
import current_time
from connectors.academic import get_assignments, get_courses, get_next_class, get_next_class_overall
from connectors.bus_sim import get_my_location, plan_bus_trip, resolve_place, trip_cards, walk_minutes_between
from connectors.cafe import get_cafe_crowd
from connectors.clinic import get_clinic_slots
from connectors.events import get_events
from connectors.rooms import get_study_rooms

TIMETABLE_FILE = Path(__file__).resolve().parent.parent.parent / "data" / "timetable.json"
_DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
EVENT_MINUTES = 90  # events have no end time in the mock data
CLINIC_MINUTES = 30
TRAVEL_BUFFER = 10
DAY_END_HOUR = 21


_classes_on = availability.classes_on
_clash = availability.clash_with


def _hm(dt: datetime) -> str:
    return dt.strftime("%H:%M")


def _next_class(course_id: str | None) -> dict | None:
    now = current_time.now()
    if course_id:
        raw = get_next_class(course_id)
        course = next((c for c in get_courses() if c["id"] == course_id), None)
        if raw is None or course is None:
            return None
        label = f"{course['code']} {course['name']}"
    else:
        raw = get_next_class_overall()
        if raw is None:
            return None
        label = f"{raw['code']} {raw['name']}"
    start = datetime.strptime(f"{raw['date']} {raw['time']}", "%Y-%m-%d %H:%M")
    return {"label": label, "start": start, "minutes_until": int((start - now).total_seconds() / 60),
            "location": raw["location"], "room": raw["room"]}


PLAN_TO_CLASS_SCHEMA = {
    "type": "function",
    "function": {
        "name": "plan_getting_to_class",
        "description": (
            "How to get from the student's current location to their next class: bus vs walking, "
            "travel time, whether they will be on time and the latest they can leave. Use for "
            "'how do I get to class', 'will I make it to class on time', 'when should I leave'."
        ),
        "parameters": {"type": "object", "properties": {"course_id": {"type": "string", "description": "Optional, default next class"}}},
    },
}


def plan_getting_to_class(course_id: str | None = None) -> dict:
    nxt = _next_class(course_id)
    if nxt is None or nxt["minutes_until"] <= 0:
        return {"summary": "There is no upcoming class to get to.", "cards": []}
    where = f"{nxt['location']} {nxt['room']}"
    head = f"Your next class, {nxt['label']}, starts at {_hm(nxt['start'])} ({nxt['minutes_until']} min from now) in {where}."
    trip = plan_bus_trip(nxt["location"])
    if "from_id" not in trip:
        return {"summary": f"{head} {trip['error']}", "cards": []}

    choices = [("walk", trip["walk_minutes"], None)]
    for o in trip["options"]:
        choices.append(("bus", o["total_minutes"], o["route"]))
    for t in trip["transfers"]:
        choices.append(("bus and change", t["total_minutes"], f"{t['leg1']['route']} then {t['leg2']['route']}"))
    mode, minutes, route = min(choices, key=lambda c: c[1])
    spare = nxt["minutes_until"] - minutes
    how = f"walking takes about {minutes} min" if mode == "walk" else f"{route} takes about {minutes} min including the wait"
    walk_note = "" if mode == "walk" else f" (walking would take {trip['walk_minutes']} min)"
    verdict = (f"you'd arrive with {spare} min to spare; leave by {_hm(nxt['start'] - timedelta(minutes=minutes))}"
               if spare >= 0 else f"you'd be {-spare} min late")
    summary = f"{head} From {trip['origin']}, the fastest way is {mode}: {how}{walk_note}, so {verdict}."
    return {"summary": summary, "cards": trip_cards(trip) if mode != "walk" else [],
            "fastest": mode, "minutes_needed": minutes, "spare_minutes": spare}


PLAN_DAY_SCHEMA = {
    "type": "function",
    "function": {
        "name": "plan_my_day",
        "description": (
            "A time-aware briefing for right now: next class, remaining classes today, free gaps, "
            "what is due or overdue, and today's events (flagging clashes with classes). Use for "
            "'what should I do now', 'plan my day', 'what's on today', 'am I free this afternoon'."
        ),
        "parameters": {"type": "object", "properties": {}},
    },
}


def plan_my_day() -> dict:
    now = current_time.now()
    classes = [c for c in _classes_on(now) if c["end"] > now]
    parts = [f"It's {_hm(now)} on {now:%A}."]

    if classes:
        first = classes[0]
        if first["start"] <= now:
            parts.append(f"You're in {first['label']} until {_hm(first['end'])}.")
        else:
            parts.append(f"Next class: {first['label']} at {_hm(first['start'])} in {first['where']} "
                         f"({int((first['start'] - now).total_seconds() / 60)} min).")
        later = [f"{c['label']} at {_hm(c['start'])}" for c in classes[1:]]
        if later:
            parts.append("Later today: " + ", ".join(later) + ".")
    else:
        parts.append("No more classes today.")

    gaps, cursor = [], now
    for c in classes:
        if c["start"] > cursor and (c["start"] - cursor) >= timedelta(minutes=20):
            gaps.append((cursor, c["start"]))
        cursor = max(cursor, c["end"])
    day_end = now.replace(hour=DAY_END_HOUR, minute=0, second=0, microsecond=0)
    if day_end > cursor and (day_end - cursor) >= timedelta(minutes=20):
        gaps.append((cursor, day_end))
    if gaps:
        parts.append("Free: " + ", ".join(f"{_hm(a)}-{_hm(b)} ({int((b - a).total_seconds() / 60)} min)" for a, b in gaps) + ".")
        first_gap = gaps[0]
        if classes and first_gap[1] == classes[0]["start"] and (first_gap[1] - first_gap[0]) >= timedelta(minutes=25):
            parts.append("That's enough for a coffee before class.")

    overdue, due_today = [], []
    for a in get_assignments(pending_only=True):
        due = datetime.strptime(f"{a['due_date']} {a['due_time']}", "%Y-%m-%d %H:%M")
        if due < now:
            overdue.append(a["title"])
        elif due.date() == now.date():
            due_today.append(f"{a['title']} by {_hm(due)}")
    if due_today:
        parts.append("Due today: " + "; ".join(due_today) + ".")
    if overdue:
        parts.append("Overdue: " + "; ".join(overdue) + ".")

    events = []
    for e in get_events(date=now.strftime("%Y-%m-%d")):
        start = datetime.strptime(f"{e['date']} {e['time']}", "%Y-%m-%d %H:%M")
        if start + timedelta(minutes=EVENT_MINUTES) <= now:
            continue
        clash = _clash(start, start + timedelta(minutes=EVENT_MINUTES), classes)
        events.append(f"{e['name']} at {_hm(start)} in {e['venue']}" + (f" (clashes with {clash['code']})" if clash else " (no clash)"))
    if events:
        parts.append("Events today: " + "; ".join(events) + ".")
    return {"summary": " ".join(parts), "cards": []}


CLASH_FREE_SCHEMA = {
    "type": "function",
    "function": {
        "name": "find_clash_free",
        "description": (
            "Find clinic appointment slots or campus events that do NOT clash with the student's "
            "classes. Use for 'a clinic slot that doesn't clash with my classes', 'events I can go "
            "to without missing class'. kind is 'clinic' or 'events'; date (YYYY-MM-DD) optional."
        ),
        "parameters": {
            "type": "object",
            "properties": {"kind": {"type": "string", "enum": ["clinic", "events"]}, "date": {"type": "string"}},
            "required": ["kind"],
        },
    },
}


def find_clash_free(kind: str, date: str | None = None) -> dict:
    now = current_time.now()
    free, clashing = [], []
    cards = []

    if kind == "clinic":
        for s in get_clinic_slots(date=date):
            start = datetime.strptime(f"{s['date']} {s['time']}", "%Y-%m-%d %H:%M")
            if not s["available"] or start <= now:
                continue
            clash = _clash(start, start + timedelta(minutes=CLINIC_MINUTES), _classes_on(start))
            text = f"{start:%a %d %b} {_hm(start)} with {s['doctor']} ({s['type']})"
            (clashing if clash else free).append(text + (f" clashes with {clash['code']}" if clash else ""))
            if not clash:
                cards.append({"kind": "clinic", "id": f"{s['doctor']}|{s['type']}", "title": s["doctor"],
                              "subtitle": f"{s['type']} · {start:%a %d %b} {_hm(start)}", "available": True})
        noun = "clinic slots"
    else:
        days = [now + timedelta(days=i) for i in range(4)] if not date else [datetime.strptime(date, "%Y-%m-%d")]
        for day in days:
            classes = _classes_on(day)
            for e in get_events(date=f"{day:%Y-%m-%d}"):
                start = datetime.strptime(f"{e['date']} {e['time']}", "%Y-%m-%d %H:%M")
                if start <= now:
                    continue
                clash = _clash(start, start + timedelta(minutes=EVENT_MINUTES), classes)
                text = f"{e['name']} on {start:%a %d %b} at {_hm(start)} in {e['venue']}"
                (clashing if clash else free).append(text + (f" clashes with {clash['code']}" if clash else ""))
        noun = "events"

    def short(items: list[str], limit: int) -> str:
        more = f" (and {len(items) - limit} more)" if len(items) > limit else ""
        return "; ".join(items[:limit]) + more

    if free:
        summary = f"These {noun} don't clash with your classes: " + short(free, 5) + "."
    else:
        summary = f"None of the upcoming {noun} are clash-free."
    if clashing:
        summary += " Ruled out: " + short(clashing, 3) + "."
    return {"summary": summary, "cards": cards[:4]}


STUDY_SPOT_SCHEMA = {
    "type": "function",
    "function": {
        "name": "find_study_spot",
        "description": (
            "Find a study room near the student that is free, with walking time from where they are "
            "and how long they have before their next class. Use for 'where can I study', 'a room for "
            "4 people near me'."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "group_size": {"type": "integer", "description": "Number of people, default 1"},
                "whiteboard": {"type": "boolean", "description": "Only rooms with a whiteboard"},
            },
        },
    },
}


def find_study_spot(group_size: int = 1, whiteboard: bool = False) -> dict:
    me = get_my_location()
    rooms = []
    for r in get_study_rooms():
        if r["capacity"] < group_size or (whiteboard and not r["has_whiteboard"]):
            continue
        building = resolve_place(r["building"])
        walk = walk_minutes_between(me["building_id"], building["id"]) if building else 5
        rooms.append({**r, "walk": walk, "building_id": building["id"] if building else None})
    rooms.sort(key=lambda r: (not r["available"], r["walk"]))
    if not rooms:
        return {"summary": f"No study room seats {group_size} people.", "cards": []}

    nxt = _next_class(None)
    gap = f" You have {nxt['minutes_until']} min before {nxt['label']}." if nxt and nxt["minutes_until"] > 0 else ""
    free = [r for r in rooms if r["available"]]
    if free:
        best = free[0]
        summary = (f"{best['name']} ({best['building']}, floor {best['floor']}, seats {best['capacity']}"
                   f"{', whiteboard' if best['has_whiteboard'] else ''}) is free and about {best['walk']} min from you at {me['name']}.{gap}")
        cafe = next((c for c in get_cafe_crowd() if resolve_place(c["zone"]) and resolve_place(c["zone"])["id"] == best["building_id"]), None)
        if cafe:
            summary += f" The {cafe['name']} nearby has a {cafe['crowd_level']} crowd right now ({cafe['wait_minutes']} min wait)."
    else:
        who = "1 person" if group_size == 1 else f"{group_size} people"
        summary = (f"No room for {who} is free right now: " + ", ".join(r["name"] for r in rooms[:3]) +
                   f" are all in use. You can still book one for a later time.{gap}")

    cards = [{"kind": "room", "id": r["id"], "title": r["name"],
              "subtitle": f"{r['building']}, Floor {r['floor']} · {r['capacity']} seats"
                          f"{' · whiteboard' if r['has_whiteboard'] else ''} · {r['walk']} min walk"
                          f"{' · free now' if r['available'] else ' · in use now'}",
              "available": True} for r in rooms[:4]]
    return {"summary": summary, "cards": cards}
