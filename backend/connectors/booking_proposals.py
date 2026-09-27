import re
from datetime import datetime, timedelta

import availability
import current_time
from connectors.clinic import get_clinic_slots
from connectors.day_planner import _classes_on, _clash
from connectors.facilities import get_facilities
from connectors.rooms import get_study_rooms

_WEEKDAYS = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
_PART_OF_DAY = {"morning": "09:00", "noon": "12:00", "lunch": "12:00", "afternoon": "13:00",
                "evening": "18:00", "night": "19:00"}
WINDOWS = {"morning": ("09:00", "12:00"), "afternoon": ("13:00", "17:00"), "evening": ("18:00", "22:00")}
SLOT_TIMES = [f"{m // 60:02d}:{m % 60:02d}" for m in range(8 * 60, 22 * 60 + 1, 30)]

PROPOSE_BOOKING_SCHEMA = {
    "type": "function",
    "function": {
        "name": "propose_booking",
        "description": (
            "Turn a booking request into a concrete proposal (a free slot on a date and time) that the "
            "student confirms with one tap. Use whenever the student asks to book, reserve or get a "
            "study room, a sports facility/hall, or a clinic appointment, even if vague ('basketball "
            "Tuesday', 'book one for me'). You cannot book directly; this only proposes."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "kind": {"type": "string", "enum": ["room", "facility", "clinic"]},
                "what": {"type": "string", "description": "What they want as they said it: 'basketball court', 'study room', 'gym', 'counseling', 'Dr Tanaka', 'doctor'"},
                "when": {"type": "string", "description": "Day as they said it: 'tomorrow', 'tuesday', '2026-10-02'. Omit if not stated."},
                "time": {"type": "string", "description": "A time ('6pm', '18:00') or part of day ('morning', 'afternoon', 'evening'). Omit if not stated (the tool then asks the student which part of the day). Use 'earliest' if they say any time / asap."},
                "group_size": {"type": "integer"},
                "whiteboard": {"type": "boolean"},
            },
            "required": ["kind", "what"],
        },
    },
}


def _parse_date(text: str | None, now: datetime) -> datetime | None:
    t = (text or "").strip().lower()
    if not t or t == "today":
        return now
    if "day after tomorrow" in t:
        return now + timedelta(days=2)
    if "tomorrow" in t:
        return now + timedelta(days=1)
    iso = re.search(r"\d{4}-\d{2}-\d{2}", t)
    if iso:
        return datetime.strptime(iso.group(), "%Y-%m-%d")
    for i, name in enumerate(_WEEKDAYS):
        if name in t or (len(t) >= 3 and re.search(rf"\b{name[:3]}\b", t)):
            ahead = (i - now.weekday()) % 7 or 7
            return now + timedelta(days=ahead)
    return None


def _parse_time(time_text: str | None) -> str | None:
    t = (time_text or "").strip().lower()
    if re.search(r"\b(earliest|asap|any ?time|whenever|now|first)\b", t):
        return "earliest"
    for word, hhmm in _PART_OF_DAY.items():
        if re.search(rf"\b{word}\b", t):
            return hhmm
    m = re.search(r"(\d{1,2})(?::?(\d{2}))?\s*(am|pm)?", t)
    if not m:
        return None
    hour, minute, ampm = int(m.group(1)), int(m.group(2) or 0), m.group(3)
    if ampm == "pm" and hour < 12:
        hour += 12
    if ampm == "am" and hour == 12:
        hour = 0
    if not (0 <= hour < 24 and 0 <= minute < 60):
        return None
    return f"{hour:02d}:{minute - minute % 30:02d}"


def _on(day_label: str) -> str:
    return day_label if day_label.lower() in ("today", "tomorrow") else f"on {day_label}"


def _first_free_slot(resource_id: str, name: str, day: datetime, start: str, now: datetime,
                     until: str | None = None, days: int = 5) -> tuple[str, str] | None:
    """Earliest free slot at/after `start` on `day` (before `until` if given), else over the next days."""
    for offset in range(0, days):
        d = day + timedelta(days=offset)
        date = d.strftime("%Y-%m-%d")
        for t in SLOT_TIMES:
            if offset == 0 and t < start:
                continue
            if until and t >= until and t != "22:00":
                continue
            if until and t == "22:00" and until != "22:00":
                continue
            if date == now.strftime("%Y-%m-%d") and t <= now.strftime("%H:%M"):
                continue
            if availability.slot_free(resource_id, name, date, t) and availability.class_clash(date, t) is None:
                return date, t
    return None


