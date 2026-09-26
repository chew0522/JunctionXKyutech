# Navigation

**There is one screen: Chat.** No tabs, no bottom nav, no menu, no login. This is the product idea itself — the student never has to know *where* something lives (unlike a typical campus portal's grid of tiles). They just ask.

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

Exception: the header **To-do** button opens the to-do sheet directly (it's a view, not an action).

## Screens and surfaces

| Surface | How you get there | How you leave | Contents |
|---|---|---|---|
| **Chat** | App launch | — | Everything |
| **To-do sheet** | Header to-do button, or card link "View all" | Swipe down, tap outside, or close button | Pending assignments from `todo_list`: title, course, due date. View only (optional: a `Mark submitted` button that sends "Mark Problem Set 3 as submitted"). |

That's all. **Don't add** a settings page, profile page, or event detail page — the agent answers in the chat.

## First launch

1. Chat opens with **one agent greeting** + 3 chips:
   > Hi! I'm your campus concierge. I can check events, book study rooms, track the bus, and show what's due. What do you need?
   >
   > [What's on today?] [Next bus] [My to-dos]
2. The Flutter app polls `/nudges` every 15 s, so the first nudge appears within ~15 s (see [nudges.md](nudges.md)).

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

Demo clock is fixed at **Sat 26 Sep 2026, 14:50** (`DEMO_NOW` in `backend/nudges.py`). Exact names and numbers: see [README.md § Demo facts](README.md#demo-facts).

**Before each run:** restore `data/rooms.json` (booking changes it) and call `POST /reset` to clear the chat history.

| # | Moment | Student does | Agent does | Canvas screen |
|---|---|---|---|---|
| 1 | Open | Opens app | Greeting + chips | — |
| 2 | Ask | Taps `What's on today?` | "AI Workshop at 15:00 in Building A, Room 101, and the Career Fair at 17:00 in the Main Hall." | 1 (top) |
| 3 | **Nudge** ⭐ | Nothing — waits ≤ 15 s | Amber card: "Your usual room is taken" | 1 |
| 4 | **Action** ⭐ | Taps `Book Room 201` | Trace line → "Room booked" card: Study Room 201, Library 2F | 2 |
| 5 | Ask | Taps `Next bus` | Bus card: Campus Loop A at the Library, 4 min | 3 (top) |
| 6 | **Nudge 2** | Nothing | Amber card: "Problem Set 3 is due tonight" | — |
| 7 | To-dos | Taps `Show my to-dos` | To-do card: 3 assignments, Problem Set 3 first | 3 (bottom) |

Optional if time allows: "Where can I get coffee without a queue?" → cafe card: Student Union Coffee Bar, low, 2 min.

**Presenter tip:** at step 3, stop talking and let the nudge appear on its own. Then say: "I didn't ask anything — the agent noticed."
