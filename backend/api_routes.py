"""Plain REST endpoints over the connectors, for UI pages (Dashboard, Courses,
Bookings, drill-in pages) that need structured data directly — no LLM round-trip.
The chat agent (agent.py) is a separate consumer of the same connector functions."""

import hashlib
import json
from pathlib import Path

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

import bookings_log
import current_time
from connectors.academic import (
    get_assignments,
    get_course_materials,
    get_courses,
    submit_assignment,
)
from connectors.bus import get_bus_location
from connectors.bus_sim import get_campus_map, get_my_location, plan_trip, schedule_trip
from connectors.cafe import get_cafe_crowd
from connectors.course_detail import get_course_detail
from connectors.clinic import book_clinic_appointment, get_clinic_slots
from connectors.events import get_events
from connectors.facilities import book_facility, get_facilities
from connectors.scan import get_qr, handle_scan
from connectors.rooms import book_study_room, get_study_rooms
from connectors.student_admin import (
    get_finance,
    get_form_submissions,
    get_forms,
    get_registration,
    submit_form,
)
from connectors.todo import todo_list

router = APIRouter(prefix="/api")

_DATA = Path(__file__).resolve().parent.parent / "data"


@router.get("/slots")
def api_slots(resource_id: str, name: str, date: str):
    """Mock availability grid, 08:00-22:00 every 30 min. Stable per resource+date (hash),
    plus past times today and anything already in the student's own bookings."""
    now = current_time.now()
    taken = {(b["title"], b["date"], b["time"]) for b in bookings_log.get_bookings()}
    slots = []
    for minutes in range(8 * 60, 22 * 60 + 1, 30):
        t = f"{minutes // 60:02d}:{minutes % 60:02d}"
        busy = int(hashlib.md5(f"{resource_id}|{date}|{t}".encode()).hexdigest(), 16) % 10 < 3
        past = date == now.strftime("%Y-%m-%d") and t <= now.strftime("%H:%M")
        slots.append({"time": t, "available": not (busy or past or (name, date, t) in taken)})
    return slots


@router.get("/profile")
def api_profile():
    return json.loads((_DATA / "profile.json").read_text())


class FeedbackBody(BaseModel):
    category: str
    message: str


@router.post("/feedback")
def api_feedback(body: FeedbackBody):
    file = _DATA / "feedback.json"
    log = json.loads(file.read_text())
    log.append({**body.model_dump(), "submitted_at": current_time.now().isoformat()})
    file.write_text(json.dumps(log, indent=2))
    return {"ok": True}


@router.get("/registration")
def api_registration():
    return get_registration()


@router.get("/finance")
def api_finance():
    return get_finance()


@router.get("/forms")
def api_forms():
    return get_forms()


@router.get("/form-submissions")
def api_form_submissions():
    return get_form_submissions()


class FormSubmitBody(BaseModel):
    values: dict


@router.post("/forms/{form_id}/submit")
def api_submit_form(form_id: str, body: FormSubmitBody):
    entry = submit_form(form_id, body.values)
    if entry is None:
        raise HTTPException(status_code=404, detail="Unknown form")
    return entry


@router.get("/timetable")
def api_timetable():
    courses = {c["id"]: c for c in get_courses()}
    entries = json.loads((_DATA / "timetable.json").read_text())
    return [{**e, "code": courses[e["course_id"]]["code"], "name": courses[e["course_id"]]["name"]} for e in entries]


class ScanBody(BaseModel):
    code: str


@router.post("/scan")
def api_scan(body: ScanBody):
    return handle_scan(body.code)


@router.get("/qr/{kind}")
def api_qr(kind: str):
    qr = get_qr(kind)
    if qr is None:
        raise HTTPException(status_code=404, detail="Unknown QR kind")
    return qr


@router.get("/now")
def api_now():
    """Single source of truth for 'today' so the frontend never hardcodes a copy of
    the demo clock (see CLAUDE.md's "Shared demo clock" note on current_time.py)."""
    return {"now": current_time.now().isoformat()}


@router.get("/events")
def api_events(date: str | None = None):
    return get_events(date=date)


@router.get("/rooms")
def api_rooms():
    return get_study_rooms()


class BookRoomRequest(BaseModel):
    room_id: str
    date: str | None = None
    time: str | None = None


@router.post("/rooms/book")
def api_book_room(req: BookRoomRequest):
    return book_study_room(req.room_id, req.date, req.time)


@router.get("/campus-map")
def api_campus_map():
    return get_campus_map()


@router.get("/my-location")
def api_my_location():
    return get_my_location()


@router.get("/trip-plan")
def api_trip_plan(from_id: str, to_id: str):
    return plan_trip(from_id, to_id)


class TripScheduleBody(BaseModel):
    route_id: str
    from_id: str
    to_id: str


@router.post("/trip-schedule")
def api_trip_schedule(body: TripScheduleBody):
    return schedule_trip(body.route_id, body.from_id, body.to_id)


@router.get("/bus")
def api_bus():
    return get_bus_location()


@router.get("/cafes")
def api_cafes():
    return get_cafe_crowd()


@router.get("/clinic-slots")
def api_clinic_slots(date: str | None = None):
    return get_clinic_slots(date=date)


class BookSlotRequest(BaseModel):
    slot_id: str


@router.post("/clinic-slots/book")
def api_book_slot(req: BookSlotRequest):
    return book_clinic_appointment(req.slot_id)


@router.get("/courses")
def api_courses():
    return get_courses()


@router.get("/courses/{course_id}/detail")
def api_course_detail(course_id: str):
    detail = get_course_detail(course_id)
    if detail is None:
        raise HTTPException(status_code=404, detail="Unknown course")
    return detail


@router.get("/materials")
def api_materials(course_id: str):
    return get_course_materials(course_id)


@router.get("/assignments")
def api_assignments(course_id: str | None = None, pending_only: bool = False):
    return get_assignments(course_id=course_id, pending_only=pending_only)


class SubmitAssignmentRequest(BaseModel):
    assignment_id: str


@router.post("/assignments/submit")
def api_submit_assignment(req: SubmitAssignmentRequest):
    """Native UI action only — see the docstring on submit_assignment in
    connectors/academic.py for why this is deliberately not an agent tool."""
    return submit_assignment(req.assignment_id)


@router.get("/todos")
def api_todos():
    return todo_list()


@router.get("/facilities")
def api_facilities(category: str | None = None):
    return get_facilities(category=category)


class BookFacilityRequest(BaseModel):
    facility_id: str
    date: str | None = None
    time: str | None = None


@router.post("/facilities/book")
def api_book_facility(req: BookFacilityRequest):
    return book_facility(req.facility_id, req.date, req.time)


@router.get("/my-bookings")
def api_my_bookings():
    """Confirmed bookings the student actually made — see bookings_log.py's docstring
    for why this isn't just 'available: false' rooms/slots."""
    return bookings_log.get_bookings()
