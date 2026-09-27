import json
import math
import time
from pathlib import Path

import bookings_log
import current_time

MAP_FILE = Path(__file__).resolve().parent.parent.parent / "data" / "campus_map.json"


def get_campus_map() -> dict:
    data = json.loads(MAP_FILE.read_text())
    buildings = {b["id"]: b for b in data["buildings"]}
    for route in data["routes"]:
        route["path"] = [[buildings[s]["lat"], buildings[s]["lng"]] for s in route["stops"] + route["stops"][:1]]
    return data


def _meters(a: tuple[float, float], b: tuple[float, float]) -> float:
    dlat = (b[0] - a[0]) * 111_320
    dlng = (b[1] - a[1]) * 111_320 * math.cos(math.radians(a[0]))
    return math.hypot(dlat, dlng)


def _geometry(route: dict, buildings: dict) -> dict:
    """Closed loop through the stops in order; cum[i] is the distance along the loop at stop i."""
    stops = route["stops"]
    points = [(buildings[s]["lat"], buildings[s]["lng"]) for s in stops]
    cum = [0.0]
    for i in range(1, len(points)):
        cum.append(cum[-1] + _meters(points[i - 1], points[i]))
    total = cum[-1] + _meters(points[-1], points[0])
    return {"points": points, "cum": cum, "total": total}


def _position(geo: dict, s: float) -> dict:
    n = len(geo["points"])
    for i in range(n):
        start = geo["cum"][i]
        end = geo["cum"][i + 1] if i + 1 < n else geo["total"]
        if s <= end:
            a = geo["points"][i]
            b = geo["points"][(i + 1) % n]
            frac = (s - start) / (end - start) if end > start else 0
            return {
                "lat": a[0] + (b[0] - a[0]) * frac,
                "lng": a[1] + (b[1] - a[1]) * frac,
                "prev": i,
                "next": (i + 1) % n,
                "to_next_m": end - s,
                "from_prev_m": s - start,
            }
    return {"lat": geo["points"][0][0], "lng": geo["points"][0][1], "prev": 0, "next": 1 % n, "to_next_m": 0, "from_prev_m": 0}


def _bus_s(route: dict, geo: dict, now_ts: float) -> float:
    return (route["offset_m"] + now_ts * route["speed_mps"]) % geo["total"]


def get_bus_location(route: str | None = None) -> list[dict]:
    """Simulated live positions. Deterministic in wall-clock time, so every client sees
    the same buses moving along their loops without any stored state."""
    data = get_campus_map()
    buildings = {b["id"]: b for b in data["buildings"]}
    now_ts = time.time()
    buses = []
    for r in data["routes"]:
        if route and r["name"] != route:
            continue
        geo = _geometry(r, buildings)
        s = _bus_s(r, geo, now_ts)
        pos = _position(geo, s)
        prev_stop = buildings[r["stops"][pos["prev"]]]["name"]
        next_stop = buildings[r["stops"][pos["next"]]]["name"]
        eta = max(1, math.ceil(pos["to_next_m"] / r["speed_mps"] / 60))
        heading = math.degrees(math.atan2(
            (geo["points"][pos["next"]][1] - geo["points"][pos["prev"]][1]) * math.cos(math.radians(pos["lat"])),
            geo["points"][pos["next"]][0] - geo["points"][pos["prev"]][0]))
        buses.append({
            "id": r["id"],
            "route": r["name"],
            "plate_number": r["plate"],
            "lat": pos["lat"],
            "lng": pos["lng"],
            "heading": heading,
            "current_stop": prev_stop,
            "next_stop": next_stop,
            "eta_minutes": eta,
            "capacity_status": r["capacity"],
            "last_updated": current_time.now().isoformat(),
            "stops": [buildings[s]["name"] for s in r["stops"]],
        })
    return buses


def plan_trip(from_id: str, to_id: str, after_seconds: float = 0) -> dict:
    data = get_campus_map()
    buildings = {b["id"]: b for b in data["buildings"]}
    if from_id not in buildings or to_id not in buildings:
        return {"error": "Unknown location.", "options": []}
    if from_id == to_id:
        return {"error": "Pick two different places.", "options": []}

    from datetime import timedelta

    now_ts = time.time() + after_seconds
    now = current_time.now() + timedelta(seconds=after_seconds)
    options = []
    for r in data["routes"]:
        if from_id not in r["stops"] or to_id not in r["stops"]:
            continue
        geo = _geometry(r, buildings)
        s_bus = _bus_s(r, geo, now_ts)
        s_from = geo["cum"][r["stops"].index(from_id)]
        s_to = geo["cum"][r["stops"].index(to_id)]
        wait_m = (s_from - s_bus) % geo["total"]
        ride_m = (s_to - s_from) % geo["total"]
        wait_min = math.ceil(wait_m / r["speed_mps"] / 60)
        ride_min = max(1, math.ceil(ride_m / r["speed_mps"] / 60))
        loop_min = math.ceil(geo["total"] / r["speed_mps"] / 60)
        options.append({
            "route_id": r["id"],
            "route": r["name"],
            "plate_number": r["plate"],
            "capacity_status": r["capacity"],
            "wait_minutes": wait_min,
            "ride_minutes": ride_min,
            "total_minutes": wait_min + ride_min,
            "depart_at": _clock(now, wait_min),
            "arrive_at": _clock(now, wait_min + ride_min),
            "next_departure_after": wait_min + loop_min,
            "next_depart_at": _clock(now, wait_min + loop_min),
        })
    options.sort(key=lambda o: o["total_minutes"])
    return {
        "error": None if options else "No direct bus between these two places.",
        "options": options,
    }


