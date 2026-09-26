# App pages — build spec for the coder

**These are real, standalone pages — not the chat.** Reaching one means seeing a scrollable list, not a conversation. The chat (specified in [chat-ui.md](chat-ui.md)) is reached **only** through the **Ask** button.

Shared with [dashboard.md](dashboard.md): colours/fonts in [design.md](design.md), the bottom bar, the back-chevron header. Demo data: Sat 26 Sep 2026, 14:50.

## Shared page header (not the chat header)

Every page below uses this, not the chat's `[home] Campus Concierge` header:

```
(‹)  Page title
```
| Part | Spec |
|---|---|
| Back button | 44 × 44, outlined `line`, radius 12, left-chevron icon. Goes back to Dashboard (or wherever the page was opened from) |
| Title | Page name (Bricolage 20 / 700), e.g. "Events", "Buses", "Cafes", "Courses", "Bookings" |
| Bottom bar | Shown on the 4 tab pages (Events, Courses, Bookings, and Home) with that tab active. **Not shown** on drill-in pages reached from a Dashboard tile only (Buses, Cafes) — those just go back with the chevron |

---

## 1. Events — canvas **EventsPage**, bottom bar tab

List of every campus event, grouped by day, nearest first.

| Part | Spec |
|---|---|
| Section label | "Today · Sat 26 Sep" for the first group, then just the date ("Sun 27 Sep", …) |
| Card per day | `surface`, 1 px `line`, radius 20, one row per event, 1 px `lineSoft` divider between rows |
| Row | time (Bricolage 16, `primary`, 52 px wide) · name (15 / 600) + "venue · organizer" (13 muted) · category pill (right, `primaryTint` fill, `primary` text, 11 / 700) |

Rows: **15:00 AI Workshop** — Building A, Room 101 · Computer Science Club — *Workshop* · **17:00 Career Fair** — Main Hall · Career Services Office — *Career* · (Sun 27) **07:30 Morning Yoga**, **13:00 Robotics Showcase** · (Mon 28) **10:00 Guest Lecture: Climate Data Modeling**, **12:00 International Food Festival** · (Tue 29) **18:00 Midterm Study Jam** · (Wed 30) **19:00 Startup Pitch Night**.

