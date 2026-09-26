import json
import os

from openai import OpenAI

from connectors.academic import (
    GET_ASSIGNMENTS_SCHEMA,
    GET_COURSES_SCHEMA,
    GET_MATERIALS_SCHEMA,
    SUBMIT_ASSIGNMENT_SCHEMA,
    get_assignments,
    get_course_materials,
    get_courses,
    submit_assignment,
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

SYSTEM_PROMPT = (
    "You are Campus Concierge, a helpful assistant for university students. "
    "You have tools to check events, study rooms, bus locations, cafe crowd levels, "
    "clinic appointment slots, courses, course materials, assignments, and a to-do list. "
    "The to-do list is sourced entirely from the student's pending lecturer assignments — "
    "it is not a place for arbitrary personal notes. "
    "Always use a tool to get real data before answering factual questions — never invent "
    "event details, room availability, bus times, appointment slots, or assignment details. "
    "Keep answers short and conversational."
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
    SUBMIT_ASSIGNMENT_SCHEMA,
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
    "submit_assignment": submit_assignment,
}


def run_agent(user_message: str, history: list[dict] | None = None) -> dict:
    """Runs one turn of the agent loop and returns the final reply plus updated history."""
    messages = history[:] if history else [{"role": "system", "content": SYSTEM_PROMPT}]
    messages.append({"role": "user", "content": user_message})

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
            return {"reply": choice.message.content, "history": messages}

        for tool_call in choice.message.tool_calls:
            name = tool_call.function.name
            args = json.loads(tool_call.function.arguments or "{}")
            result = TOOL_FUNCTIONS[name](**args)
            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": json.dumps(result),
                }
            )