def _matches(name_source: str, what: str) -> bool:
    words = [w for w in re.findall(r"[a-z0-9]+", what.lower()) if len(w) >= 3 and w not in {"the", "for", "one", "book", "room", "court"}]
    text = name_source.lower()
    return any(w in text for w in words)


def propose_booking(kind: str, what: str, when: str | None = None, time: str | None = None,
                    group_size: int | None = None, whiteboard: bool | None = None) -> dict:
    now = current_time.now()
    day = _parse_date(when, now)
    if day is None:
        return {"summary": f"I didn't understand the day '{when}'. Which date would you like?", "cards": []}
    ask_part_of_day = not (time or "").strip()
    explicit_time = bool(re.search(r"\d", time or ""))
    requested_time = _parse_time(time)
    if requested_time == "earliest":
        requested_time = None
    start = requested_time or (now.strftime("%H:%M") if day.date() == now.date() else "09:00")
    day_label = (when or "today").strip()

    if kind == "clinic":
        if ask_part_of_day:
            asked = _ask_clinic_window(what, day, day_label, now)
            if asked:
                return asked
        return _propose_clinic(what, day, requested_time, now, explicit_time)

    generic_room = kind == "room" and not re.search(r"\d{3}|pod", what.lower())
    if kind == "room":
        pool = [r for r in get_study_rooms()
                if (group_size is None or r["capacity"] >= group_size) and (not whiteboard or r["has_whiteboard"])
                and (generic_room or _matches(r["name"], what))]
        where = lambda r: f"{r['building']}, Floor {r['floor']}"
    else:
        pool = [f for f in get_facilities() if _matches(f["name"], what)]
        if not pool and re.search(r"\b(sports?|facility|facilities|venue|space|court)\b", what.lower()):
            pool = [f for f in get_facilities() if f["category"] == "sports"]
        where = lambda f: f["location"]
    if not pool:
        return {"summary": f"I couldn't find a {kind} matching '{what}'.", "cards": []}

    if ask_part_of_day:
        windows = {}
        for label, (w_start, w_end) in WINDOWS.items():
            options = [(r, _first_free_slot(r["id"], r["name"], day, w_start, now, until=w_end, days=1)) for r in pool]
            options = [(r, s) for r, s in options if s]
            if options:
                windows[label] = min(options, key=lambda x: (x[1], x[0].get("capacity", 0)))
        if windows:
            listed = ", ".join(f"{label} (from {slot[1]})" for label, (_, slot) in windows.items())
            return {"summary": f"When {_on(day_label)}? Free windows for {what}: {listed}. Pick one and I'll choose the best slot for you to confirm.",
                    "choices": [f"{what.strip().capitalize()} {day_label} {label}" for label in windows], "cards": []}

    if explicit_time and requested_time:
        date_str = day.strftime("%Y-%m-%d")
        if date_str > now.strftime("%Y-%m-%d") or requested_time > now.strftime("%H:%M"):
            for r in sorted(pool, key=lambda x: x.get("capacity", 0)):
                if availability.slot_free(r["id"], r["name"], date_str, requested_time):
                    clash = availability.class_clash(date_str, requested_time)
                    warn = (f" Heads up: that's right around {clash['label']} ({clash['start']:%H:%M}-{clash['end']:%H:%M}), "
                            f"so you'd miss it. You can still book it if you want.") if clash else " (it doesn't clash with your classes)"
                    d = day
                    return {"summary": f"I can book {r['name']} ({where(r)}) on {d:%a %d %b} at {requested_time}.{warn} Tap Confirm to book it, or Change time to pick another.",
                            "cards": [{"kind": "proposal", "action": kind, "id": r["id"], "title": r["name"],
                                       "subtitle": f"{d:%a %d %b} · {requested_time} · {where(r)}", "date": date_str,
                                       "time": requested_time, "available": True}]}

    best = None
    for r in pool:
        slot = _first_free_slot(r["id"], r["name"], day, start, now)
        if slot and (best is None or slot < best[1] or (slot == best[1] and r.get("capacity", 0) < best[0].get("capacity", 0))):
            best = (r, slot)
    if best is None:
        return {"summary": f"I couldn't find a free slot for {what} in the next few days.", "cards": []}

    r, (date, slot_time) = best
    d = datetime.strptime(date, "%Y-%m-%d")
    when_text = f"{d:%a %d %b} at {slot_time}"
    asked = day.strftime("%Y-%m-%d") == date and (requested_time is None or requested_time == slot_time)
    requested_clash = availability.class_clash(day.strftime("%Y-%m-%d"), requested_time) if requested_time else None
    if asked:
        note = ""
    elif requested_clash:
        note = (f" (your requested {requested_time} clashes with {requested_clash['code']} at "
                f"{requested_clash['start']:%H:%M}, so this is the first slot that doesn't)")
    else:
        note = f" (that's the first free slot after {'your requested time' if day.strftime('%Y-%m-%d') == date else d.strftime('%a %d %b')})"
    if requested_time and not ("08:00" <= requested_time <= "22:00"):
        note = f" (bookings run 08:00-22:00, so {requested_time} isn't possible; this is the first free slot)"
    if not note:
        note = " (it doesn't clash with your classes)"
    summary = f"I can book {r['name']} ({where(r)}) on {when_text}{note}. Tap Confirm to book it, or Change time to pick another."
    card = {"kind": "proposal", "action": kind, "id": r["id"], "title": r["name"],
            "subtitle": f"{d:%a %d %b} · {slot_time} · {where(r)}", "date": date, "time": slot_time, "available": True}
    return {"summary": summary, "cards": [card]}


