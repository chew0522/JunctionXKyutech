from datetime import datetime

from connectors.academic import get_assignments

LIST_TODOS_SCHEMA = {
    "type": "function",
    "function": {
        "name": "todo_list",
        "description": (
            "List the student's to-do items. This is sourced entirely from pending "
            "(unsubmitted) lecturer assignments, sorted by due date — not a freeform "
            "personal list."
        ),
        "parameters": {"type": "object", "properties": {}},
    },
}


def todo_list() -> list[dict]:
    pending = get_assignments(pending_only=True)
    pending.sort(key=lambda a: (a["due_date"], a["due_time"]))
    return [
        {
            "id": a["id"],
            "task": a["title"],
            "due": f"{a['due_date']} {a['due_time']}",
            "course_id": a["course_id"],
        }
        for a in pending
    ]
