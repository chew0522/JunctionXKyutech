from datetime import datetime

from connectors.academic import get_assignments
from connectors.events import get_events
from connectors.rooms import get_study_rooms

# Demo-only: the "current time" is hardcoded so the nudge can be staged to fire on cue.
# Swap this for datetime.now() once you're ready to test against a real clock.
DEMO_NOW = datetime(2026, 9, 26, 14, 50)

USUAL_ROOM_ID = "room-204"


def check_nudges(now: datetime = DEMO_NOW) -> list[str]:
    """Evaluates simple rules against mock data and returns any nudge messages that fire."""
    nudges = []

    for event in get_events(date=now.strftime("%Y-%m-%d")):
        event_time = datetime.strptime(f"{event['date']} {event['time']}", "%Y-%m-%d %H:%M")
        minutes_until = (event_time - now).total_seconds() / 60
        if 0 < minutes_until <= 15:
            nudges.append(
                f"⏰ \"{event['name']}\" starts in {int(minutes_until)} min at {event['venue']} — leave now if it's far."
            )

    rooms = get_study_rooms()
    usual_room = next((r for r in rooms if r["id"] == USUAL_ROOM_ID), None)
    if usual_room and not usual_room["available"]:
        alternative = next((r for r in rooms if r["available"]), None)
        if alternative:
            nudges.append(
                f"📚 Your usual room ({usual_room['name']}) is booked — {alternative['name']} is free, want it instead?"
            )

    for assignment in get_assignments(pending_only=True):
        due = datetime.strptime(f"{assignment['due_date']} {assignment['due_time']}", "%Y-%m-%d %H:%M")
        hours_until = (due - now).total_seconds() / 3600
        if 0 < hours_until <= 12:
            nudges.append(
                f"📝 \"{assignment['title']}\" is due in {int(hours_until)}h and you haven't submitted it yet."
            )

    return nudges
