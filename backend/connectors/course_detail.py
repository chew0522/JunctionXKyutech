import json
from pathlib import Path

import current_time
from connectors.academic import get_assignments, get_course_materials, get_courses

EXTRAS_FILE = Path(__file__).resolve().parent.parent.parent / "data" / "course_extras.json"


def get_course_detail(course_id: str) -> dict | None:
    course = next((c for c in get_courses() if c["id"] == course_id), None)
    if course is None:
        return None
    extras = json.loads(EXTRAS_FILE.read_text()).get(course_id, {})
    now = current_time.now()

    grades = extras.get("grades", [])
    graded = [g for g in grades if "score" in g]
    pending = [g for g in grades if "score" not in g]
    weight_done = sum(g["weight"] for g in graded)
    overall = (
        round(sum(g["score"] / g["max"] * g["weight"] for g in graded) / weight_done * 100)
        if weight_done
        else None
    )

    scores_by_assignment = {g["assignment_id"]: g for g in graded if "assignment_id" in g}
    assignments = []
    for a in get_assignments(course_id=course_id):
        g = scores_by_assignment.get(a["id"])
        assignments.append({**a, "score": g["score"] if g else None, "max_score": g["max"] if g else None})

    quizzes = extras.get("quizzes", [])
    upcoming_quizzes = [q for q in quizzes if f"{q['date']} {q['time']}" > now.strftime("%Y-%m-%d %H:%M")]
    completed_quizzes = [q for q in quizzes if q not in upcoming_quizzes]

    sessions = extras.get("attendance", [])
    attended = sum(1 for s in sessions if s["status"] in ("Present", "Late"))
    attendance = {
        "attended": attended,
        "total": len(sessions),
        "rate": round(attended / len(sessions) * 100) if sessions else None,
        "recent": list(reversed(sessions))[:6],
    }

    agenda = [
        {"date": a["due_date"], "time": a["due_time"], "title": f"{a['title']} due", "detail": a["due_time"]}
        for a in assignments
        if not a["submitted"] and f"{a['due_date']} {a['due_time']}" >= now.strftime("%Y-%m-%d %H:%M")
    ]
    agenda += [
        {"date": q["date"], "time": q["time"], "title": q["title"],
         "detail": f"{q['time']} · {q['mode']}, {q['duration']} min"}
        for q in upcoming_quizzes
    ]
    agenda += [{**e, "detail": f"{e['time']} · {e['detail']}"} for e in extras.get("events", [])]
    agenda.sort(key=lambda e: (e["date"], e["time"]))

    return {
        "course": course,
        "materials": get_course_materials(course_id),
        "assignments": assignments,
        "quizzes": {"upcoming": upcoming_quizzes, "completed": completed_quizzes},
        "grades": {"overall": overall, "graded": graded, "pending": pending},
        "attendance": attendance,
        "agenda": agenda,
    }
