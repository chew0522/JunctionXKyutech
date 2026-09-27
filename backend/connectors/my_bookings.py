from datetime import datetime

import bookings_log
import current_time

GET_MY_BOOKINGS_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_my_bookings",
        "description": "The student's upcoming bookings and appointments (rooms, facilities, clinic, bus trips). Use for 'what did I book', 'what appointments do I have'.",
        "parameters": {"type": "object", "properties": {}},
    },
}


def get_my_bookings() -> dict:
    now = current_time.now()
    upcoming = []
    for b in bookings_log.get_bookings():
        when = datetime.strptime(f"{b['date']} {b['time']}", "%Y-%m-%d %H:%M")
        if when >= now:
            upcoming.append((when, b))
    upcoming.sort(key=lambda x: x[0])
    if not upcoming:
        return {"bookings": [], "note": "You have no upcoming bookings."}
    return {"bookings": [
        {"what": b["title"], "where": b["subtitle"], "when": f"{when:%a %d %b} at {when:%H:%M}", "kind": b["kind"]}
        for when, b in upcoming
    ]}
