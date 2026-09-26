import json
from pathlib import Path

DATA_FILE = Path(__file__).resolve().parent.parent.parent / "data" / "bus.json"

TOOL_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_bus_location",
        "description": "Get current location and ETA for campus shuttle bus routes.",
        "parameters": {
            "type": "object",
            "properties": {
                "route": {"type": "string", "description": "Optional route name to filter, e.g. 'Campus Loop A'"}
            },
        },
    },
}


def get_bus_location(route: str | None = None) -> list[dict]:
    buses = json.loads(DATA_FILE.read_text())
    if route:
        buses = [b for b in buses if b["route"] == route]
    return buses
