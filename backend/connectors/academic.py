import json
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent.parent / "data"
COURSES_FILE = DATA_DIR / "courses.json"
MATERIALS_FILE = DATA_DIR / "materials.json"
ASSIGNMENTS_FILE = DATA_DIR / "assignments.json"
CLASS_SCHEDULE_FILE = DATA_DIR / "class_schedule.json"

GET_COURSES_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_courses",
        "description": "List the student's enrolled courses for this semester.",
        "parameters": {"type": "object", "properties": {}},
    },
}

GET_MATERIALS_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_course_materials",
        "description": "List academic materials (slides, readings, recordings) for a course.",
        "parameters": {
            "type": "object",
            "properties": {
                "course_id": {"type": "string", "description": "e.g. course-cs301"},
            },
            "required": ["course_id"],
        },
    },
}

GET_ASSIGNMENTS_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_assignments",
        "description": "List assignments set by lecturers, optionally filtered to a course or to only pending (not yet submitted) ones.",
        "parameters": {
            "type": "object",
            "properties": {
                "course_id": {"type": "string", "description": "Optional, e.g. course-cs301"},
                "pending_only": {"type": "boolean", "description": "If true, only return unsubmitted assignments"},
            },
        },
    },
}

def get_courses() -> list[dict]:
    courses = json.loads(COURSES_FILE.read_text())
    registered = json.loads((DATA_DIR / "registration.json").read_text())["registered"]
    credits = {r["code"]: r["credits"] for r in registered}
    for c in courses:
        c["credits"] = credits.get(c["code"])
    return courses


def get_next_class(course_id: str) -> dict | None:
    """Not an agent tool — used by plan_coffee_run (connectors/planner.py) to look up
    when/where a course's next class is, without exposing raw schedule data as a tool."""
    schedule = json.loads(CLASS_SCHEDULE_FILE.read_text())
    upcoming = [s for s in schedule if s["course_id"] == course_id]
    upcoming.sort(key=lambda s: (s["date"], s["time"]))
    return upcoming[0] if upcoming else None


def get_course_materials(course_id: str) -> list[dict]:
    materials = json.loads(MATERIALS_FILE.read_text())
    return [m for m in materials if m["course_id"] == course_id]


def get_assignments(course_id: str | None = None, pending_only: bool = False) -> list[dict]:
    assignments = json.loads(ASSIGNMENTS_FILE.read_text())
    if course_id:
        assignments = [a for a in assignments if a["course_id"] == course_id]
    if pending_only:
        assignments = [a for a in assignments if not a["submitted"]]
    return assignments


def submit_assignment(assignment_id: str) -> dict:
    """Deliberately NOT exposed as an agent tool (no *_SCHEMA here, not registered in
    agent.py) — the chatbot must never submit on the student's behalf. This is called
    only from the Courses page's own explicit confirm-then-submit UI flow (REST route
    in main.py), where the student directly taps a real button, not an AI-mediated
    action."""
    assignments = json.loads(ASSIGNMENTS_FILE.read_text())
    assignment = next((a for a in assignments if a["id"] == assignment_id), None)

    if assignment is None:
        return {"success": False, "message": f"No assignment found with id {assignment_id}."}
    if assignment["submitted"]:
        return {"success": False, "message": f"\"{assignment['title']}\" was already submitted."}

    assignment["submitted"] = True
    ASSIGNMENTS_FILE.write_text(json.dumps(assignments, indent=2))
    return {"success": True, "message": f"\"{assignment['title']}\" submitted."}


def get_next_class_overall() -> dict | None:
    """Earliest class still to come across all courses (used by the schedule tool and as the
    coffee planner's default), so the model never has to guess which class 'my next class' is."""
    from datetime import datetime

    import current_time

    now = current_time.now()
    courses = {c["id"]: c for c in get_courses()}
    upcoming = []
    for s in json.loads(CLASS_SCHEDULE_FILE.read_text()):
        when = datetime.strptime(f"{s['date']} {s['time']}", "%Y-%m-%d %H:%M")
        if when > now:
            upcoming.append((when, s))
    if not upcoming:
        return None
    when, s = min(upcoming, key=lambda x: x[0])
    c = courses[s["course_id"]]
    return {"course_id": s["course_id"], "code": c["code"], "name": c["name"], "date": s["date"],
            "time": s["time"], "location": s["location"], "room": s["room"],
            "minutes_until": int((when - now).total_seconds() / 60)}