Data: `get_events()`, all of them, sorted by date then time.
Row tap: no action for the mock (or opens a simple detail sheet with the `description` field, if there's time).

---

## 2. Buses — canvas **BusPage**, opened from the Dashboard's "Next bus" tile only (not a bottom-bar tab)

| Part | Spec |
|---|---|
| Section label | "Live · updated 20 s ago" |
| One card per route | `surface`, 1 px `line`, radius 20, padding 14: `bus` icon in a 36 px `primaryTint` square · route name (Bricolage 16) + "current stop → next stop" (13 muted) · right: ETA (Bricolage 22, `primary`) + a small status pill (Quiet green / Moderate amber / Crowded red) |

Rows, in `bus.json` order: **Campus Loop A** — Library → Dormitory Block C — 4 min — Moderate · **Campus Loop B** — Main Gate → Engineering Building — 9 min — Crowded · **Campus Loop C** — Sports Complex → Student Union — 2 min — Quiet · **Off-Campus Shuttle** — Train Station → Main Gate — 14 min — Moderate.

Data: `get_bus_location()`, all routes. `capacity_status` → Quiet (empty) / Moderate / Crowded, colour-coded **and** labelled (never colour alone).

---

## 3. Cafes — canvas **CafePage**, opened from the Dashboard's "Quietest cafe" tile only

| Part | Spec |
|---|---|
| Section label | "Quietest first" |
| One card, one row per cafe | `coffee` icon in a 36 px `primaryTint` square · name (15 / 600) + location (13 muted) · right: 3 bars + word (Low/Medium/High, 14 / 700) + "{n} min wait" (12 muted) |

Sorted quietest first: **Student Union Coffee Bar** — Low, 2 min · **Engineering Building Kiosk** — Medium, 6 min · **Main Library Cafe** — High, 12 min.

Data: `get_cafe_crowd()`, sorted by `crowd_level` (low → high).

---

## 4. Courses — canvas **CoursesPage**, bottom bar tab

Two sections in one scroll: **to-dos** first (the "Due next" tile also lands here), then **courses**.

### To-dos section
| Part | Spec |
|---|---|
| Section label | "To-dos · 3 not submitted" |
| Card, one row per pending assignment | Empty checkbox 20 px · title (14 / 600) + course (13 muted) · due, right — **today's item gets an indigo pill** ("Today 23:59", white on `primary`), others plain muted text |

Rows: **Problem Set 3 – Consensus** / CS301 Distributed Systems / **Today 23:59** (pill) · **Lab 5 – Balanced Trees** / CS210 Data Structures / Tue 18:00 · **Homework 2 – Fourier Series** / EE150 Signals and Systems / Wed 23:59.

Tapping a row opens the **Submit assignment** confirm flow (reuse the chat's confirm/submitted cards from [chat-ui.md § C10](chat-ui.md), shown in-page instead of in a chat bubble — same card, same copy, no user/agent bubbles around it).

### Courses section
| Part | Spec |
|---|---|
| Section label | "My courses" |
| Card, one tappable row per course | cap icon in 36 px square · "CODE Name" (14 / 600) + "instructor · n due" (13 muted) · chevron (right) |

Rows: **CS301 Distributed Systems** — Prof. Yamamoto · 1 due · **CS210 Data Structures & Algorithms** — Prof. Ito · 1 due · **EE150 Signals and Systems** — Prof. Kobayashi · 1 due.

Tapping a course opens its **materials** (reuse the chat's materials card from [chat-ui.md § C9](chat-ui.md), shown as its own page or an inline expand — coder's call on time).

Data: `get_assignments(pending_only=True)` sorted by due date; `get_courses()`; `get_course_materials(course_id)`; `submit_assignment(id)`.

---

## 5. Bookings — canvas **BookingsPage**, bottom bar tab

Two sections: study rooms, then clinic.

### Study rooms section
| Part | Spec |
|---|---|
| Section label | "Study rooms · {n} free" |
| Card, one row per room | `door` icon in 36 px square · name (14 / 600) + "location · seats" (13 muted) · right: **Book** button (`primary` fill, pill, 32 px) if free, or "Taken" (`danger`, 12 / 600) if not |

All 7 rooms from `rooms.json`, available ones first or in id order — coder's call: **Study Room 201** (free) · **202** (free) · **203** (taken) · **204** (taken) · **205** (free) · **Group Pod A** (taken) · **Group Pod B** (free).

Tapping **Book** calls `book_study_room(room_id)` directly and shows the existing "Room booked" card in-page (from [chat-ui.md § C2](chat-ui.md)) — no chat involved.

### Clinic section
| Part | Spec |
|---|---|
| Section label | "Clinic · next available" |
| Card, one row per free slot | `stethoscope` icon · "date, time" (14 / 600) + "doctor · type" (13 muted) · **Book** button |

Rows (today's are gone): **Sun 27 Sep, 09:00** — Dr. Tanaka · General Checkup · **Sun 27 Sep, 15:00** — Dr. Suzuki · Mental Health Counseling.

Tapping **Book** calls `book_clinic_appointment(slot_id)` and shows the "Appointment booked" card in-page.

Data: `get_study_rooms()`, `book_study_room(id)`, `get_clinic_slots()` (future + `available` only), `book_clinic_appointment(id)`.

---

## What changed from the chat-only plan

[chat-ui.md](chat-ui.md) still has the full chat spec (nudges, the "every tap sends a message" chat screens, states) — that's unchanged and is what you see after tapping **Ask**. What's different now:

- The **Dashboard's tiles and the bottom bar's Events/Courses/Bookings tabs open these dedicated pages**, not the chat. [chat-ui.md § C1, C7–C10](chat-ui.md) describe the *content* (same cards, same data) — reuse those card designs here, just without the surrounding chat bubbles.
- **Booking and submitting happen in-page**, directly, not through a conversation. The result card is the same design either way.
- The chat is now reached **only** by the Ask button, and is used for open-ended questions (the wow moments: the nudge, and the combined-answer feature) rather than for browsing.

## Build order addition

Before [chat-ui.md](chat-ui.md)'s step 5 (Tier 1 cards), first build:
1. Bottom bar + page header (shared across all 5 pages)
2. Events, Buses, Cafes (read-only lists — fastest to build)
3. Courses (to-dos + courses, wire up `submit_assignment`)
4. Bookings (rooms + clinic, wire up both `book_*` calls)

Then continue with the chat build order for the Ask flow.
