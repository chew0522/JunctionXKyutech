import json
import os
from pathlib import Path

import requests

WALK_TIMES_FILE = Path(__file__).resolve().parent.parent.parent / "data" / "walk_times.json"
ZONE_COORDS_FILE = Path(__file__).resolve().parent.parent.parent / "data" / "zone_coordinates.json"

DISTANCE_MATRIX_URL = "https://maps.googleapis.com/maps/api/distancematrix/json"

# In-memory only — fine for a single-session hackathon demo, avoids repeat API calls
# for the same zone pair within one run.
_cache: dict[frozenset, int] = {}


def get_walk_minutes(from_zone: str, to_zone: str) -> int:
    """Not an agent tool on its own — used by plan_coffee_run (connectors/planner.py) so
    the LLM never has to guess or compute this itself.

    Tries the real Google Maps Distance Matrix API first (walking mode) using
    data/zone_coordinates.json. Falls back to the static mock table in
    data/walk_times.json whenever a coordinate is missing, the API key isn't set, or
    the request fails for any reason — so a flaky connection never breaks the demo.
    """
    if from_zone == to_zone:
        return 0

    cache_key = frozenset((from_zone, to_zone))
    if cache_key in _cache:
        return _cache[cache_key]

    minutes = _real_walk_minutes(from_zone, to_zone)
    if minutes is None:
        minutes = _fallback_walk_minutes(from_zone, to_zone)

    _cache[cache_key] = minutes
    return minutes


def _real_walk_minutes(from_zone: str, to_zone: str) -> int | None:
    api_key = os.environ.get("GOOGLE_MAPS_API_KEY")
    if not api_key:
        return None

    coords = json.loads(ZONE_COORDS_FILE.read_text())
    origin = coords.get(from_zone)
    destination = coords.get(to_zone)
    if not origin or not destination:
        return None

    try:
        response = requests.get(
            DISTANCE_MATRIX_URL,
            params={
                "origins": f"{origin['lat']},{origin['lng']}",
                "destinations": f"{destination['lat']},{destination['lng']}",
                "mode": "walking",
                "key": api_key,
            },
            timeout=5,
        )
        response.raise_for_status()
        element = response.json()["rows"][0]["elements"][0]
        if element["status"] != "OK":
            return None
        return max(1, round(element["duration"]["value"] / 60))
    except Exception:
        return None


def _fallback_walk_minutes(from_zone: str, to_zone: str) -> int:
    table = json.loads(WALK_TIMES_FILE.read_text())
    for pair in table["pairs"]:
        if {pair["from"], pair["to"]} == {from_zone, to_zone}:
            return pair["minutes"]
    return table["default_minutes"]
