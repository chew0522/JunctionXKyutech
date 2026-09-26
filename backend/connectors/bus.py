from connectors.bus_sim import get_bus_location, plan_bus_trip

TOOL_SCHEMA = {
    "type": "function",
    "function": {
        "name": "get_bus_location",
        "description": "Get live location, next stop and ETA for campus shuttle bus routes.",
        "parameters": {
            "type": "object",
            "properties": {
                "route": {"type": "string", "description": "Optional route name to filter, e.g. 'Campus Loop A'"}
            },
        },
    },
}

PLAN_TRIP_SCHEMA = {
    "type": "function",
    "function": {
        "name": "plan_bus_trip",
        "description": (
            "Find which campus buses go from the student's current location (read "
            "automatically) to a destination, with wait time, ride time and arrival time. "
            "Call this whenever the student says they want to go somewhere or asks how to get "
            "somewhere on campus. Only pass origin if the student names a different starting place."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "destination": {"type": "string", "description": "Where they want to go, as they said it, e.g. 'main hall'"},
                "origin": {"type": "string", "description": "Optional starting place if not their current location"},
            },
            "required": ["destination"],
        },
    },
}
