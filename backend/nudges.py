import json
from datetime import datetime
from pathlib import Path

import current_time
from connectors.academic import get_assignments, get_courses
from connectors.events import get_events

DELIVERED_FILE = Path(__file__).resolve().parent.parent / "data" / "nudges_delivered.json"


def get_new_nudges(now: datetime | None = None) -> list[dict]:
    """Returns only nudges that haven't been delivered before. Mock data doesn't change
    on its own (the room stays booked, the assignment stays pending), so without this
    filter every poll of /nudges would re-fire the same nudge forever — a real proactive
    nudge should surface once, not nag on every app open."""
    all_nudges = _evaluate_nudges(now or current_time.now())
    delivered = _load_delivered()

    fresh = [n for n in all_nudges if n["id"] not in delivered]
    if fresh:
        delivered.update(n["id"] for n in fresh)
        _save_delivered(delivered)

    return fresh


def reset_delivered() -> None:
    """Clears delivery history so nudges can fire again — for local testing via /reset,
    not something a real client ever calls."""
    _save_delivered(set())


def _load_delivered() -> set[str]:
    if not DELIVERED_FILE.exists():
        return set()
    return set(json.loads(DELIVERED_FILE.read_text()))


def _save_delivered(ids: set[str]) -> None:
    DELIVERED_FILE.write_text(json.dumps(sorted(ids), indent=2))


def _evaluate_nudges(now: datetime) -> list[dict]:
    """Evaluates simple rules against mock data and returns any nudge cards that
    currently match. Shape matches chat-ui.md's Nudge card spec: title, body, pills,
    buttons. Called only by get_new_nudges — see its docstring for why."""
    nudges = []

    courses_by_id = {c["id"]: c for c in get_courses()}
    for assignment in get_assignments(pending_only=True):
        due = datetime.strptime(f"{assignment['due_date']} {assignment['due_time']}", "%Y-%m-%d %H:%M")
        hours_until = (due - now).total_seconds() / 3600
        if 0 < hours_until <= 12:
            course = courses_by_id.get(assignment["course_id"])
            course_label = f"{course['code']} {course['name']}" if course else assignment["course_id"]
            nudges.append(
                {
                    "id": f"nudge-assignment-{assignment['id']}",
                    "title": f"{assignment['title']} is due soon",
                    "body": (
                        f"{assignment['title']} ({course_label}) is due at "
                        f"{assignment['due_time']} and isn't submitted yet."
                    ),
                    "pills": [
                        {"icon": "clock", "text": f"Due {assignment['due_time']}"},
                        {"icon": "clock", "text": f"{int(hours_until)}h left"},
                    ],
                    "buttons": [
                        {"label": "Show my to-dos", "style": "primary"},
                        {"label": "Got it", "style": "secondary"},
                    ],
                }
            )

    for event in get_events(date=now.strftime("%Y-%m-%d")):
        event_time = datetime.strptime(f"{event['date']} {event['time']}", "%Y-%m-%d %H:%M")
        minutes_until = (event_time - now).total_seconds() / 60
        if 0 < minutes_until <= 15:
            nudges.append(
                {
                    "id": f"nudge-event-{event['id']}",
                    "title": f"{event['name']} starts in {int(minutes_until)} min",
                    "body": event["description"],
                    "pills": [
                        {"icon": "clock", "text": event["time"]},
                        {"icon": "map-pin", "text": event["venue"]},
                    ],
                    "buttons": [
                        {"label": "Tell me more", "style": "primary"},
                        {"label": "Not going", "style": "secondary"},
                    ],
                }
            )

    return nudges
