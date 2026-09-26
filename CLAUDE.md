# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

Campus Concierge — an AI agent for campus services, built for JunctionX Kyutech 2026, Track 02 (Hack Connected Everywhere). Full context and scope: [PRD.md](PRD.md). Read it before making architectural decisions.

24-hour hackathon build. Only one team member codes — prioritize speed and clarity over polish. Don't build Tier 3 features (course *enrollment*/registration, exam results, student ID) — they're explicitly out of scope; see PRD §4-5. Note this is narrower than "academic platform" — *viewing* enrolled courses, materials, and assignments (and submitting an assignment) is in scope and already built.

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

- **Tier 0 (build first):** nudge engine — a rule-based check (polling on a timer is fine) that evaluates mock data and pushes an unsolicited message into the chat when a rule fires. It reuses Tier 1 connector functions for data access; it does not get its own data layer. See PRD §6.1 for the exact trigger design.
- **Tier 1:** `get_events`, `book_study_room`, `get_bus_location`, `get_courses`/`get_course_materials`/`get_assignments`/`submit_assignment`, `todo_list`.
- **Tier 2:** `get_cafe_crowd`, `book_clinic_appointment` (reuse the Tier 1 booking pattern).
- **Tier 2.5 (build after Tier 0-2 exist):** cross-connector reasoning — one answer combining 3+ connectors. Needs the full connector set in place first, since there's nothing to reason across otherwise.

**`todo_list` is not a standalone data source** — it derives its output from `get_assignments(pending_only=True)` in `connectors/academic.py`. There is deliberately no `todo_add`: the to-do list only ever reflects pending lecturer assignments, never arbitrary personal notes. Don't reintroduce a personal-add path without checking with the team first — it was a scope decision, not an oversight.

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
