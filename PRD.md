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
- Prove the "ask once, agent connects the dots" experience across 2+ data sources in one answer (stretch — build if time allows, see §5)
- Present a credible extensibility + cost story so judges see this as a real platform, not a toy

## 4. Non-goals (explicitly out of scope for this build)

- Real integration with the school's official Student Information System (course registration, exam results, student ID/identity)
- Any authentication/security-sensitive student data
- Real hardware/IoT sensors (cafe crowd detection, bus GPS) — all simulated/mocked

## 5. Feature scope, by tier

### Tier 0 — Highest priority, build before anything else in Tier 1/2
| Feature | Behavior |
|---|---|
| Proactive Nudges | Agent surfaces an unsolicited, timely message based on the student's context — e.g. "Your next class starts in 15 min and it's a 10-min walk, leave now" or "Your usual study room is filling up, want me to reserve it?" This is the single highest-leverage feature for both Innovation and Impact scoring (see judging-criteria notes) — it's what separates an *agent* from a *chatbot*. |

### Tier 1 — Built and demoed live
| Feature | Behavior |
|---|---|
| Event Information Center | Agent answers questions about campus events (desc, date, time, venue) from a mock event dataset |
| Library Study Room Reservation | Agent checks room availability and **books a room** (the "agent takes action" wow moment) |
| School Bus Location Tracker | Agent reports simulated live bus location/ETA |
| Built-in To-Do List | Agent adds/reads personal tasks on request ("remind me to submit the assignment Friday") |

### Tier 2 — Present as connected, kept shallow
| Feature | Behavior |
|---|---|
| Cafe Crowd Detection | Agent reports a mocked crowd level (low/medium/high); framed as "would come from real sensors in production" |
| School Clinic Reservation | Reuses the room-booking pattern for appointment booking |
| Student Service Assistance | Covered by the agent's general Q&A/help capability — not a separate module |

### Stretch — build only if Tier 0/1/2 are done with time to spare
| Feature | Behavior |
|---|---|
| Cross-connector reasoning | Agent combines 3+ connectors to answer something none could alone — e.g. "best time to grab coffee before your 2pm class" factoring in cafe crowd + walk time + class location. Do not start this until Tier 0/1/2 are demo-solid; a broken stretch feature costs more (Technical Quality) than a missing one costs (Innovation). |

### Tier 3 — Roadmap only, not built
| Feature | Why deferred |
|---|---|
| Course Registration | Requires real SIS integration, high stakes if incorrect |
| Exam Results | Sensitive student data, needs real auth |
| Student ID / College Residency | Needs real identity verification, security-critical |

## 6. Architecture principle: connector-based extensibility

One core agent (DeepSeek + tool-calling) + a library of independent "connectors" (tools). Each connector = one data source or action, with its own input/output schema. Adding a new campus service later means writing one new connector function — no rearchitecture required.

```
Agent (DeepSeek, tool-calling)
 ├── connector: get_events()
 ├── connector: book_study_room()
 ├── connector: get_bus_location()
 ├── connector: get_cafe_crowd()
 ├── connector: book_clinic_appointment()
 ├── connector: todo_add() / todo_list()
 ├── nudge engine: periodic check → pushes a proactive message into the chat when a rule fires (Tier 0)
 └── [future] connector: course_registration()  ← Tier 3, not built
```

This is the pitch's technical answer to "how does this scale?"

### 6.1 Proactive nudge engine (Tier 0 — build first)

Unlike a connector (which the agent calls reactively when the student asks something), the nudge engine runs **independently** and pushes a message *into* the chat without being asked. For a 24h demo, keep this simple and rule-based — no need for real background scheduling infrastructure:

- **Trigger source:** a small set of hardcoded/mock rules evaluated against the mock data (e.g. "if next event start time − now < 15 min AND student hasn't acknowledged it → nudge"; "if room X occupancy > 90% AND student's usual room = X → nudge")
- **Delivery for the demo:** a timer/poll on the Flutter client (or a simple backend loop) that checks rule conditions every N seconds and, if one fires, injects a message bubble into the chat as if the agent "spoke first" — no need for real push notifications infra
- **Reuses existing connectors:** the nudge engine calls the same `get_events()`, `get_bus_location()`, etc. functions the agent already has — it does not need its own data layer
- **Demo script:** stage the mock data/timing so a nudge fires live during the pitch (e.g. time the demo so "student's next class" is a few minutes away) rather than relying on a real clock coincidence

## 7. Tech stack

- **Backend:** Python (FastAPI) or Node (Express) — pick whichever the coder knows best
- **AI:** DeepSeek API (OpenAI-compatible chat completions format), function/tool-calling
- **Data:** Mock JSON/CSV datasets for events, rooms, bus, cafe, clinic — no real hardware or school system integration
- **Frontend:** Flutter (single chat screen, cross-platform demo on phone or web)
- **Hosting:** Local run for demo; no production deployment needed for the hackathon

## 8. Cost & business model (for the pitch)

- DeepSeek's API is priced substantially lower per-token than most Western frontier-model APIs — verify current published rates before quoting exact figures on a slide, but the directional pitch point (a real cost estimate at ~2,000 active students × 5 queries/day) should still be built and shown, using whatever DeepSeek's current pricing page states at build time
- Cost-reduction levers to present regardless of provider: caching repeated system/tool context, hybrid architecture (simple lookups skip the LLM entirely — only genuinely ambiguous/reasoning queries hit the model), rate limits per student, phased pilot rollout (single department first)
- Positioning: DeepSeek's lower per-token cost strengthens the "this is affordable even for a smaller institution" argument — make that comparison explicit in the pitch

## 9. Success criteria for the demo

1. **Live proactive nudge:** the agent surfaces an unsolicited, timely message during the demo without being asked — this is the must-land moment
2. Live agent action: booking a study room or adding a to-do, executed on stage, not just described
3. Live multi-source answer: one question, combining 2+ data sources in a single response (stretch, see §5)
4. A cost/extensibility slide that shows the team thought past the demo into real deployment

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

- **0-4h:** Basic chat UI + backend + DeepSeek API connected, plain Q&A working
- **4-8h:** Tier 0 proactive nudge engine working end-to-end (at least one rule firing reliably) — do this before Tier 1 connectors
- **8-13h:** Tool-calling for Tier 1 connectors on mock data
- **13-17h:** Tier 2 connectors added, agent responses polished, team demo sync
- **17-19h:** Stretch — cross-connector reasoning, only if Tier 0/1/2 are demo-solid
- **19-21h:** Bug fixes, demo flow smoothing, full team run-through (confirm the nudge fires reliably on cue)
- **21-24h:** Pitch prep and rehearsal only — feature freeze
