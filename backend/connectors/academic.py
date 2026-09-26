import json
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent.parent / "data"
COURSES_FILE = DATA_DIR / "courses.json"
MATERIALS_FILE = DATA_DIR / "materials.json"
ASSIGNMENTS_FILE = DATA_DIR / "assignments.json"

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

SUBMIT_ASSIGNMENT_SCHEMA = {
    "type": "function",
    "function": {
        "name": "submit_assignment",
        "description": "Submit an assignment through the submission portal, marking it as turned in.",
        "parameters": {
            "type": "object",
            "properties": {
                "assignment_id": {"type": "string", "description": "e.g. assign-1"},
            },
            "required": ["assignment_id"],
        },
    },
}


def get_courses() -> list[dict]:
    return json.loads(COURSES_FILE.read_text())


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
    assignments = json.loads(ASSIGNMENTS_FILE.read_text())
    assignment = next((a for a in assignments if a["id"] == assignment_id), None)

    if assignment is None:
        return {"success": False, "message": f"No assignment found with id {assignment_id}."}
    if assignment["submitted"]:
        return {"success": False, "message": f"\"{assignment['title']}\" was already submitted."}

    assignment["submitted"] = True
    ASSIGNMENTS_FILE.write_text(json.dumps(assignments, indent=2))
    return {"success": True, "message": f"✅ \"{assignment['title']}\" submitted."}
