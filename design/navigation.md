# Navigation

**Everything happens in one screen: Chat.** It opens on a Welcome state, and a Home button leads back to a Dashboard. No tabs, no bottom nav, no menu, no login. This is the product idea itself — the student never has to know *where* something lives (unlike a typical campus portal's grid of tiles). They just ask.

```
App launch
   │
   ▼
┌─────────────────────────────┐
│  Chat screen (only route)   │◄─────────────┐
│                             │              │
│  header ─ [To-do] button ───┼──► To-do bottom sheet ── swipe down / tap outside
│                             │
│  messages                   │
│   └ card buttons ───────────┼──► send a message (stay on Chat)
│                             │
│  chips ─────────────────────┼──► send a message (stay on Chat)
│  input + send ──────────────┼──► send a message (stay on Chat)
└─────────────────────────────┘
```

## The one rule: every tap is a message

Chips, nudge buttons, and card buttons **all do the same thing**: post their label into the chat as a user message, then the agent replies.

| Tap | What gets sent |
|---|---|
| Chip `Next bus` | "Next bus" |
| Nudge button `Book Room 201` | "Book Room 201" |
| Card button `Show my to-dos` | "Show my to-dos" |

Why:
- **The coder writes one handler**, not one per button.
- **Judges see every step in the chat history.** Nothing happens off-screen.
- The agent (DeepSeek) already knows the context from the conversation, so "Book Room 201" after a room nudge just works.
- **Nudge text must reach the agent.** When a nudge is shown, add it to the chat history as an assistant message, so the agent knows what "Book Room 201" refers to.

Exceptions (views, not actions): the **Home** button opens the Dashboard, and the **View all** link on the to-do card opens the to-do sheet.

## Screens and surfaces

| Surface | How you get there | How you leave | Contents |
|---|---|---|---|
| **Dashboard** | App launch, or Home button (top left of every chat screen) | Tap a tile, the nudge, or the ask bar | Nudge + 4 live tiles + ask bar |
| **Chat — Welcome state** | Opening the chat with no messages | Send a message, or a nudge fires | Welcome, search bar, 3 chips |
| **Chat** | First message sent | Home button → Dashboard | Everything |
| **To-do sheet** | "View all" link on the to-do card | Swipe down, tap outside, or close button | Pending assignments from `todo_list`: title, course, due date. View only (optional: a `Mark submitted` button that sends "Mark Problem Set 3 as submitted"). |

That's all. **Don't add** a settings page, profile page, or event detail page — the agent answers in the chat.

## First page: Welcome

The chat opens on a **Welcome** state (canvas board "0 · Welcome"). It's the same Chat screen with no messages yet — not a separate route.

| Element | Behaviour |
|---|---|
| **Home button** (top left) | Goes back to the **Dashboard**. `aria-label="Back to dashboard"` |
| "Welcome, {username}" | Centred. Username comes from the app (mock: a fixed demo name) |
| Subtitle | "Ask me anything about campus — rooms, buses, events and what's due." |
| **Search bar** (round, pill) | The student types here. Sending the first message switches to the chat view |
| 3 chips below | `What's on today?` · `Next bus` · `My to-dos` — tap = send that message |

**What happens next:**
1. Student sends a message (typed or chip) → Welcome fades out, the chat view appears with the message at the bottom, and the search bar moves down to become the composer.
2. If a nudge fires while still on Welcome → switch to the chat view and show the nudge as the first message.
3. The Flutter app polls `/nudges` every 15 s, so the first nudge appears within ~15 s (see [nudges.md](nudges.md)).

## Dashboard

Where the Home button goes (canvas board "Dashboard"). It's a **glance at campus right now**, not a grid of app shortcuts — every tile is live info, and tapping it asks the agent.

| Element | Tap → |
|---|---|
| Header: logo left, "Sat 26 Sep · 14:50" right | — |
| "Good afternoon, {username}" + "Here's your campus right now." | — |
| **Current nudge** (amber, compact) — same nudge as the chat | `Book Room 201` → opens chat and sends "Book Room 201" |
| Tile **Next bus** — 4 min, Campus Loop A at the Library | Opens chat, sends "Next bus" |
| Tile **Due next** — 23:59, Problem Set 3, 3 due | Opens chat, sends "Show my to-dos" |
| Tile **Next event** — 15:00, AI Workshop, Building A 101 | Opens chat, sends "What's on today?" |
| Tile **Quietest cafe** — Low, Student Union, 2 min | Opens chat, sends "Where can I get coffee without a queue?" |
| **Ask bar** at the bottom | Opens chat on the Welcome state |

Same rule as everywhere: **every tap becomes a chat message**. The dashboard has no logic of its own — it calls the same connectors as the nudge engine (`get_bus_location`, `todo_list`, `get_events`, `get_cafe_crowd`).

If there's no time to build it: Home just clears the chat and returns to Welcome.

## Message states (what the student sees while waiting)

| State | What shows |
|---|---|
| **Sending** | User bubble appears immediately (don't wait for the server) |
| **Agent thinking** | Agent bubble with 3 animated dots, left-aligned |
| **Agent using a tool** | Trace line from the `tools` list in the `/chat` response: "Checked study rooms · Booked Study Room 201" |
| **Reply** | Text bubble and/or result card replaces the dots |
| **Error** (server down, API fails) | Agent bubble: "Sorry, I couldn't reach campus services. Try again?" + `Try again` chip. Never show a raw error. |
| **Nudge arrives** | Card slides up from the bottom of the list (250 ms) + light haptic. Auto-scroll to it. |

## Scrolling and keyboard

- New messages auto-scroll the list to the bottom.
- If the student has scrolled up to read history, **don't** auto-scroll; show a small "↓ New message" pill instead.
- When the keyboard opens, the composer rides on top of it and the list shrinks (Flutter: `Scaffold` with `resizeToAvoidBottomInset: true`).

## Demo flow (3 min, for the pitch)

Demo clock is fixed at **Sat 26 Sep 2026, 14:50** (`DEMO_NOW` in `backend/nudges.py`). Exact names and numbers: see [Demo facts](#demo-facts) below.

**Before each run:** restore `data/rooms.json` (booking changes it) and call `POST /reset` to clear the chat history.

| # | Moment | Student does | Agent does | Canvas screen |
|---|---|---|---|---|
| 1 | Open | Opens the chat | Welcome page: "Welcome, {username}" + search bar + chips | 0 |
| 2 | Ask | Taps `What's on today?` | "AI Workshop at 15:00 in Building A, Room 101, and the Career Fair at 17:00 in the Main Hall." | 1 (top) |
| 3 | **Nudge** ⭐ | Nothing — waits ≤ 15 s | Amber card: "Your usual room is taken" | 1 |
| 4 | **Action** ⭐ | Taps `Book Room 201` | Trace line → "Room booked" card: Study Room 201, Library 2F | 2 |
| 5 | Ask | Taps `Next bus` | Bus card: Campus Loop A at the Library, 4 min | 3 (top) |
| 6 | **Nudge 2** | Nothing | Amber card: "Problem Set 3 is due tonight" | — |
| 7 | To-dos | Taps `Show my to-dos` | To-do card: 3 assignments, Problem Set 3 first | 3 (bottom) |

Optional if time allows:
- "Where can I get coffee without a queue?" → cafe card: Student Union Coffee Bar, low, 2 min (canvas 4)
- "I need to see a doctor" → clinic slot card → tap 09:00 → "Appointment booked" (canvas 5)
- Tap Home → Dashboard shows the whole campus at a glance

**Presenter tip:** at step 3, stop talking and let the nudge appear on its own. Then say: "I didn't ask anything — the agent noticed."

## Demo facts

**Single source of truth — taken from `data/` and `backend/nudges.py`.** Mockups, sample replies and the pitch script use exactly these values. If the coder changes the data, update this table and the canvas.

Demo clock: **Saturday 26 Sep 2026, 14:50** (`DEMO_NOW`). The student is at the Library.

| Feature | Value (from mock data) |
|---|---|
| App name | Campus Concierge |
| Demo user name | Alex (placeholder) |
| Header | Home button (left) · "Campus Concierge". Nothing on the right. Welcome footer: "Connected to 6 campus services" |
| **Usual room (nudge)** | **Study Room 204** · Library 3F · 8 seats — **booked** (`room-204`) |
| **Room offered + booked** | **Study Room 201** · Library 2F · **4 seats · whiteboard** (`room-201`) |
| Events today | **AI Workshop**, 15:00, Building A, Room 101 · **Career Fair**, 17:00, Main Hall |
| Bus | **Campus Loop A** — now at **Library**, next stop **Dormitory Block C**, **4 min**, moderately busy |
| Assignments / to-dos | **Problem Set 3 – Consensus** (CS301) due **today 23:59** · **Lab 5 – Balanced Trees** (CS210) due **Tue 29 Sep 18:00** · **Homework 2 – Fourier Series** (EE150) due **Wed 30 Sep 23:59** |
| Cafes | Main Library Cafe **high**, 12 min wait · Student Union Coffee Bar **low**, 2 min · Engineering Kiosk **medium**, 6 min |
| Clinic slots (tomorrow) | **Sun 27 Sep 09:00** Dr. Tanaka, General Checkup (`slot-4`) · **15:00** Dr. Suzuki, Mental Health Counseling (`slot-5`) |
