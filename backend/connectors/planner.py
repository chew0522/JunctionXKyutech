from datetime import datetime

import current_time
from connectors.academic import get_next_class, get_next_class_overall
from connectors.cafe import get_cafe_crowd
from connectors.bus_sim import plan_trip, resolve_place
from connectors.campus_map import get_walk_minutes

# Demo-only: the student's current location, hardcoded like current_time.DEMO_START so
# this can be staged reliably. In a real app this would come from device location.
STUDENT_CURRENT_ZONE = "Library"

PLAN_COFFEE_SCHEMA = {
    "type": "function",
    "function": {
        "name": "plan_coffee_run",
        "description": (
            "Figure out whether the student has time to grab coffee before their next "
            "class, and recommend the best cafe, including how to get from the cafe to class (by "
            "campus bus when that is faster than walking). One call gives the whole plan, so use it "
            "for 'coffee then class', 'coffee then bus to class' and 'plan my afternoon' too. "
            "Leave course_id out to use their next class. Computes real walk "
            "times and cafe wait times — do not estimate this yourself, always call this tool."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "course_id": {"type": "string", "description": "e.g. course-ee150"},
            },
        },
    },
}


def plan_coffee_run(course_id: str | None = None) -> dict:
    next_class = get_next_class(course_id) if course_id else None
    course_label = None
    if course_id is None:
        overall = get_next_class_overall()
        if overall is not None:
            next_class = {"date": overall["date"], "time": overall["time"],
                          "location": overall["location"], "room": overall["room"]}
            course_label = f"{overall['code']} {overall['name']}"
    if next_class is None:
        return {"feasible": False, "message": "No upcoming class found for that course."}

    class_time = datetime.strptime(f"{next_class['date']} {next_class['time']}", "%Y-%m-%d %H:%M")
    minutes_until_class = int((class_time - current_time.now()).total_seconds() / 60)

    if minutes_until_class <= 0:
        return {"feasible": False, "message": "That class has already started or passed."}

    class_building = resolve_place(next_class["location"])
    options = []
    for cafe in get_cafe_crowd():
        walk_to_cafe = get_walk_minutes(STUDENT_CURRENT_ZONE, cafe["zone"])
        walk_to_class = get_walk_minutes(cafe["zone"], next_class["location"])

        leg = {"mode": "walk", "minutes": walk_to_class, "route": None, "route_id": None}
        cafe_building = resolve_place(cafe["zone"])
        if cafe_building and class_building and cafe_building["id"] != class_building["id"]:
            # The bus only helps if it beats walking once the wait for it is included.
            trip = plan_trip(cafe_building["id"], class_building["id"],
                             after_seconds=(walk_to_cafe + cafe["wait_minutes"]) * 60)
            if trip["options"]:
                bus = min(trip["options"], key=lambda o: o["total_minutes"])
                if bus["total_minutes"] < walk_to_class:
                    leg = {"mode": "bus", "minutes": bus["total_minutes"], "route": bus["route"],
                           "route_id": bus["route_id"], "from_id": cafe_building["id"], "to_id": class_building["id"],
                           "plate_number": bus["plate_number"]}

        total_minutes_needed = walk_to_cafe + cafe["wait_minutes"] + leg["minutes"]
        options.append(
            {
                "cafe": cafe["name"],
                "walk_to_cafe_minutes": walk_to_cafe,
                "wait_minutes": cafe["wait_minutes"],
                "to_class": leg,
                "total_minutes_needed": total_minutes_needed,
                "buffer_minutes": minutes_until_class - total_minutes_needed,
            }
        )

    options.sort(key=lambda o: o["total_minutes_needed"])
    best = options[0]
    leg = best["to_class"]
    class_text = course_label or "your next class"
    where = f"{next_class['location']} {next_class['room']}"
    getting_there = (f"take {leg['route']} to {class_building['name']} ({leg['minutes']} min incl. waiting)"
                     if leg["mode"] == "bus" else f"walk to class ({leg['minutes']} min)")
    plan = (f"walk to {best['cafe']} ({best['walk_to_cafe_minutes']} min), queue ({best['wait_minutes']} min), "
            f"then {getting_there}")
    if best["buffer_minutes"] >= 0:
        summary = (f"Yes, you have time. {class_text.capitalize() if not course_label else course_label} starts in "
                   f"{minutes_until_class} min at {where}. Best plan: {plan}. That's {best['total_minutes_needed']} min "
                   f"in total, leaving a {best['buffer_minutes']}-min buffer.")
    else:
        summary = (f"It's too tight for coffee: {class_text} starts in {minutes_until_class} min at {where}, and the "
                   f"quickest plan ({plan}) takes {best['total_minutes_needed']} min, so you'd be "
                   f"{-best['buffer_minutes']} min late.")
    others = [f"{o['cafe']} ({o['total_minutes_needed']} min)" for o in options[1:] if o["buffer_minutes"] >= 0]
    if others and best["buffer_minutes"] >= 0:
        summary += " Other options: " + ", ".join(others) + "."

    cards = []
    if leg["mode"] == "bus":
        cards.append({"kind": "bus", "id": leg["route_id"], "title": f"{leg['route']} · {leg['plate_number']}",
                      "subtitle": f"{best['cafe']} to {class_building['name']} · {leg['minutes']} min incl. waiting",
                      "from_id": leg["from_id"], "to_id": leg["to_id"], "available": True})

    return {
        "summary": summary,
        "cards": cards,
        "feasible": best["buffer_minutes"] >= 0,
        "minutes_until_class": minutes_until_class,
        "recommended_cafe": best["cafe"],
        "total_minutes_needed": best["total_minutes_needed"],
        "buffer_minutes": best["buffer_minutes"],
        "class_location": where,
        "all_options": options,
    }
