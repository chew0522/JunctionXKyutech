# PRD: Campus Concierge — AI Agent for Connected Campus Life

**Track:** JunctionX Kyutech 2026 — Track 02, Hack Connected Everywhere
**Team size:** 4 (1 engineer, 3 non-engineering: UX/design, competitor analysis + slides, business/pitch)
**Build window:** 24 hours

---

## 1. Problem

Campus life is fragmented across disconnected systems — students juggle separate apps/portals for events, room bookings, transport, clinic appointments, and announcements. There's no single, natural way to ask "what's happening on campus right now" or get something *done* (book a room, check a bus) without hunting through multiple apps.

## 2. Solution

A conversational AI agent that sits on top of campus services. Students ask in plain language; the agent looks up real-time info across multiple sources **and takes actions on their behalf** (not just answering — booking, adding to-dos, etc.), via DeepSeek's function/tool-calling.

## 3. Goals for the hackathon demo

- Prove the agent can **initiate**, not just respond — a proactive nudge the student didn't ask for (the core differentiator vs. every other "campus chatbot")
- Prove the agent can **take an action**, not just answer (the "agent vs chatbot" distinction)
- Prove the "ask once, agent connects the dots" experience — one answer combining 2+ data sources
- Present a credible extensibility + cost story so judges see this as a real platform, not a toy

**Scope decision:** all features in §5 are committed to be built — none are conditional on time remaining. §5's ordering is build sequence, not a priority cutoff. If the team falls behind schedule, cut scope explicitly by re-opening this PRD and moving an item to §5's Tier 3 (Roadmap only) — don't silently drop something the day of.

## 4. Non-goals (explicitly out of scope for this build)

- Real integration with the school's official Student Information System — specifically **course enrollment/registration**, exam results, and student ID/identity. Note this is narrower than "academic platform": *viewing* already-enrolled courses, materials, and assignments is in scope (§5, Tier 1) and uses the same mock-data pattern as everything else — it's only the enrollment/registration transaction itself, and anything identity- or grade-related, that's deferred.
- Any authentication/security-sensitive student data
- Real hardware/IoT sensors (cafe crowd detection, bus GPS) — all simulated/mocked
- **Assignment submission through the agent.** Deliberately removed after initially building it — turning in coursework is high-stakes and hard to "undo" (unlike booking a room), and letting an AI agent submit on the student's behalf makes them too dependent on it for something that matters academically. The agent can *view* assignments and due dates, but always redirects the student to the school's real submission portal to actually submit. Same category of judgment call as the SIS exclusions above.

## 5. Feature scope, by build order

All features below are committed — the tiering is build sequence (build 0 first, then 1, then 2, then the cross-connector feature), not an optionality ranking. See §3 for what to do if the team runs out of time.

### Tier 0 — build first
| Feature | Behavior |
|---|---|
| Proactive Nudges | Agent surfaces an unsolicited, timely message based on the student's context — e.g. "Your next class starts in 15 min and it's a 10-min walk, leave now", "Your usual study room is filling up, want me to reserve it?", or "Your assignment is due in a few hours and you haven't submitted it." This is the single highest-leverage feature for both Innovation and Impact scoring (see judging-criteria notes) — it's what separates an *agent* from a *chatbot*. |

### Tier 1 — build second
| Feature | Behavior |
|---|---|
| Event Information Center | Agent answers questions about campus events (desc, date, time, venue) from a mock event dataset |
| Library Study Room Reservation | Agent checks room availability and **books a room** (the "agent takes action" wow moment) |
| School Bus Location Tracker | Agent reports simulated live bus location/ETA |
| Academic Platform (view-only) | Agent shows the student's enrolled courses, course materials (slides/readings/recordings), and assignments. No submission action — see §4; the agent redirects to the real submission portal instead. Enrollment/registration itself also stays out of scope (§4). |
| Built-in To-Do List | **Sourced entirely from pending lecturer assignments** (via the Academic Platform), sorted by due date — not a freeform personal list. The agent can list it but does not add arbitrary personal tasks to it. |

### Tier 2 — build third
| Feature | Behavior |
|---|---|
| Cafe Crowd Detection | Agent reports a mocked crowd level (low/medium/high); framed as "would come from real sensors in production" |
| School Clinic Reservation | Reuses the room-booking pattern for appointment booking |
| Student Service Assistance | Covered by the agent's general Q&A/help capability — not a separate module |

