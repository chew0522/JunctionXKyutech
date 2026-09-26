"""Plain REST endpoints over the connectors, for UI pages (Dashboard, Courses,
Bookings, drill-in pages) that need structured data directly — no LLM round-trip.
The chat agent (agent.py) is a separate consumer of the same connector functions."""

from fastapi import APIRouter
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
from connectors.cafe import get_cafe_crowd
from connectors.clinic import book_clinic_appointment, get_clinic_slots
from connectors.events import get_events
from connectors.facilities import book_facility, get_facilities
from connectors.rooms import book_study_room, get_study_rooms
from connectors.todo import todo_list

router = APIRouter(prefix="/api")


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


@router.post("/rooms/book")
def api_book_room(req: BookRoomRequest):
    return book_study_room(req.room_id)


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


@router.post("/facilities/book")
def api_book_facility(req: BookFacilityRequest):
    return book_facility(req.facility_id)


@router.get("/my-bookings")
def api_my_bookings():
    """Confirmed bookings the student actually made — see bookings_log.py's docstring
    for why this isn't just 'available: false' rooms/slots."""
    return bookings_log.get_bookings()