def _clock(now, minutes: int) -> str:
    from datetime import timedelta
    return (now + timedelta(minutes=minutes)).strftime("%H:%M")


def schedule_trip(route_id: str, from_id: str, to_id: str) -> dict:
    plan = plan_trip(from_id, to_id)
    option = next((o for o in plan["options"] if o["route_id"] == route_id), None)
    if option is None:
        return {"success": False, "message": "That bus doesn't serve this trip."}
    buildings = {b["id"]: b for b in get_campus_map()["buildings"]}
    now = current_time.now()
    bookings_log.record_booking(
        kind="bus",
        title=f"{option['route']}: {buildings[from_id]['name']} to {buildings[to_id]['name']}",
        subtitle=f"{option['plate_number']} · {option['ride_minutes']} min ride",
        date=now.strftime("%Y-%m-%d"),
        time=option["depart_at"],
    )
    return {"success": True, "message": f"Scheduled {option['route']} at {option['depart_at']}."}


LOCATION_FILE = Path(__file__).resolve().parent.parent.parent / "data" / "user_location.json"


def get_my_location() -> dict:
    """Mock 'current location' of the student (a building id). A real build would read GPS."""
    building_id = json.loads(LOCATION_FILE.read_text())["building_id"]
    building = next(b for b in get_campus_map()["buildings"] if b["id"] == building_id)
    return {"building_id": building_id, "name": building["name"]}


def resolve_place(text: str) -> dict | None:
    """Fuzzy-match what the student said ('the gym', 'CS faculty') to a campus building."""
    query = text.strip().lower()
    best, best_len = None, 0
    for b in get_campus_map()["buildings"]:
        for candidate in [b["name"].lower(), b["id"], *b.get("aliases", [])]:
            if candidate in query or (len(query) >= 3 and query in candidate):
                if len(candidate) > best_len:
                    best, best_len = b, len(candidate)
    return best


def _transfer_options(from_id: str, to_id: str) -> list[dict]:
    """One-change journeys (ride bus 1 to a shared stop, then bus 2). All timing is done
    here in seconds so the second bus's position at the moment you arrive is accounted for."""
    data = get_campus_map()
    buildings = {b["id"]: b for b in data["buildings"]}
    now_ts = time.time()
    now = current_time.now()
    routes = {r["id"]: (r, _geometry(r, buildings)) for r in data["routes"]}
    options = []
    for r1, g1 in routes.values():
        if from_id not in r1["stops"] or to_id in r1["stops"]:
            continue
        s1 = _bus_s(r1, g1, now_ts)
        s_from = g1["cum"][r1["stops"].index(from_id)]
        wait1 = ((s_from - s1) % g1["total"]) / r1["speed_mps"]
        for r2, g2 in routes.values():
            if r2["id"] == r1["id"] or to_id not in r2["stops"]:
                continue
            for via in r1["stops"]:
                if via == from_id or via not in r2["stops"]:
                    continue
                ride1 = ((g1["cum"][r1["stops"].index(via)] - s_from) % g1["total"]) / r1["speed_mps"]
                arrive_via = wait1 + ride1
                s2 = (_bus_s(r2, g2, now_ts) + r2["speed_mps"] * arrive_via) % g2["total"]
                s_via2 = g2["cum"][r2["stops"].index(via)]
                wait2 = ((s_via2 - s2) % g2["total"]) / r2["speed_mps"]
                ride2 = ((g2["cum"][r2["stops"].index(to_id)] - s_via2) % g2["total"]) / r2["speed_mps"]
                total_s = arrive_via + wait2 + ride2
                options.append({
                    "via": buildings[via]["name"],
                    "via_id": via,
                    "leg1": {"route_id": r1["id"], "route": r1["name"], "plate_number": r1["plate"],
                             "wait_minutes": math.ceil(wait1 / 60), "ride_minutes": max(1, math.ceil(ride1 / 60))},
                    "leg2": {"route_id": r2["id"], "route": r2["name"], "plate_number": r2["plate"],
                             "wait_minutes": math.ceil(wait2 / 60), "ride_minutes": max(1, math.ceil(ride2 / 60))},
                    "total_minutes": math.ceil(total_s / 60),
                    "arrive_at": _clock(now, math.ceil(total_s / 60)),
                    "_total_s": total_s,
                })
    options.sort(key=lambda o: o["_total_s"])
    for o in options:
        del o["_total_s"]
    return options[:2]


