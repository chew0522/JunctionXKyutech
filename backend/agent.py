import inspect
import json
import os
import re

from dotenv import load_dotenv
from openai import OpenAI

import current_time

load_dotenv()

from connectors.academic import (
    GET_ASSIGNMENTS_SCHEMA,
    GET_COURSES_SCHEMA,
    GET_MATERIALS_SCHEMA,
    get_assignments,
    get_course_materials,
    get_courses,
)
from connectors.bus import PLAN_TRIP_SCHEMA, TOOL_SCHEMA as BUS_SCHEMA, get_bus_location, plan_bus_trip
from connectors.bus_sim import trip_cards
from connectors.cafe import TOOL_SCHEMA as CAFE_SCHEMA, get_cafe_crowd
from connectors.clinic import GET_SLOTS_SCHEMA, get_clinic_slots
from connectors.booking_proposals import PROPOSE_BOOKING_SCHEMA, propose_booking
from connectors.day_planner import (
    CLASH_FREE_SCHEMA,
    PLAN_DAY_SCHEMA,
    PLAN_TO_CLASS_SCHEMA,
    STUDY_SPOT_SCHEMA,
    find_clash_free,
    find_study_spot,
    plan_getting_to_class,
    plan_my_day,
)
from connectors.events import TOOL_SCHEMA as EVENTS_SCHEMA, get_events
from connectors.facilities import GET_FACILITIES_SCHEMA, get_facilities

# get_next_class (used internally by plan_coffee_run) is not registered as its own agent
# tool — the model should always go through the planner, never raw schedule data.
from connectors.planner import PLAN_COFFEE_SCHEMA, plan_coffee_run
from connectors.rooms import GET_ROOMS_SCHEMA, get_study_rooms
from connectors.my_bookings import GET_MY_BOOKINGS_SCHEMA, get_my_bookings
from connectors.schedule import (
    CHECK_CLASS_SCHEMA,
    GET_CREDITS_SCHEMA,
    GET_SCHEDULE_SCHEMA,
    check_class_at,
    get_credit_hours,
    get_my_schedule,
)
from connectors.todo import LIST_TODOS_SCHEMA, todo_list

client = OpenAI(
    api_key=os.environ["DEEPSEEK_API_KEY"],
    base_url="https://api.deepseek.com",
    timeout=25,
    max_retries=3,
)

MODEL = "deepseek-chat"

# Not a connector — no data file, no side effect. This tool exists purely so the UI
# can render tappable chips for a short list of options instead of forcing the student
# to type one out. The model calls it alongside its normal text reply; run_agent below
# captures the choices and returns them separately from the reply text.
OFFER_CHOICES_SCHEMA = {
    "type": "function",
    "function": {
        "name": "offer_choices",
        "description": (
            "Call this whenever your answer presents a short list of distinct, "
            "pickable options the student would otherwise have to type out — e.g. "
            "which room to book, which bus route, which clinic slot, which cafe, or "
            "a yes/no confirmation. Pass each option as a short label written exactly "
            "as the student would type it themselves (e.g. 'Book Study Room 202', "
            "'Yes', 'No'). Always also give your normal text answer in the same turn — "
            "this tool only adds tappable shortcuts, it doesn't replace the reply."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "choices": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "2-4 short button labels, each a valid next message on its own",
                }
            },
            "required": ["choices"],
        },
    },
}


def offer_choices(choices: list[str]) -> dict:
    return {"acknowledged": True, "choices": choices}


OFFER_BOOKINGS_SCHEMA = {
    "type": "function",
    "function": {
        "name": "offer_bookings",
        "description": (
            "Show bookable options as detailed cards in the chat. This is the ONLY way to "
            "book anything: the student taps a card and picks the date and time in the app. "
            "Call it whenever the student wants to book or asks what is available to book: "
            "kind 'room' (study rooms), 'facility' (halls, courts, gym) or 'clinic' "
            "(clinic appointments). Optionally pass ids of the specific rooms/facilities "
            "to show; omit ids to show everything (every room and facility can be booked for a later time). Also write a short "
            "text reply — the cards only add the pickable options."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "kind": {"type": "string", "enum": ["room", "facility", "clinic"]},
                "ids": {"type": "array", "items": {"type": "string"}},
            },
            "required": ["kind"],
        },
    },
}