### Tier 2.5 — build fourth
| Feature | Behavior |
|---|---|
| Cross-connector reasoning (coffee-run planner) | Agent answers "do I have time to grab coffee before my [course] class?" by combining class schedule + cafe crowd/wait time + walk times between campus zones. **Built as a dedicated deterministic tool (`plan_coffee_run`), not free-form LLM arithmetic** — the model never estimates or sums times itself; it calls the tool and phrases the result. Walk times are a static mock lookup table, not a real maps API (see §7). |

### Tier 3 — roadmap only, not built this hackathon
| Feature | Why deferred |
|---|---|
| Course Registration/Enrollment | Requires real SIS integration, high stakes if incorrect (distinct from *viewing* enrolled courses, which is Tier 1) |
| Exam Results | Sensitive student data, needs real auth |
| Student ID / College Residency | Needs real identity verification, security-critical |

Tier 3 stays deferred regardless of schedule — these need real school-system access this hackathon cannot provide, not just more time.

## 6. Architecture principle: connector-based extensibility

One core agent (DeepSeek + tool-calling) + a library of independent "connectors" (tools). Each connector = one data source or action, with its own input/output schema. Adding a new campus service later means writing one new connector function — no rearchitecture required.

```
Agent (DeepSeek, tool-calling)
 ├── connector: get_events()
 ├── connector: book_study_room()
 ├── connector: get_bus_location()
 ├── connector: get_cafe_crowd()
 ├── connector: book_clinic_appointment()
 ├── connector: get_courses() / get_course_materials() / get_assignments()  ← view-only, no submit (§4)
 ├── connector: todo_list()  ← derived from get_assignments(pending_only=True), not its own data
 ├── nudge engine: periodic check → pushes a proactive message into the chat when a rule fires (Tier 0)
 └── [future] connector: course_registration()  ← Tier 3, not built
```

This is the pitch's technical answer to "how does this scale?"

**Design principle for anything time/quantity-sensitive:** never let the LLM estimate or calculate a number that matters (walk times, whether something is feasible in time, costs). Write a dedicated deterministic tool that does the real computation in Python and returns a structured verdict — the model's only job is to call it and phrase the result in natural language. `plan_coffee_run` (§6.2) is the reference example; follow the same pattern for any future reasoning feature.

### 6.1 Proactive nudge engine (Tier 0 — build first)

Unlike a connector (which the agent calls reactively when the student asks something), the nudge engine runs **independently** and pushes a message *into* the chat without being asked. For a 24h demo, keep this simple and rule-based — no need for real background scheduling infrastructure:

- **Trigger source:** a small set of hardcoded/mock rules evaluated against the mock data (e.g. "if next event start time − now < 15 min AND student hasn't acknowledged it → nudge"; "if room X occupancy > 90% AND student's usual room = X → nudge")
- **Delivery for the demo:** a timer/poll on the Flutter client (or a simple backend loop) that checks rule conditions every N seconds and, if one fires, injects a message bubble into the chat as if the agent "spoke first" — no need for real push notifications infra
- **Reuses existing connectors:** the nudge engine calls the same `get_events()`, `get_bus_location()`, etc. functions the agent already has — it does not need its own data layer
- **Demo script:** stage the mock data/timing so a nudge fires live during the pitch (e.g. time the demo so "student's next class" is a few minutes away) rather than relying on a real clock coincidence

### 6.2 Coffee-run planner (Tier 2.5)

Answers "do I have time to grab coffee before my [course]'s class?" — the flagship cross-connector reasoning example.

- **Real Google Maps Distance Matrix API for outdoor walk time** (`connectors/campus_map.py`), using coordinates in `data/zone_coordinates.json`. **Automatic fallback to the static mock table** (`data/walk_times.json`) whenever a zone's coordinates are unset, the API key is missing, or the call fails — this is deliberate, not a bug: it keeps the demo safe from network issues on stage, and lets the team plug in real campus coordinates whenever they're ready with zero code changes.
- **The student's current location and the demo clock are both hardcoded** (`STUDENT_CURRENT_ZONE` in `connectors/planner.py`, `current_time.DEMO_NOW`) so the scenario can be staged reliably rather than depending on real device location or wall-clock timing.
- **The math is deterministic, not LLM-estimated:** `plan_coffee_run` computes walk-to-cafe + wait-in-line + walk-to-class against time remaining until class, in Python, and returns a structured feasible/not-feasible verdict with a recommended cafe. The model only narrates that result — see the design principle in §6.
- **Anticipated judge question — "how would this work in the real world, that can't be mocked?"** Answer: outdoor walk time is a solved problem via Maps APIs (which is what we use); indoor navigation (building → specific room) genuinely can't be solved by Maps — no mainstream maps API routes indoors — so the real industry answer there is a maintained static lookup table, calibrated over time from real usage data, which is exactly the architecture built here. The mock table isn't a hackathon shortcut we'd throw away; it's the production design for the indoor half of the problem, just pre-seeded with example data instead of the school's real floor plan.