def _propose_clinic(what: str, day: datetime, requested_time: str | None, now: datetime, explicit_time: bool = False) -> dict:
    slots = []
    for s in get_clinic_slots():
        start = datetime.strptime(f"{s['date']} {s['time']}", "%Y-%m-%d %H:%M")
        if s["available"] and start > now:
            slots.append((start, s))
    typed = [(st, s) for st, s in slots if _matches(f"{s['doctor']} {s['type']}", what)]
    slots = typed or slots
    earliest = day.replace(hour=int((requested_time or "00:00")[:2]), minute=int((requested_time or "00:00")[3:]), second=0, microsecond=0)
    if day.date() == now.date() and requested_time is None:
        earliest = now
    later = sorted([x for x in slots if x[0] >= earliest], key=lambda x: x[0])
    if not later:
        return {"summary": "There are no open clinic slots after that time.", "cards": []}
    clash_free = [x for x in later if not _clash(x[0], x[0] + timedelta(minutes=30), _classes_on(x[0]))]
    exact = next((x for x in later if explicit_time and x[0].date() == day.date() and x[1]["time"] == requested_time), None)
    if exact:
        start, s = exact
        clash = _clash(start, start + timedelta(minutes=30), _classes_on(start))
        warn = (f" Heads up: that's right around {clash['label']} ({clash['start']:%H:%M}-{clash['end']:%H:%M}), so you'd miss it. "
                "You can still book it if you want.") if clash else ""
        card = {"kind": "proposal", "action": "clinic", "id": s["id"], "title": f"{s['type']} · {s['doctor']}",
                "subtitle": f"{start:%a %d %b} · {s['time']} · Health Center", "date": s["date"], "time": s["time"], "available": True}
        return {"summary": f"I can book {s['type']} with {s['doctor']} on {start:%a %d %b} at {s['time']}.{warn} Tap Confirm to book it, or Change time to pick another.", "cards": [card]}
    start, s = (clash_free or later)[0]
    avoided = "" if clash_free else " (it clashes with a class, but nothing else is open)"
    if clash_free and clash_free[0] != later[0]:
        avoided = " (the earlier slot would clash with your classes)"
    summary = (f"I can book {s['type']} with {s['doctor']} on {start:%a %d %b} at {s['time']}{avoided}. "
               "Tap Confirm to book it, or Change time to pick another.")
    card = {"kind": "proposal", "action": "clinic", "id": s["id"], "title": f"{s['type']} · {s['doctor']}",
            "subtitle": f"{start:%a %d %b} · {s['time']} · Health Center", "date": s["date"], "time": s["time"], "available": True}
    return {"summary": summary, "cards": [card]}


def _ask_clinic_window(what: str, day: datetime, day_label: str, now: datetime) -> dict | None:
    date = day.strftime("%Y-%m-%d")
    found: dict[str, str] = {}
    for s in get_clinic_slots(date=date):
        start = datetime.strptime(f"{s['date']} {s['time']}", "%Y-%m-%d %H:%M")
        if not s["available"] or start <= now or not _matches(f"{s['doctor']} {s['type']}", what) and _matches_any_clinic(what):
            continue
        for label, (w_start, w_end) in WINDOWS.items():
            if w_start <= s["time"] < w_end and label not in found:
                found[label] = s["time"]
    if not found:
        return None
    listed = ", ".join(f"{label} (from {t})" for label, t in found.items())
    return {"summary": f"When {_on(day_label)}? Open clinic times: {listed}. Pick one and I'll choose the best slot for you to confirm.",
            "choices": [f"{what.strip().capitalize()} appointment {day_label} {label}" for label in found], "cards": []}


def _matches_any_clinic(what: str) -> bool:
    return any(_matches(f"{s['doctor']} {s['type']}", what) for s in get_clinic_slots())