def offer_bookings(kind: str, ids: list[str] | None = None) -> list[dict]:
    cards: list[dict] = []
    if kind == "room":
        for r in get_study_rooms():
            if ids and r["id"] not in ids:
                continue
            cards.append({
                "kind": "room", "id": r["id"], "title": r["name"],
                "subtitle": f"{r['building']}, Floor {r['floor']} · {r['capacity']} seats"
                            + (" · whiteboard" if r["has_whiteboard"] else "")
                            + (" · free now" if r["available"] else " · in use now"),
                "available": True,
            })
    elif kind == "facility":
        for f in get_facilities():
            if ids and f["id"] not in ids:
                continue
            cards.append({
                "kind": "facility", "id": f["id"], "title": f["name"],
                "subtitle": f"{f['location']} · Capacity {f['capacity']}" + (" · free now" if f["available"] else " · in use now"),
                "available": True,
            })
    elif kind == "clinic":
        seen = {}
        for s in get_clinic_slots():
            if s["available"]:
                seen.setdefault((s["doctor"], s["type"]), 0)
                seen[(s["doctor"], s["type"])] += 1
        for (doctor, type_), n in seen.items():
            cards.append({
                "kind": "clinic", "id": f"{doctor}|{type_}", "title": doctor,
                "subtitle": f"{type_} · {n} open slot{'s' if n != 1 else ''}",
                "available": True,
            })
    return cards


def _system_prompt() -> str:
    # Rebuilt per call (not a module-level constant) so "today"/"tomorrow" stay correct
    # relative to current_time.now() — without this, the model has to guess the date
    # itself and gets relative-date reasoning wrong (e.g. calling something due today
    # "due tomorrow").
    today = current_time.now().strftime("%A, %Y-%m-%d")
    return (
        "You are Campus Concierge, a helpful assistant for university students. "
        f"Today's date is {today}. Always compute 'today'/'tomorrow'/'this week' "
        "from that date rather than guessing. "
        "You have tools to check events, study rooms, bus locations, cafe crowd levels, "
        "clinic appointment slots, courses, course materials, assignments, a to-do list, "
        "and a coffee-run planner that checks if there's time to grab coffee before a class. "
        "The to-do list is sourced entirely from the student's pending lecturer assignments — "
        "it is not a place for arbitrary personal notes. "
        "You cannot submit assignments — that stays in the school's real submission portal, "
        "not through chat. If asked, tell the student to submit it there directly. "
        "Always use a tool to get real data before answering factual questions — never invent "
        "event details, room availability, bus times, appointment slots, or assignment details. "
        "Never estimate walk times or whether there's enough time for something yourself — "
        "always call plan_coffee_run for that, without a course_id unless the student names "
        "a class (it uses their next class automatically). It also plans how to get from the "
        "cafe to class, so use it alone for 'coffee then bus to class' style questions and "
        "start your reply with its 'summary'. For 'what class do I have next' or "
        "'where is my class', call get_my_schedule. For 'do I have a class then / on <day> / at <time>' "
        "(including the time of a booking you just proposed) call check_class_at with that date and time.  For a general 'when is the next bus', call "
        "get_bus_location and give the soonest arrivals instead of asking where they are going. "
        "Ready-made planners (each returns a 'summary' — start your reply with it word for word): "
        "plan_getting_to_class for 'how do I get to class / will I be on time / when should I leave'; "
        "plan_my_day for 'what should I do now / plan my day / am I free'; find_clash_free for clinic "
        "slots or events that do not clash with their classes; find_study_spot for 'where can I study / "
        "a room for N people near me'. "
        "If the student says where they are ('I'm at the gym'), pass it as origin to plan_bus_trip. "
        "Keep answers short and conversational. Buttons and cards appear BELOW your message, never above it. "
        "There is no way to cancel or change a booking yet — say so plainly if asked. "
        "For 'am I free this afternoon / what's my day like' call plan_my_day. For 'what did I book / my appointments' call get_my_bookings. For credits or credit hours call get_credit_hours (never add numbers yourself). "
        "The student cannot see tool results, so your written reply must itself contain the "
        "actual facts (names, times, numbers) — never say 'your list is above' or 'see the "
        "cards'. "
        "Never use emoji — the app's design system forbids them; use plain text only. "
        "When the student says they want to go somewhere or asks how to get somewhere on "
        "campus, call plan_bus_trip (it reads their current location itself). Start your reply "
        "with the tool's 'summary' sentence(s) word for word — it already contains where they "
        "are, the bus and the timings — then add one short line saying they can tap a card "
        "below to track that bus live. Never restate or recompute the numbers yourself. Do not also call offer_choices for this. "
        "You never book anything yourself. When the student asks to book, reserve or get a study room, "
        "a sports facility or hall, or a clinic appointment (even vaguely, like 'basketball Tuesday' or "
        "'just book one for me'), call propose_booking with what they said. If they give no time of day it returns "
        "morning/afternoon/evening options for them to tap; after they pick one it proposes the slot "
        "and the student confirms with one tap. Start your reply with its 'summary'. Do not ask them for a "
        "date or time first — propose one. Use offer_bookings only when they want to browse what exists "
        "('what facilities can I book?'). Do not call offer_choices for either (the tool supplies its own buttons). "
        "Only when you ask the student to pick between options (which cafe, which route, "
        "a yes/no confirmation) call offer_choices — never for a plain factual answer or just "
        "to suggest follow-up topics — with those options so the "
        "student can tap instead of typing. Calling offer_choices never replaces your "
        "written reply — your final message must still contain real sentences "
        "describing the options (e.g. which rooms are free and where), never empty "
        "or blank text, even when offer_choices covers the same options."
    )