## 7. Tech stack

- **Backend:** Python (FastAPI) or Node (Express) — pick whichever the coder knows best
- **AI:** DeepSeek API (OpenAI-compatible chat completions format), function/tool-calling
- **Data:** Mock JSON/CSV datasets for events, rooms, bus, cafe, clinic — no real hardware or school system integration
- **Frontend:** Flutter (single chat screen, cross-platform demo on phone or web)
- **Hosting:** Local run for demo; no production deployment needed for the hackathon
- **Maps/location:** using the real **Google Maps Distance Matrix API** (walking mode) for outdoor building-to-building walk times, via a Google Maps Platform key already on hand. Falls back automatically to the static mock table if a zone's coordinates aren't set yet or the API call fails for any reason (network, quota, key issue) — see §6.2. Real campus coordinates for the zones (Library, Student Union, Engineering Building, Building A/B) are still TBD in `data/zone_coordinates.json`; until they're filled in, the app runs entirely on the mock table with no behavior change. Indoor navigation (building → specific room) still uses the static table regardless, since Maps doesn't route indoors — see the judge Q&A note in §6.2.

## 8. Cost & business model (for the pitch)

- DeepSeek's API is priced substantially lower per-token than most Western frontier-model APIs — verify current published rates before quoting exact figures on a slide, but the directional pitch point (a real cost estimate at ~2,000 active students × 5 queries/day) should still be built and shown, using whatever DeepSeek's current pricing page states at build time
- Cost-reduction levers to present regardless of provider: caching repeated system/tool context, hybrid architecture (simple lookups skip the LLM entirely — only genuinely ambiguous/reasoning queries hit the model), rate limits per student, phased pilot rollout (single department first)
- Positioning: DeepSeek's lower per-token cost strengthens the "this is affordable even for a smaller institution" argument — make that comparison explicit in the pitch

## 9. Success criteria for the demo

1. **Live proactive nudge:** the agent surfaces an unsolicited, timely message during the demo without being asked — this is the must-land moment
2. Live agent action: booking a study room or adding a to-do, executed on stage, not just described
3. Live multi-source answer: one question, combining 2+ data sources in a single response
4. All Tier 0-2.5 connectors respond correctly to at least one rehearsed question each
5. A cost/extensibility slide that shows the team thought past the demo into real deployment

## 10. Competitive landscape

To be filled in by the Competitor Analysis role during the build — compare against existing campus app solutions (generic university portal apps, single-purpose room-booking apps, chatbot-only FAQ bots) on: whether they take actions vs. just display info, whether they unify multiple services vs. staying siloed, and cost/deployment model. Use this to sharpen the pitch's differentiation claim (agent-that-acts + connector extensibility + credible cost story).

## 11. Team roles

| Role | Owns |
|---|---|
| Coder | Backend, DeepSeek tool-calling integration, Flutter chat UI, deployment for demo |
| UX/Design | User flow, chat UI mockup, agent tone/sample responses |
| Competitor Analysis + Slides | Competitor/market research, mock datasets, pitch deck slides, live testing/QA |
| Business/Pitch | Cost model, roadmap slide, demo delivery |

## 12. Timeline (24h)

All tiers below are in scope — this is a tight schedule, so each block has a hard cutoff. If a block overruns, move to the next one anyway and fix the gap in the 19-21h buffer rather than letting one feature eat later blocks.

- **0-3h:** Basic chat UI + backend + DeepSeek API connected, plain Q&A working
- **3-6h:** Tier 0 proactive nudge engine working end-to-end (at least one rule firing reliably)
- **6-10h:** Tier 1 connectors (events, room booking, bus, to-do) wired into tool-calling
- **10-13h:** Tier 2 connectors (cafe crowd, clinic booking) — reuse the Tier 1 booking pattern to move fast
- **13-16h:** Tier 2.5 cross-connector reasoning, using the now-complete connector set
- **16-19h:** Full pass on agent response quality/tone across all connectors, team demo sync
- **19-21h:** Bug fixes, demo flow smoothing, full team run-through (confirm the nudge fires reliably on cue)
- **21-24h:** Pitch prep and rehearsal only — feature freeze

**If genuinely behind at the 13h checkpoint:** re-open §3's scope decision as a team, and explicitly move Tier 2.5 (and only Tier 2.5) to a "described in the pitch, not demoed live" fallback — don't quietly cut Tier 0-2, since those are what the success criteria in §9 depend on.
