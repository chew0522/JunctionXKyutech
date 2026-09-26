from datetime import datetime

import current_time
from connectors.academic import get_next_class
from connectors.cafe import get_cafe_crowd
from connectors.campus_map import get_walk_minutes

# Demo-only: the student's current location, hardcoded like current_time.DEMO_NOW so
# this can be staged reliably. In a real app this would come from device location.
STUDENT_CURRENT_ZONE = "Library"

PLAN_COFFEE_SCHEMA = {
    "type": "function",
    "function": {
        "name": "plan_coffee_run",
        "description": (
            "Figure out whether the student has time to grab coffee before their next "
            "class for a given course, and recommend the best cafe. Computes real walk "
            "times and cafe wait times — do not estimate this yourself, always call this tool."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "course_id": {"type": "string", "description": "e.g. course-ee150"},
            },
            "required": ["course_id"],
        },
    },
}


def plan_coffee_run(course_id: str) -> dict:
    next_class = get_next_class(course_id)
    if next_class is None:
        return {"feasible": False, "message": "No upcoming class found for that course."}

    class_time = datetime.strptime(f"{next_class['date']} {next_class['time']}", "%Y-%m-%d %H:%M")
    minutes_until_class = int((class_time - current_time.now()).total_seconds() / 60)

    if minutes_until_class <= 0:
        return {"feasible": False, "message": "That class has already started or passed."}

    options = []
    for cafe in get_cafe_crowd():
        walk_to_cafe = get_walk_minutes(STUDENT_CURRENT_ZONE, cafe["zone"])
        walk_to_class = get_walk_minutes(cafe["zone"], next_class["location"])
        total_minutes_needed = walk_to_cafe + cafe["wait_minutes"] + walk_to_class
        options.append(
            {
                "cafe": cafe["name"],
                "total_minutes_needed": total_minutes_needed,
                "buffer_minutes": minutes_until_class - total_minutes_needed,
            }
        )

    options.sort(key=lambda o: o["total_minutes_needed"])
    best = options[0]

    return {
        "feasible": best["buffer_minutes"] >= 0,
        "minutes_until_class": minutes_until_class,
        "recommended_cafe": best["cafe"],
        "total_minutes_needed": best["total_minutes_needed"],
        "buffer_minutes": best["buffer_minutes"],
        "class_location": f"{next_class['location']} {next_class['room']}",
        "all_options": options,
    }
