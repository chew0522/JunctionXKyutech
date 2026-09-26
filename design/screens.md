# Screens — build spec for the coder

Every screen in the [canvas](https://claude.ai/artifact/NtfYEffJuhq1eSvM8qeFjn), top to bottom, with exact text, what each tap does, and where the data comes from. Build from this file; look up colours, fonts and sizes in [design.md](design.md), component specs in [layout.md](layout.md), nudge format in [nudges.md](nudges.md), agent wording in [tone.md](tone.md).

Device: **phone, portrait, 390 × 844**, light mode only. All example values are the demo data (`DEMO_NOW` = Sat 26 Sep 2026, 14:50).

---

## 0. Overview

| # | Screen | Canvas board | Type |
|---|---|---|---|
| A | Dashboard | Dashboard | Screen (route `/`) |
| B | Chat — Welcome state | 0 · Welcome | Chat screen with no messages |
| C | Chat — conversation | 1 – 5 | Chat screen with messages |
| D | To-do bottom sheet | To-do bottom sheet | Optional (see §D) |

**Only 2 routes:** Dashboard and Chat. Welcome is the chat screen when the message list is empty.

```
Dashboard ──(tile / nudge / ask bar)──► Chat
    ▲                                    │
    └────────────(Home button)───────────┘
```

**The one rule:** every chip, nudge button, card button and dashboard tile **sends its label as a user message** to `/chat`. One handler: `sendMessage(String text)`. Exceptions: the Home button (navigates) and the ask bar (opens chat, focuses the input).

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

## A. Dashboard

Canvas: **Dashboard**. Route `/`. Background `background`, side padding 16.

| # | Element | Content (demo) | Tap → |
|---|---|---|---|
| 1 | Header (no border) | Left: "Campus Concierge" (Bricolage 16). Right: "Sat 26 Sep · 14:50" (13 / 600, `textMuted`) | — |
| 2 | Greeting | "Good afternoon, Alex" (Bricolage 28 / 34) · "Here's your campus right now." (15, `textMuted`) | — |
| 3 | Nudge card (compact) | HEADS UP · "Your usual room is taken" (18) · "Study Room 204 is booked. Study Room 201 is free right now." (14) · no pills | `Book Room 201` → open Chat + send "Book Room 201" · `No thanks` → dismiss |
| 4 | Section label | "RIGHT NOW" (12 / 700, uppercase, `textMuted`) | — |
| 5 | Tile: Next bus | `bus` "Next bus" · **4 min** · Campus Loop A / at the Library | Chat + "Next bus" |
| 6 | Tile: Due next | `square-check` "Due next" · **23:59** · Problem Set 3 / today · 3 due | Chat + "Show my to-dos" |
| 7 | Tile: Next event | `calendar` "Next event" · **15:00** · AI Workshop / Building A, 101 | Chat + "What's on today?" |
| 8 | Tile: Quietest cafe | `coffee` "Quietest cafe" · 3 bars (1 filled) + **Low** · Student Union / 2 min wait | Chat + "Where can I get coffee without a queue?" |
| 9 | Ask bar (bottom, 20 px from edge) | Pill 56 px: `search` icon · "Ask Campus Concierge…" · round send button | Open Chat (Welcome state), focus the input |

**Tiles:** 2 × 2 grid, gap 12. Each: `surface`, 1 px `line`, radius 20, padding 14, min height 124. Big value = Bricolage 30 / 700 `primary`.

**Data:** `get_bus_location` (first route), `todo_list` (first item + count), `get_events(today)` (next upcoming), `get_cafe_crowd` (lowest crowd), nudge from `/nudges`. Greeting word from the time: before 12 "Good morning", before 18 "Good afternoon", else "Good evening".

**No time?** Skip the Dashboard: Home clears the chat and shows Welcome.

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

---

## D. To-do bottom sheet (optional)

Canvas: **To-do bottom sheet**. There's no header button for it any more; **build only if there's time**, opened from a "View all" link on the to-do card. Otherwise skip it — the to-do card in the chat already lists everything.

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
5. Trace line + result cards: Room booked → Bus → To-do list (needs backend change 2)
6. Thinking + error states
7. Tier 2 cards: Cafe crowds, Clinic slots, Appointment booked
8. Dashboard
9. Optional: to-do sheet, nudge collapse, animations

## Widgets to make

| Widget | Used by |
|---|---|
| `ChatHeader` | All chat screens |
| `Composer(chips)` | All chat screens |
| `UserBubble`, `AgentBubble`, `TimeDivider`, `TraceLine`, `ThinkingBubble` | Chat |
| `NudgeCard(nudge, compact)` | Chat, Dashboard (`compact: true`) |
| `ResultCard(icon, title, rows, buttons)` | Room booked, Appointment booked |
| `BusCard`, `TodoListCard`, `CafeCard`, `SlotPickerCard` | One per connector |
| `DashTile(icon, label, value, line1, line2, message)` | Dashboard |
| `Chip(label)` | Composer, Welcome, error |

Check before handing back: every tappable thing ≥ 44 × 44 · amber only on nudges · no emoji anywhere · every tap sends a message.
