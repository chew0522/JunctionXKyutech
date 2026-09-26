# Navigation

**A real multi-page app, not a chat-only funnel.** Dashboard (Home) + 4 bottom-bar tabs, most of them dedicated pages. The chat is reached **only** through the raised **Ask** button — it's not where the app starts, and tiles/tabs don't route into it. Full page specs: [pages.md](pages.md) and [dashboard.md](dashboard.md). Full chat spec: [chat-ui.md](chat-ui.md).

```
                  Home   Events   ( ASK )   Courses   Bookings   ← bottom bar
                    │       │     opens Chat    │         │
                    ▼       ▼                   ▼         ▼
              Dashboard  EventsPage         Chat      CoursesPage
                                          (Welcome →       │
                                          conversation)  BookingsPage
Dashboard tiles: Next bus ──► BusPage        Quietest cafe ──► CafePage
                 Due next ──► CoursesPage
                 Next event ──► EventsPage
```

## The one rule, and where it applies

**Inside the chat only:** every chip, nudge button and card button **sends its label as a message**. One handler: `sendMessage(String text)`.

| Tap (in chat) | What gets sent |
|---|---|
| Chip `Next bus` | "Next bus" |
| Nudge button `Book Room 201` | "Book Room 201" |
| Card button `Show my to-dos` | "Show my to-dos" |

**Outside the chat** (Dashboard, Events, Courses, Bookings), taps **navigate** or **call a connector directly** — they never send a chat message:

| Surface | Tap | Does |
|---|---|---|
| Dashboard | A tile | Navigates to that page ([dashboard.md](dashboard.md)) |
| Dashboard, bottom bar | The nudge's action button | Navigates to the relevant page (e.g. Bookings) and completes the action there |
| Events / Bookings | A row's action (Book) | Calls the connector (`book_study_room`, `book_clinic_appointment`) directly and shows the result card in-page |
| Courses | A to-do row | Opens the submit-confirmation flow in-page |
| Bottom bar | Home / Events / Courses / Bookings | Navigates to that tab |
| Bottom bar | **Ask** | Opens the Chat (Welcome state) — the only door into the chat |

Why split it this way: browsing and simple actions (view a list, book a free room) are faster as a normal app; the chat is reserved for open-ended questions and the two "wow" moments — the unprompted nudge and the combined-answer feature — where a conversation genuinely adds something a list can't.

## Screens and surfaces

| Surface | How you get there | How you leave | Contents |
|---|---|---|---|
| **Dashboard (Home)** | App launch, or the Home tab | Tap a tile or a bottom-bar tab | Nudge + 4 live tiles + bottom bar — [dashboard.md](dashboard.md) |
| **Events** | Bottom bar, or the "Next event" tile | Bottom bar, or the back chevron | All events, by day — [pages.md § 1](pages.md) |
| **Buses** | The "Next bus" tile only | Back chevron | All bus routes, live — [pages.md § 2](pages.md) |
| **Cafes** | The "Quietest cafe" tile only | Back chevron | All cafes, quietest first — [pages.md § 3](pages.md) |
| **Courses** | Bottom bar, or the "Due next" tile | Bottom bar, or the back chevron | To-dos + courses + materials + submit — [pages.md § 4](pages.md) |
| **Bookings** | Bottom bar, or a room/clinic nudge action | Bottom bar, or the back chevron | Study rooms + clinic, book in-page — [pages.md § 5](pages.md) |
| **Chat — Welcome state** | The **Ask** button | Send a message, or a nudge fires | Welcome, search bar, 3 chips |
| **Chat — conversation** | First message sent | Chat header's Home button → Dashboard | Everything in [chat-ui.md](chat-ui.md) |

**Don't add** a settings page, profile page, or login — everything above is it.

## Welcome state (inside the Chat, after tapping Ask)

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

## Dashboard, Events, Courses, Bookings, Buses, Cafes

Full specs: [dashboard.md](dashboard.md) (Home + the bottom bar) and [pages.md](pages.md) (the other 5). Short version: it's a **glance at campus right now**, not a grid of app-launcher icons — every tile and row is live info, and tapping one takes you straight to that page or does the action, no conversation needed. The **Ask** button is the only door into the chat.

If there's no time to build the pages: fall back to the chat-only plan in [chat-ui.md](chat-ui.md), where every tile and tab sends a message into the chat instead.

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

| # | Moment | Student does | App/agent does | Page or canvas screen |
|---|---|---|---|---|
| 1 | Open | Opens the app | Dashboard: greeting, live tiles, bottom bar | Dashboard |
| 2 | Browse | Taps the **Events** tab | Full events list, AI Workshop first | EventsPage |
| 3 | Book | Taps **Bookings**, then `Book` on Study Room 201 | "Room booked" shown in-page, no chat | BookingsPage |
| 4 | **Nudge** ⭐ | Nothing — a nudge appears on the Dashboard | Amber card: "Your usual room is taken" | Dashboard |
| 5 | **Ask** ⭐ | Taps the raised **Ask** button | Chat opens on Welcome | Chat: 0 |
| 6 | **Combined answer** ⭐ | Types "Can I grab a coffee before the AI Workshop?" | Plan card pulling from 4 services | Chat: 10 · Combined |
| 7 | Close | Taps Home (chat header) | Back to the Dashboard | Dashboard |

**Presenter tip:** show the app first (steps 1–3) to prove it's a real, fast tool — then land the **nudge** (step 4) and the **Ask → combined answer** (steps 5–6) as the two moments that prove it's an *agent*, not just another campus app.

Alternate flow, if the team keeps the chat-only fallback instead of the 5 pages: use the older script — see chat-ui.md's build order note.

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
