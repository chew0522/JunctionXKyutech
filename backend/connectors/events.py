import json
from pathlib import Path

DATA_FILE = Path(__file__).resolve().parent.parent.parent / "data" / "events.json"

TOOL_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_events",
        "description": "Get campus events, optionally filtered by date (YYYY-MM-DD).",
        "parameters": {
            "type": "object",
            "properties": {
                "date": {"type": "string", "description": "Filter to this date, e.g. 2026-09-26"}
            },
        },
    },
}


def get_events(date: str | None = None) -> list[dict]:
    events = json.loads(DATA_FILE.read_text())
    if date:
        events = [e for e in events if e["date"] == date]
    return events