TOOLS = [
    EVENTS_SCHEMA,
    GET_ROOMS_SCHEMA,
    GET_FACILITIES_SCHEMA,
    BUS_SCHEMA,
    PLAN_TRIP_SCHEMA,
    LIST_TODOS_SCHEMA,
    CAFE_SCHEMA,
    GET_SLOTS_SCHEMA,
    GET_COURSES_SCHEMA,
    GET_MATERIALS_SCHEMA,
    GET_ASSIGNMENTS_SCHEMA,
    PLAN_COFFEE_SCHEMA,
    GET_SCHEDULE_SCHEMA,
    CHECK_CLASS_SCHEMA,
    GET_MY_BOOKINGS_SCHEMA,
    GET_CREDITS_SCHEMA,
    PLAN_TO_CLASS_SCHEMA,
    PLAN_DAY_SCHEMA,
    CLASH_FREE_SCHEMA,
    STUDY_SPOT_SCHEMA,
    PROPOSE_BOOKING_SCHEMA,
    OFFER_CHOICES_SCHEMA,
    OFFER_BOOKINGS_SCHEMA,
]

# Maps tool name -> the actual Python function that implements it
TOOL_FUNCTIONS = {
    "get_events": get_events,
    "get_study_rooms": get_study_rooms,
    "get_facilities": get_facilities,
    "get_bus_location": get_bus_location,
    "plan_bus_trip": plan_bus_trip,
    "todo_list": todo_list,
    "get_cafe_crowd": get_cafe_crowd,
    "get_clinic_slots": get_clinic_slots,
    "get_courses": get_courses,
    "get_course_materials": get_course_materials,
    "get_assignments": get_assignments,
    "plan_coffee_run": plan_coffee_run,
    "get_my_schedule": get_my_schedule,
    "check_class_at": check_class_at,
    "get_my_bookings": get_my_bookings,
    "get_credit_hours": get_credit_hours,
    "plan_getting_to_class": plan_getting_to_class,
    "plan_my_day": plan_my_day,
    "find_clash_free": find_clash_free,
    "find_study_spot": find_study_spot,
    "propose_booking": propose_booking,
    "offer_choices": offer_choices,
    "offer_bookings": offer_bookings,
}


def _card_hint(cards: list[dict]) -> str:
    if all(c["kind"] == "bus" for c in cards):
        return "\n\nTap a card below to track it live."
    if all(c["kind"] == "proposal" for c in cards):
        return ""
    return "\n\nTap a card below to book it and pick your date and time."


