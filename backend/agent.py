import json
import os

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
from connectors.bus import TOOL_SCHEMA as BUS_SCHEMA, get_bus_location
from connectors.cafe import TOOL_SCHEMA as CAFE_SCHEMA, get_cafe_crowd
from connectors.clinic import (
    BOOK_APPOINTMENT_SCHEMA,
    GET_SLOTS_SCHEMA,
    book_clinic_appointment,
    get_clinic_slots,
)
from connectors.events import TOOL_SCHEMA as EVENTS_SCHEMA, get_events

# get_next_class (used internally by plan_coffee_run) is not registered as its own agent
# tool — the model should always go through the planner, never raw schedule data.
from connectors.planner import PLAN_COFFEE_SCHEMA, plan_coffee_run
from connectors.rooms import (
    BOOK_ROOM_SCHEMA,
    GET_ROOMS_SCHEMA,
    book_study_room,
    get_study_rooms,
)
from connectors.todo import LIST_TODOS_SCHEMA, todo_list

client = OpenAI(
    api_key=os.environ["DEEPSEEK_API_KEY"],
    base_url="https://api.deepseek.com",
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
        "always call plan_coffee_run for that. Keep answers short and conversational. "
        "Never use emoji — the app's design system forbids them; use plain text only. "
        "Whenever you present a short list of pickable options (rooms, routes, slots, "
        "cafes, a yes/no confirmation), call offer_choices with those options so the "
        "student can tap instead of typing. Calling offer_choices never replaces your "
        "written reply — your final message must still contain real sentences "
        "describing the options (e.g. which rooms are free and where), never empty "
        "or blank text, even when offer_choices covers the same options."
    )

TOOLS = [
    EVENTS_SCHEMA,
    GET_ROOMS_SCHEMA,
    BOOK_ROOM_SCHEMA,
    BUS_SCHEMA,
    LIST_TODOS_SCHEMA,
    CAFE_SCHEMA,
    GET_SLOTS_SCHEMA,
    BOOK_APPOINTMENT_SCHEMA,
    GET_COURSES_SCHEMA,
    GET_MATERIALS_SCHEMA,
    GET_ASSIGNMENTS_SCHEMA,
    PLAN_COFFEE_SCHEMA,
    OFFER_CHOICES_SCHEMA,
]

# Maps tool name -> the actual Python function that implements it
TOOL_FUNCTIONS = {
    "get_events": get_events,
    "get_study_rooms": get_study_rooms,
    "book_study_room": book_study_room,
    "get_bus_location": get_bus_location,
    "todo_list": todo_list,
    "get_cafe_crowd": get_cafe_crowd,
    "get_clinic_slots": get_clinic_slots,
    "book_clinic_appointment": book_clinic_appointment,
    "get_courses": get_courses,
    "get_course_materials": get_course_materials,
    "get_assignments": get_assignments,
    "plan_coffee_run": plan_coffee_run,
    "offer_choices": offer_choices,
}


def run_agent(user_message: str, history: list[dict] | None = None) -> dict:
    """Runs one turn of the agent loop and returns the final reply plus updated history.
    'choices' is populated whenever offer_choices was called this turn, so the UI can
    render tappable options instead of the reply text alone."""
    messages = history[:] if history else [{"role": "system", "content": ""}]
    messages[0] = {"role": "system", "content": _system_prompt()}
    messages.append({"role": "user", "content": user_message})
    choices: list[str] | None = None

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
            return {"reply": choice.message.content, "history": messages, "choices": choices}

        for tool_call in choice.message.tool_calls:
            name = tool_call.function.name
            args = json.loads(tool_call.function.arguments or "{}")
            result = TOOL_FUNCTIONS[name](**args)
            if name == "offer_choices":
                choices = args["choices"]
            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": json.dumps(result),
                }
            )
