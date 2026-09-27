import hashlib
import json
import time
from pathlib import Path

import current_time
from connectors.academic import get_courses

DATA = Path(__file__).resolve().parent.parent.parent / "data"
QR_WINDOW_SECONDS = 30


def handle_scan(code: str) -> dict:
    """QR payloads are 'kind:value', e.g. 'attendance:CS301' or 'merit:EVT-MERIT-1'."""
    kind, _, value = code.strip().partition(":")
    if kind == "attendance":
        return _record_attendance(value)
    if kind == "merit":
        return _record_merit(value)
    return {"ok": False, "kind": "unknown", "title": "Unrecognised QR code", "detail": "This code isn't an attendance or merit code."}


def _record_attendance(course_code: str) -> dict:
    course = next((c for c in get_courses() if c["code"].lower() == course_code.lower()), None)
    if course is None:
        return {"ok": False, "kind": "attendance", "title": "Unknown class", "detail": f"No course matches '{course_code}'."}

    now = current_time.now()
    if not any(e["course_id"] == course["id"] and e["day"] == now.strftime("%a")
               for e in json.loads((DATA / "timetable.json").read_text())):
        return {"ok": False, "kind": "attendance", "title": "No class today",
                "detail": f"{course['code']} {course['name']} has no class on {now:%A}."}

    today = now.strftime("%Y-%m-%d")
    extras_file = DATA / "course_extras.json"
    extras = json.loads(extras_file.read_text())
    sessions = extras.setdefault(course["id"], {}).setdefault("attendance", [])
    if any(s["date"] == today for s in sessions):
        return {"ok": True, "kind": "attendance", "title": "Already recorded", "detail": f"{course['code']} {course['name']} is already marked for today."}
    sessions.append({"date": today, "status": "Present"})
    extras_file.write_text(json.dumps(extras, indent=2))

    log_file = DATA / "attendance.json"
    log = json.loads(log_file.read_text())
    log.append({"code": f"attendance:{course['code']}", "scanned_at": current_time.now().isoformat()})
    log_file.write_text(json.dumps(log, indent=2))
    return {"ok": True, "kind": "attendance", "title": "Attendance recorded", "detail": f"{course['code']} {course['name']}"}


def _record_merit(activity_id: str) -> dict:
    activity = next((m for m in json.loads((DATA / "merit.json").read_text()) if m["id"].lower() == activity_id.lower()), None)
    if activity is None:
        return {"ok": False, "kind": "merit", "title": "Unknown activity", "detail": f"No merit activity matches '{activity_id}'."}

    log_file = DATA / "merit_log.json"
    log = json.loads(log_file.read_text())
    if any(e["id"] == activity["id"] for e in log):
        return {"ok": True, "kind": "merit", "title": "Already claimed", "detail": f"{activity['title']} was already added to your merit."}
    log.append({"id": activity["id"], "title": activity["title"], "points": activity["points"], "scanned_at": current_time.now().isoformat()})
    log_file.write_text(json.dumps(log, indent=2))
    total = sum(e["points"] for e in log)
    return {"ok": True, "kind": "merit", "title": f"+{activity['points']} merit points", "detail": f"{activity['title']} · total {total} points"}


def get_qr(kind: str) -> dict | None:
    """Rotating payload for the Pay / ID tabs. Uses wall-clock time (not the demo clock)
    so the QR visibly refreshes; the token is derived from the matric number and window."""
    if kind not in ("id", "pay"):
        return None
    profile = json.loads((DATA / "profile.json").read_text())["personal"]
    now = time.time()
    window = int(now // QR_WINDOW_SECONDS)
    token = hashlib.sha256(f"{kind}|{profile['matric']}|{window}".encode()).hexdigest()[:12]
    return {
        "code": f"campus-{kind}:{profile['matric']}:{token}",
        "expires_in": QR_WINDOW_SECONDS - int(now % QR_WINDOW_SECONDS),
        "name": profile["name"],
        "matric": profile["matric"],
        "programme": profile["programme"],
        "faculty": profile["faculty"],
        "status": profile["status"],
    }