def plan_bus_trip(destination: str, origin: str | None = None) -> dict:
    """Agent-facing trip planner: defaults the start to the student's current location and
    returns finished numbers (wait, ride, arrival) computed in Python, never by the model."""
    if origin:
        start = resolve_place(origin)
        if start is None:
            return {"error": f"I don't recognise the starting place '{origin}'."}
        origin_is_current = False
    else:
        me = get_my_location()
        start = {"id": me["building_id"], "name": me["name"]}
        origin_is_current = True

    end = resolve_place(destination)
    if end is None:
        names = ", ".join(b["name"] for b in get_campus_map()["buildings"])
        return {"error": f"I don't recognise '{destination}'. Known places: {names}."}
    if end["id"] == start["id"]:
        return {"error": f"You're already at {end['name']}."}

    plan = plan_trip(start["id"], end["id"])
    transfers = [] if plan["options"] else _transfer_options(start["id"], end["id"])
    buildings = {b["id"]: b for b in get_campus_map()["buildings"]}
    straight_m = _meters((buildings[start["id"]]["lat"], buildings[start["id"]]["lng"]),
                         (buildings[end["id"]]["lat"], buildings[end["id"]]["lng"]))
    walk_minutes = max(1, math.ceil(straight_m * 1.25 / 1.3 / 60))
    where = f"You're at {start['name']}" if origin_is_current else f"Starting from {start['name']}"

    def wait_text(minutes: int) -> str:
        return "is arriving now" if minutes == 0 else f"arrives in {minutes} min"

    if plan["options"]:
        o = plan["options"][0]
        summary = (f"{where}. {o['route']} {wait_text(o['wait_minutes'])}, and the ride to {end['name']} takes "
                   f"{o['ride_minutes']} min, so you'd arrive around {o['arrive_at']}.")
        if len(plan["options"]) > 1:
            summary += " Other buses are listed below."
    elif transfers:
        t = transfers[0]
        summary = (f"There's no direct bus from {start['name']} to {end['name']}. {where}: take {t['leg1']['route']} "
                   f"({wait_text(t['leg1']['wait_minutes'])}) to {t['via']}, then {t['leg2']['route']}, "
                   f"for about {t['total_minutes']} min in total (arriving around {t['arrive_at']}).")
    else:
        summary = (f"There's no direct or one-change bus from {start['name']} to {end['name']} "
                   f"(it would need two changes).")
    summary += f" Walking would take about {walk_minutes} min."
    return {
        "walk_minutes": walk_minutes,
        "summary": summary,
        "transfers": transfers,
        "origin": start["name"],
        "origin_is_current_location": origin_is_current,
        "destination": end["name"],
        "from_id": start["id"],
        "to_id": end["id"],
        "error": None if transfers else plan["error"],
        "note": "No direct bus; each option needs one change." if transfers else None,
        "options": plan["options"],
    }


def trip_cards(result: dict) -> list[dict]:
    """Tappable chat cards for a plan_bus_trip result; each opens live tracking of that bus."""
    cards = []
    for t in result.get("transfers", []):
        l1, l2 = t["leg1"], t["leg2"]
        first = "arriving now" if l1["wait_minutes"] == 0 else f"arrives in {l1['wait_minutes']} min"
        cards.append({
            "kind": "bus",
            "id": l1["route_id"],
            "title": f"{l1['route']}, then {l2['route']}",
            "subtitle": f"Change at {t['via']} · first bus {first} · about {t['total_minutes']} min total · you arrive {t['arrive_at']}",
            "from_id": result["from_id"],
            "to_id": t["via_id"],
            "available": True,
        })
    for o in result.get("options", []):
        wait = "arriving now" if o["wait_minutes"] == 0 else f"arrives in {o['wait_minutes']} min"
        cards.append({
            "kind": "bus",
            "id": o["route_id"],
            "title": f"{o['route']} · {o['plate_number']}",
            "subtitle": f"{result['origin']} to {result['destination']} · {wait} · {o['ride_minutes']} min ride · you arrive {o['arrive_at']}",
            "from_id": result["from_id"],
            "to_id": result["to_id"],
            "available": True,
        })
    return cards


def walk_minutes_between(from_id: str, to_id: str) -> int:
    """Straight-line walk with a detour allowance; moving inside one building counts as 1 min."""
    if from_id == to_id:
        return 1
    buildings = {b["id"]: b for b in get_campus_map()["buildings"]}
    a, b = buildings[from_id], buildings[to_id]
    return max(1, math.ceil(_meters((a["lat"], a["lng"]), (b["lat"], b["lng"])) * 1.25 / 1.3 / 60))
