# Chat UI — build spec for the coder

Every chat screen in the [canvas](https://claude.ai/artifact/NtfYEffJuhq1eSvM8qeFjn), top to bottom, with exact text, what each tap does, and where the data comes from. Build from this file; look up colours, fonts and sizes in [design.md](design.md), component specs in [layout.md](layout.md), nudge format in [nudges.md](nudges.md), agent wording in [tone.md](tone.md).

Device: **phone, portrait, 390 × 844**, light mode only. All example values are the demo data (`DEMO_NOW` = Sat 26 Sep 2026, 14:50).

---

## 0. Overview

| # | Screen | Canvas board | Type |
|---|---|---|---|
| B | Chat — Welcome state | 0 · Welcome | Chat screen with no messages |
| C | Chat — conversation | 1 – 10 | Chat screen with messages |
| D | To-do bottom sheet | To-do bottom sheet | **Extra — not in PRD** (see §D) |

**Features → screens** (every PRD §5 feature, Tier 0 – 2.5):

| Tier | PRD feature | Connector(s) | Screen |
|---|---|---|---|
| 0 | Proactive nudges | nudge engine (`/nudges`) | C1, C6 |
| 1 | Event Information Center | `get_events` | C7 in chat, **EventsPage** by default (see [page-events.md](page-events.md)) |
| 1 | Library study room reservation | `get_study_rooms`, `book_study_room` | C8 → C2 in chat, **BookingsPage** by default |
| 1 | School bus tracker | `get_bus_location` | C3 in chat, **BusPage** by default |
| 1 | Academic platform — courses, materials | `get_courses`, `get_course_materials` | C9 in chat, **CoursesPage** by default |
| 1 | Academic platform — submit assignment | `submit_assignment` | C10 in chat, **CoursesPage** by default |
| 1 | To-do list (from assignments) | `todo_list` | C3 in chat, **CoursesPage** by default |
| 2 | Cafe crowd | `get_cafe_crowd` | C4 in chat, **CafePage** by default |
| 2 | Clinic reservation | `get_clinic_slots`, `book_clinic_appointment` | C5 in chat, **BookingsPage** by default |
| 2 | Student service assistance | none (general Q&A) | Plain agent bubble |
| 2.5 | Cross-connector reasoning | 3+ of the above | C11 |
| 3 | Registration, exam results, student ID | none — out of scope | Agent says it can't (see [tone.md](tone.md)) |

**Routes: approved.** The app is more than one screen — Dashboard + 4 bottom-bar tabs, most of them real pages, not chat. See page-events.md, page-buses.md, page-cafes.md, page-courses.md, page-bookings.md for the app pages and [dashboard.md](dashboard.md) for Home. **This file covers only the chat itself**, which is reached **exclusively through the Ask button** in the bottom bar.

```
        Home   Events   ( ASK )   Courses   Bookings   ← bottom bar (see dashboard.md and the page-*.md files)
                           │
                           ▼
                  Chat — Welcome / conversation      ← this file
```

**In the chat, the one rule:** every chip, nudge button and card button **sends its label as a user message** to `/chat`. One handler: `sendMessage(String text)`. This rule is chat-only — Dashboard tiles and bottom-bar tabs navigate to pages instead (see the page-*.md files); they don't send chat messages.

**No chat history between sessions.** CLAUDE.md says no persistence — the history lives in memory (`_history` in `backend/main.py`) and resets on `/reset` or restart.

---

## Shared parts (build once, reuse everywhere)

### Chat header — 68 px
```
[home]  Campus Concierge
```
| Part | Spec |
|---|---|
| Container | `surface`, 1 px `line` bottom border, padding 0 × 16, gap 12 |
| Home button (left) | 44 × 44, outlined `line`, radius 12, `house` icon 20 px → `Navigator.pop` / go to Dashboard. Semantics label "Back to dashboard" |
| Title | "Campus Concierge", Bricolage Grotesque 18 / 700 |
| Right side | **Empty.** No logo, no subtitle, no other buttons |

### Composer — bottom of every chat screen
| Part | Spec |
|---|---|
| Container | `surface`, 1 px `line` top border, padding 12 top / 16 sides / 20 bottom |
| Chips row (optional, above the input) | Up to 3 suggestion chips, horizontal, gap 8 — see each screen |
| Input | 48 px, pill, `background` fill, 1 px `inputLine`, text 15. Placeholder "Ask about rooms, buses, events…" |
| Send button | 48 × 48 circle, `primary`, white `send` icon. 40% opacity when the input is empty |

### Message pieces
| Piece | Look | When |
|---|---|---|
| **Time divider** | Centred, 12 / 600, `textMuted`: "Today · 14:48" | First message, and when > 10 min since the last one |
| **User bubble** | Right, `primary` fill, white 15 / 22, padding 10 × 14, radius 18 18 **4** 18, max width 78% | Every user message (typed or tapped) |
| **Agent bubble** | Left, `surface` + 1 px `line`, 15 / 22, radius 18 18 18 **4**, max width 78% | Every agent text reply |
| **Trace line** | Left, no bubble, `wrench` icon 14 + text 12 `textMuted` | Above the reply, when the agent used tools. Text table in [layout.md](layout.md#3-trace-line-agent-used-a-tool) |
| **Nudge card** | Full width, amber — spec below | When `/nudges` returns one |
| **Result card** | Full width, `surface` + 1 px `line`, radius 20, padding 16 | After a tool result — one per screen below |

### Nudge card (Tier 0)
```
┌────────────────────────────────────────┐
│ [bell] HEADS UP    You didn't ask — I noticed │
│ {title}                                │
│ {body}                                 │
│ ( pill ) ( pill )                      │  optional
│ [ {action 1} ]   [ {action 2} ]        │
└────────────────────────────────────────┘
```
| Part | Spec |
|---|---|
| Card | `nudgeFill`, 1 px `nudgeLine`, radius 20, padding 16, gap 12 |
| Label row | `bell` 16 + "HEADS UP" (12 / 700, uppercase, +6% spacing, `nudge`) · right: "You didn't ask — I noticed" (12 / 600, `nudge`) |
| Title | Bricolage 21 / 26 / 700 |
| Body | 15 / 22 |
| Pills | 32 px, white, pill radius, icon 14 + text 13 / 600 |
| Buttons | Two equal, 44 px, radius 12, gap 8. Action 1: `nudge` fill, white text. Action 2: white, 1 px `nudgeButtonLine`, `nudge` text |
| After a tap | Card collapses to one line at 60% opacity: check icon + "{title} · You chose "{button}"" |
| Arrives | Slide up 250 ms + `HapticFeedback.lightImpact()`; auto-scroll to it |

---

## B. Chat — Welcome state

Canvas: **0 · Welcome**. Shown when the chat has no messages.

| # | Element | Content | Tap → |
|---|---|---|---|
| 1 | Header (no border, `background` colour) | [home] "Campus Concierge" (Bricolage 16) | Home → Dashboard |
| 2 | Title (centred) | "Welcome, Alex" — Bricolage 32 / 38 / 700 | — |
| 3 | Subtitle (centred, max width 290) | "Ask me anything about campus — rooms, buses, events and what's due." (15, `textMuted`) | — |
| 4 | Search bar | Pill 56 px, `surface`, 1 px `inputLine`: `search` icon · input "Ask anything about campus…" (16 px text) · 44 px round send | Send → first message |
| 5 | Chips (centred, wrap) | `What's on today?` · `Next bus` · `My to-dos` | Send that text |
| 6 | Footer | green dot + "Connected to 6 campus services" (13, `textMuted`) | — |

Content block is vertically centred between header and footer, gap 24.

**On first send:** welcome text fades out (200 ms), the search bar moves down into the composer (300 ms), the user bubble appears. If a nudge arrives while on Welcome, switch to the conversation view and show it as the first message.

---

## C. Chat — conversation screens

All use the shared header + composer. Each board is one moment of the demo.

### C1. Proactive nudge — canvas **1 · Proactive nudge**
| Order | Piece | Content |
|---|---|---|
| 1 | Divider | Today · 14:48 |
| 2 | User | What's on today? |
| 3 | Agent | Two today: the AI Workshop at 15:00 in Building A, Room 101, and the Career Fair at 17:00 in the Main Hall. |
| 4 | Divider | 14:50 |
| 5 | **Nudge** | "Your usual room is taken" · "Study Room 204 is booked. Study Room 201 is free right now — want me to book it?" · pills `map-pin` Library 2F, `users` 4 seats · whiteboard · buttons **Book Room 201** / **No thanks** |
| Composer chips | | `My to-dos` · `Next bus` · `Cafe crowd` |

Data: nudge N1 from `/nudges` ([nudges.md](nudges.md#n1--your-usual-room-is-taken--demo-pick)).

### C2. Room booking — canvas **2 · Agent takes action**
| Order | Piece | Content |
|---|---|---|
| 1 | Divider | Today · 14:51 |
| 2 | User | Book Room 201 |
| 3 | Trace | Checked study rooms · Booked Study Room 201 |
| 4 | Agent | Done. Study Room 201 is yours — it's on the 2nd floor, one floor down from your usual room. |
| 5 | **Card: Room booked** | Header: green check circle (32 px, `successFill` / `success`) + "Room booked" (Bricolage 18). Rows (40 px, key muted / value 600): **Room** Study Room 201 · **Where** Library, 2nd floor · **Seats** 4 · whiteboard. Buttons: `Next bus` · `Cafe crowd` (secondary: `primaryTint`, `primary` text) |

Data: `book_study_room("room-201")` → room fields from `rooms.json` (`name`, `building`, `floor`, `capacity`, `has_whiteboard`).

### C3. Bus + to-dos — canvas **3 · Bus + to-dos**
| Order | Piece | Content |
|---|---|---|
| 1 | Divider | Today · 14:52 |
| 2 | User | Next bus |
| 3 | Trace | Checked live bus location |
| 4 | **Card: Bus** | `bus` icon in 36 px `primaryTint` square · "Campus Loop A" (Bricolage 18) / "Moderately busy" (13 muted) · right: **4 min** (Bricolage 30, `primary`) / "to next stop" (12). Stop line: filled dot "Library · bus now" (indigo) ─── empty dot "Dormitory Block C · next". Footer: green dot "Live" |
| 5 | User | Show my to-dos |
| 6 | Trace | Checked your to-dos |
| 7 | **Card: To-do list** | `square-check` in 32 px `primaryTint` circle + "3 things due". Rows: empty checkbox · title (14 / 600) · course (13 muted) · due (right). Problem Set 3 – Consensus / CS301 Distributed Systems / **Today 23:59** (bold) · Lab 5 – Balanced Trees / CS210 Data Structures / Tue 18:00 · Homework 2 – Fourier Series / EE150 Signals and Systems / Wed 23:59 |

Data: `get_bus_location` (`route`, `current_stop`, `next_stop`, `eta_minutes`, `capacity_status` → "Empty / Moderately busy / Crowded"); `todo_list` (`task`, `due`, course from `get_courses`).

### C4. Cafe crowd — canvas **4 · Cafe crowd**
| Order | Piece | Content |
|---|---|---|
| 1 | Divider | Today · 14:53 |
| 2 | User | Where can I get coffee without a queue? |
| 3 | Trace | Checked cafe crowds |
| 4 | Agent | Go to the Student Union Coffee Bar — it's quiet, about a 2-minute wait. The Library cafe is packed right now. |
| 5 | **Card: Cafe crowds** | `coffee` circle + "Cafe crowds". One row per cafe, **quietest first**: name (14 / 600) + location (13 muted) · right: 3 bars + word (14 / 700) + "{n} min wait" (12). Student Union Coffee Bar — Low, 2 min · Engineering Building Kiosk — Medium, 6 min · Main Library Cafe — High, 12 min |

Bars: 5 × 8 / 12 / 16 px, radius 2, gap 2. Filled = `primary`, empty = `inputLine`. Low = 1, Medium = 2, High = 3. **Always show the word too.**

Data: `get_cafe_crowd` (`name`, `location`, `crowd_level`, `wait_minutes`).

### C5. Clinic booking — canvas **5 · Clinic booking**
| Order | Piece | Content |
|---|---|---|
| 1 | Divider | Today · 14:55 |
| 2 | User | I need to see a doctor |
| 3 | Trace | Checked clinic slots |
| 4 | Agent | Today's slots are gone. These are open tomorrow — tap one to book. |
| 5 | **Card: Clinic slots** (options) | `stethoscope` circle + "Clinic · Sun 27 Sep". One tappable row per free slot: 56 px, `primaryTint`, 1 px `primaryLine`, radius 14 · time (Bricolage 18, `primary`) · doctor (14 / 600) + type (13 muted) · "Book" (14 / 600, `primary`). **09:00** Dr. Tanaka, General Checkup · **15:00** Dr. Suzuki, Mental Health Counseling |
| 6 | User | Book 09:00 with Dr. Tanaka *(sent by tapping the row)* |
| 7 | Trace | Booked clinic appointment |
| 8 | **Card: Appointment booked** | Green check + "Appointment booked". Rows: **When** Sun 27 Sep, 09:00 · **Doctor** Dr. Tanaka · **Type** General Checkup |

Data: `get_clinic_slots` (future + `available` only) → `book_clinic_appointment(slot_id)`.

### C6. States — canvas **States + nudges 2 and 3**
| State | Look |
|---|---|
| Agent thinking | Agent bubble 44 px with three 8 px dots (`textMuted`, animate opacity in turn) |
| Error | Agent bubble "Sorry, I couldn't reach campus services just now. Want to try again?" + chip `Try again` (resends the last message) |
| Nudge 2 | "Problem Set 3 is due tonight" · "Problem Set 3 – Consensus (CS301) is due at 23:59 and isn't submitted yet." · pill `clock` Due 23:59 · 9 h left · **Show my to-dos** / **Got it** |
| Nudge 3 | "AI Workshop starts in 10 min" · "A hands-on session on LLM tool-calling and agent design." · pills `clock` 15:00, `map-pin` Building A, Room 101 · **Tell me more** / **Not going** |
| Nudge after a tap | One line, 60% opacity: check + "Your usual room is taken · You chose "Book Room 201"" |

### C7. Events — canvas **6 · Events**
| Order | Piece | Content |
|---|---|---|
| 1 | Divider | Today · 14:48 |
| 2 | User | What's on today? |
| 3 | Trace | Checked campus events |
| 4 | Agent | Two today — the AI Workshop starts in 12 minutes. |
| 5 | **Card: Campus events** | `calendar` circle + "Today · Sat 26 Sep". One row per event: time (Bricolage 18, `primary`, 52 px wide) · name (14 / 600) + "venue · organizer" (13 muted) · category (12 / 600 muted, right). **15:00** AI Workshop — Building A, Room 101 · CS Club — Workshop · **17:00** Career Fair — Main Hall · Career Services — Career. Buttons: `Tell me more` · `What's on tomorrow?` |

Data: `get_events(date)` (`name`, `time`, `venue`, `organizer`, `category`; `description` is used by the agent for "Tell me more").

### C8. Available rooms — canvas **7 · Available rooms**
| Order | Piece | Content |
|---|---|---|
| 1 | Divider | Today · 14:50 |
| 2 | User | Is there a study room free? |
| 3 | Trace | Checked study rooms |
| 4 | Agent | Four are free right now. Your usual room, 204, is taken — 201 is the closest match. |
| 5 | **Card: Available rooms** (options) | `door` circle + "Free now · 4 rooms". One **tappable row per free room** (same style as clinic slots: 56 px, `primaryTint`, radius 14): `door` icon in a white 36 px square · name (14 / 600) + "building floorF · n seats · whiteboard" (13 muted) · "Book". Rows: Study Room 201 — Library 2F · 4 seats · whiteboard · Study Room 202 — Library 2F · 6 seats · whiteboard · Study Room 205 — Library 3F · 2 seats · Group Pod B — Student Union 1F · 6 seats · whiteboard |

Tap a row → sends "Book Study Room 201" → agent calls `book_study_room` → **C2** (Room booked card).
Data: `get_study_rooms` filtered to `available: true`.

### C9. Courses + materials — canvas **8 · Courses + materials**
| Order | Piece | Content |
|---|---|---|
| 1 | Divider | Today · 14:57 |
| 2 | User | What are my courses? |
| 3 | Trace | Checked your courses |
| 4 | **Card: Your courses** (options) | `graduation-cap` circle + "Fall 2026 · 3 courses". One tappable row per course: cap icon · "CODE Name" (14 / 600) + "instructor · n due" (13 muted) · "Materials". CS301 Distributed Systems — Prof. Yamamoto · 1 due · CS210 Data Structures & Algorithms — Prof. Ito · 1 due · EE150 Signals and Systems — Prof. Kobayashi · 1 due |
| 5 | User | Materials for CS301 *(sent by tapping the row)* |
| 6 | Trace | Checked course materials |
| 7 | **Card: Course materials** | `book-open` circle + "CS301 · Week 4". One row per material: type icon in a 36 px square (`presentation` slides · `book-open` reading · `video` video) · title (14 / 600) + "Week n" (13 muted) · type label (12 / 600 muted, right). Consensus Algorithms — Week 4 — Slides · Raft Paper — Week 4 — Reading |

Data: `get_courses` (`code`, `name`, `instructor`, `semester`) + due count from `get_assignments(course_id, pending_only=True)`; `get_course_materials(course_id)` (`title`, `week`, `type`). Strip "(Slides)" / "(Reading)" from the title — the type label shows it. Rows are **not** tappable (no real files).

### C10. Submit assignment — canvas **9 · Submit assignment**
Submitting can't be undone, so the agent **asks first**.

| Order | Piece | Content |
|---|---|---|
| 1 | Divider | Today · 14:58 |
| 2 | User | Submit Problem Set 3 |
| 3 | **Card: Confirm** | `upload` circle + "Submit this assignment?" · "Marks it as handed in. You can't undo it." (14 muted) · rows **Assignment** Problem Set 3 – Consensus · **Due** Today 23:59 · CS301 · buttons `Submit it` (primary, `primary` fill) · `Not yet` (white, 1 px `line`) |
| 4 | User | Submit it |
| 5 | Trace | Submitted Problem Set 3 – Consensus |
| 6 | Agent | Done. Two left — Lab 5 is next, due Tue 18:00. |
| 7 | **Card: Assignment submitted** | Green check + "Assignment submitted". Rows: **Assignment** Problem Set 3 – Consensus · **Submitted** Today, 14:58 |

Data: `submit_assignment(assignment_id)` — mocked, **no file upload** (PRD §4). The confirm card is built by the agent before calling the tool; add to the system prompt: "Before `submit_assignment`, ask the student to confirm."

### C11. Combined answer (Tier 2.5) — canvas **10 · Combined answer**
The "agent connects the dots" moment (PRD §3, §9 criterion 3). One question → an answer built from **4 connectors**.

| Order | Piece | Content |
|---|---|---|
| 1 | User | Can I grab a coffee before the AI Workshop? |
| 2 | Trace | Checked events · cafe crowds · study rooms · your to-dos |
| 3 | Agent | Yes — the Student Union is quiet right now. Here's the rest of your afternoon. |
| 4 | **Card: Your afternoon** (plan) | `sparkle` circle + "Your afternoon". One row per step: time (Bricolage 18, `primary`, 52 px) · title (14 / 600) + detail (13 muted) · **source tag** (22 px pill, `background` fill, 12 / 600 muted). Rows: **Now** Coffee at Student Union — Quiet, about 2 min wait. Skip the Library cafe — 12 min. — `Cafes` · **15:00** AI Workshop — Building A, Room 101 — `Events` · **After** Study Room 201 — Free now · Library 2F · 4 seats — `Rooms` · **23:59** Problem Set 3 due — CS301 · not submitted yet — `To-dos`. Footer: `sparkle` 14 + "Combined from 4 campus services" (12 muted). Buttons: `Book Room 201` (primary) · `Show my to-dos` |

Source tags are what prove it's combining services — keep them. Tags come from the tool names in the `tools` list (backend change 2).

**How the card is built:** the agent calls several tools in one turn. The UI shows the plan card when the reply used **3 or more different tools**; rows come from the tool results in time order. Simplest version for 24 h: the agent returns the plan as plain text, and the app shows it in an agent bubble with the source tags underneath.

---

## D. To-do bottom sheet — extra, not in PRD

Canvas: **To-do bottom sheet**. Not in the PRD, and there's no header button for it any more. **Build only if the team agrees and there's time**, opened from a "View all" link on the to-do card. Otherwise skip it — the to-do card (C3) lists everything, and submitting is C10.

| Part | Spec |
|---|---|
| Scrim | `#1A1C20` at 45%, tap to close |
| Sheet | `surface`, top radius 24, padding 10 / 16 / 28, drag handle 40 × 5 `inputLine` |
| Title | "Your to-dos" (Bricolage 22) · "From your courses · 3 not submitted" (13 muted) · 44 px round close (`x`) |
| Rows | Radius 16, 1 px `line`, padding 14: checkbox · title · course · due |
| Due today row | `primaryTint` fill, indigo pill "Today 23:59", button `Mark submitted` → sends "Mark Problem Set 3 as submitted" |
| Footer | check + "1 submitted this week · Problem Set 2" |

---

## Build order (suggested)

1. `AppColors` + `ThemeData` + fonts ([design.md](design.md))
2. Chat screen: header, composer, user/agent bubbles, time divider, `sendMessage()`
3. Welcome state (empty chat)
4. **Nudge card** + polling `/nudges` every 15 s (needs backend change 1 in [nudges.md](nudges.md#for-the-coder-3-backend-changes-the-ui-needs))
5. Trace line + Tier 1 cards: Events → Available rooms → Room booked → Bus → To-do list → Courses → Materials → Confirm + Submitted (needs backend change 2)
6. Thinking + error states
7. Tier 2 cards: Cafe crowds, Clinic slots, Appointment booked
8. Tier 2.5: Combined answer card (or plain text + source tags)
9. Dashboard + the 5 app pages — see [dashboard.md](dashboard.md) and the 5 page-*.md files (build these **before** step 5 if going with pages instead of chat-only; each page-*.md has its own build notes)
10. Polish: nudge collapse, animations, to-do sheet (now optional either way — Courses page covers it)

Matches PRD §12: 0–3 h steps 1–3 · 3–6 h step 4 · 6–10 h step 5 · 10–13 h step 7 · 13–16 h step 8.

## Widgets to make

| Widget | Used by |
|---|---|
| `ChatHeader` | All chat screens |
| `Composer(chips)` | All chat screens |
| `UserBubble`, `AgentBubble`, `TimeDivider`, `TraceLine`, `ThinkingBubble` | Chat |
| `NudgeCard(nudge, compact)` | Chat (also used compact on the Dashboard) |
| `ResultCard(icon, title, rows, buttons)` | Room booked, Appointment booked, Assignment submitted, Confirm submit |
| `OptionsCard(icon, title, options)` — tappable rows, each sends a message | Available rooms, Clinic slots, Courses |
| `ListCard(icon, title, rows)` — lead + 2 lines + right label | Events, Materials, To-do list, Cafe crowds |
| `BusCard` | Bus |
| `PlanCard(steps with source tags)` | Combined answer (Tier 2.5) |
| `Chip(label)` | Composer, Welcome, error |

Check before handing back: every tappable thing ≥ 44 × 44 · amber only on nudges · no emoji anywhere · every tap sends a message.
