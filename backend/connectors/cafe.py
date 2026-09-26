import json
from pathlib import Path

DATA_FILE = Path(__file__).resolve().parent.parent.parent / "data" / "cafes.json"

TOOL_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_cafe_crowd",
        "description": "Get current crowd level and estimated wait time for campus cafes.",
        "parameters": {
            "type": "object",
            "properties": {
                "name": {"type": "string", "description": "Optional cafe name to filter, e.g. 'Main Library Cafe'"}
            },
        },
    },
}


def get_cafe_crowd(name: str | None = None) -> list[dict]:
    cafes = json.loads(DATA_FILE.read_text())
    if name:
        cafes = [c for c in cafes if name.lower() in c["name"].lower()]
    return cafes