SUMMARY_IS_REPLY = {"plan_coffee_run", "plan_getting_to_class", "find_clash_free", "find_study_spot", "propose_booking", "check_class_at"}

PLANNER_TOOLS = {"plan_coffee_run", "plan_getting_to_class", "plan_my_day", "find_clash_free", "find_study_spot", "propose_booking", "check_class_at"}


def _call_tool(name: str, args: dict):
    """Run a tool defensively: the model sometimes invents or misnames an argument, and one bad
    call must not crash the whole conversation."""
    fn = TOOL_FUNCTIONS.get(name)
    if fn is None:
        return {"error": f"Unknown tool '{name}'."}
    accepted = inspect.signature(fn).parameters
    try:
        return fn(**{k: v for k, v in args.items() if k in accepted})
    except Exception as e:
        return {"error": f"{name} failed: {e}"}


def run_agent(user_message: str, history: list[dict] | None = None) -> dict:
    """Runs one turn of the agent loop and returns the final reply plus updated history.
    'choices' is populated whenever offer_choices was called this turn, so the UI can
    render tappable options instead of the reply text alone."""
    messages = history[:] if history else [{"role": "system", "content": ""}]
    messages[0] = {"role": "system", "content": _system_prompt()}
    messages.append({"role": "user", "content": user_message})
    choices: list[str] | None = None
    cards: list[dict] | None = None
    trip_summary: str | None = None
    fixed_choices: list[str] | None = None
    planner_cards: list[dict] | None = None
    browse_fallback: str | None = None
    last_planner: str | None = None

    # Loop: the model may request tool calls multiple times before giving a final answer
    while True:
        response = client.chat.completions.create(
            model=MODEL,
            messages=messages,
            tools=TOOLS,
        )
        choice = response.choices[0]
        messages.append(choice.message.model_dump(exclude_none=True))

        if choice.finish_reason != "tool_calls":
            reply = choice.message.content
            if choices and not trip_summary and len(reply or "") < 120 and any(m.get("role") == "tool" for m in messages):
                # Choices are only shortcuts; a reply that just points at them hides the actual answer.
                messages.append({"role": "user", "content": (
                    "Rewrite your last reply so it states the actual results from the tools in full "
                    "sentences (names, times, numbers). Do not refer to buttons, cards or 'above'.")})
                retry = client.chat.completions.create(model=MODEL, messages=messages)
                reply = retry.choices[0].message.content or reply
                messages.pop()
            if browse_fallback and re.search(r"\babove\b", (reply or "").lower()):
                reply = browse_fallback
            if trip_summary and last_planner in SUMMARY_IS_REPLY:
                # These summaries already answer the whole question; the model's extras
                # ("want me to show tappable choices?") only promise things the app doesn't do.
                reply = trip_summary + (_card_hint(cards) if cards else "")
            elif trip_summary and not cards and re.search(r"\bcards?\b", (reply or "").lower()):
                reply = trip_summary
            if trip_summary and trip_summary not in (reply or ""):
                # The model dropped the deterministic sentence; use it rather than trust a paraphrase.
                reply = trip_summary + (_card_hint(cards) if cards else "")
            return {"reply": reply, "history": messages, "choices": choices, "cards": cards}

        for tool_call in choice.message.tool_calls:
            name = tool_call.function.name
            args = json.loads(tool_call.function.arguments or "{}")
            result = _call_tool(name, args)
            if name == "offer_choices":
                choices = fixed_choices or args["choices"]
            if name == "plan_bus_trip":
                cards = trip_cards(result) or cards
                trip_summary = result.get("summary") or result.get("error")
            if name in PLANNER_TOOLS:
                last_planner = name
                planner_cards = result.pop("cards", None) or planner_cards
                cards = planner_cards or cards
                fixed_choices = result.pop("choices", None) or fixed_choices
                choices = fixed_choices or choices
                trip_summary = result.get("summary") or result.get("message")
            if name == "offer_bookings":
                cards = planner_cards or result
                if result:
                    browse_fallback = ("Here are the options: " + ", ".join(c["title"] for c in result)
                                       + ". Tap one below to book it and pick your date and time.")
                result = {"acknowledged": True, "cards_shown": len(cards)}
            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": json.dumps(result),
                }
            )
