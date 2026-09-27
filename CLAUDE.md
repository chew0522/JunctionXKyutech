# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

Campus Concierge — an AI agent for campus services, built for JunctionX Kyutech 2026, Track 02 (Hack Connected Everywhere). Full context and scope: [PRD.md](md/PRD.md). Read it before making architectural decisions.

24-hour hackathon build. Only one team member codes — prioritize speed and clarity over polish. Don't build Tier 3 features (course *enrollment*/registration, exam results, student ID) — they're explicitly out of scope; see PRD §4-5. The Scan / Pay / ID screen (Dashboard button) is also demo-only: Scan understands `attendance:<COURSE>` and `merit:<ID>` codes, Pay and ID show rotating fake QR codes and process nothing. MyRegister, MyFinance and MyForm exist as display-only mock pages under the Profile menu (registration is closed and nothing is enrolled; forms just save a submission record) — do not connect them to real systems. Note this is narrower than "academic platform" — *viewing* enrolled courses, materials, and assignments is in scope and already built. **Assignment submission is also out of scope** (removed after initially building it, PRD §4) — it's high-stakes and hard to undo, so the agent redirects students to the real submission portal instead of submitting on their behalf. Don't reintroduce a `submit_assignment` tool without checking with the team first.

## Tech stack

- **Backend:** Python, FastAPI
- **AI:** DeepSeek API, called via its OpenAI-compatible chat completions endpoint (use the `openai` Python SDK pointed at DeepSeek's `base_url`, not the Anthropic SDK), using function/tool-calling
- **Data:** Mock JSON files under `data/` — no real database, no real school system integration
- **Frontend:** Flutter, single chat screen — no routing/state-management package needed for a hackathon scope
- **Auth/hosting:** None. Local run only, for live demo.

This project is not an Anthropic/Claude API project — do not reach for the `anthropic` SDK, Claude model IDs, or Claude-specific tool-calling patterns (Tool Runner, `@beta_tool`, etc.) anywhere in this codebase.

## Architecture: connector pattern

The agent is one DeepSeek tool-calling loop plus a set of independent connector functions — one per data source/action. Each connector:
- Takes a small, explicit input schema
- Reads from (or writes to) its own mock JSON file under `data/`
- Has no dependency on other connectors

**All tiers below are committed to be built** (see PRD §3, §5, §12) — the numbering is build order, not an optionality ranking. Only Tier 3 (course registration, exam results, student ID) is out of scope, and that's because it needs real school-system access this hackathon doesn't have, not because of time.

- **Tier 0:** proactive nudges were built and then removed at the team's request — don't reintroduce a nudge engine, `/nudges` endpoint, or nudge cards without checking first.
- **Tier 1:** `get_events`, `book_study_room`, `get_bus_location`, `get_courses`/`get_course_materials`/`get_assignments` (view-only — no submit, see above), `todo_list`.
- **Tier 2:** `get_cafe_crowd`, `book_clinic_appointment` (reuse the Tier 1 booking pattern).
- **Tier 2.5:** `plan_coffee_run` (`connectors/planner.py`) — cross-connector reasoning combining class schedule, cafe crowd/wait time, and walk times.

**Walk times use the real Google Maps Distance Matrix API when possible** (`connectors/campus_map.py`), via `GOOGLE_MAPS_API_KEY` in `.env`. It falls back to the static table in `data/walk_times.json` automatically whenever a zone in `data/zone_coordinates.json` has no coordinates yet, or the API call fails for any reason — this fallback is intentional, not a bug to fix. Don't remove it or make the API call required; the whole point is the app keeps working identically whether or not real coordinates/network are available. When real campus coordinates are added to `data/zone_coordinates.json` (format: `{"lat": ..., "lng": ...}` per zone), the real API path activates automatically with no other code changes needed.

**`todo_list` is not a standalone data source** — it derives its output from `get_assignments(pending_only=True)` in `connectors/academic.py`. There is deliberately no `todo_add`: the to-do list only ever reflects pending lecturer assignments, never arbitrary personal notes. Don't reintroduce a personal-add path without checking with the team first — it was a scope decision, not an oversight.

**Design rule: never let the LLM estimate or calculate a number that matters** (walk times, time-feasibility, costs). Write a dedicated deterministic tool that computes the real answer in Python and returns a structured verdict — the model's only job is to call it and phrase the result. `plan_coffee_run` is the reference implementation: it looks up `get_next_class` (internal, not its own agent tool — `connectors/academic.py`) and `get_walk_minutes` (`connectors/campus_map.py`), does the arithmetic itself, and only hands the model a finished verdict to narrate. Follow this pattern for any new reasoning feature; don't hand the model raw numbers and trust it to add them up.

**Buses are simulated, not stored:** `connectors/bus_sim.py` moves each bus along its loop from `data/campus_map.json` as a function of wall-clock time (no `bus.json`). `get_bus_location`, the Dashboard tile, the live map, the trip planner and trip scheduling all read from it. The map is a drawn mock (no Google Maps API); don't add one without checking with the team. `plan_bus_trip` (agent tool) starts from the mock current location in `data/user_location.json`, computes wait/ride/transfer times in Python, and returns a `summary` sentence that the reply must use; the chat shows tappable bus cards that open live tracking.

**Booking through chat:** the agent never books by itself. `propose_booking` (`connectors/booking_proposals.py`) turns a request like 'basketball Tuesday' into a concrete free slot, and the chat shows a Confirm / Change time card; the Confirm tap calls the booking API directly with those exact details. Keep that human tap in the loop.

**Planner tools** (`plan_coffee_run`, and in `connectors/day_planner.py`: `plan_getting_to_class`, `plan_my_day`, `find_clash_free`, `find_study_spot`) each do the multi-step reasoning in Python and return a `summary` sentence the reply must start with; `agent.py` puts it back if the model drops it. Prefer adding or fixing a planner over adding prompt rules, and re-run `python eval_questions.py` from `backend/` after any prompt or tool change.

**Shared demo clock:** `current_time.py` starts at 2026-09-26 14:50 and then runs forward in real time from server start (`POST /reset-demo` or `python demo_reset.py` re-anchors it; `DEMO_CLOCK=fixed` freezes it). Everything reads `current_time.now()` — never add a second copy. **Class clashes are a soft warning:** room, facility and clinic bookings return `needs_confirmation` and go through only with `force=true` after the student confirms. Existing bookings can be moved with `POST /api/my-bookings/{id}/change`.

If running behind, don't silently drop scope — that's a PRD §12 checkpoint decision for the whole team, not a call to make alone mid-build.

When adding a new connector: write the function, register it as a tool, add its mock data file. Don't refactor the agent loop itself to accommodate a new connector — if that seems necessary, the connector is scoped wrong.

## Conventions

- Keep connector functions pure and small — one file per connector under `backend/connectors/`, one mock data file per connector under `data/`.
- No comments explaining what a connector does — name it clearly instead. Comment only genuine non-obvious constraints (e.g. a mock data quirk the demo depends on).
- Don't add auth, persistence, retries, or error handling beyond what's needed for a live demo to not crash. This is a 24h prototype, not production code.
- Keep the system prompt and tool descriptions in one place (e.g. `backend/agent.py`) so they're easy to tune live during the hackathon.

## Running the project

Backend:
```bash
cd backend && uvicorn main:app --reload
```

Frontend:
```bash
cd frontend && flutter run
```

Requires `DEEPSEEK_API_KEY` set in the environment.

## What not to do

- Don't build against real school APIs — none exist for this project; everything is mocked.
- Don't add features from PRD Tier 3.
- Don't reach for the Anthropic/Claude SDK or Claude model IDs — this project uses DeepSeek exclusively.
- Don't optimize for cost during the hackathon build (caching, hybrid lookup/LLM split) — those are pitch-deck talking points for the business case, not things to implement under time pressure. Ship the demo first.
