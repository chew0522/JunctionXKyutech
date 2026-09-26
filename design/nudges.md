# Nudges (Tier 0)

A nudge is the agent speaking first. Every nudge must **offer an action**, not just inform — that's what makes it an agent instead of a notification.

Anatomy: **Trigger → Why now → Insight → Action → Exit.** See [layout.md](layout.md) for how the nudge card is drawn.

These match the rules already in `backend/nudges.py` and the mock data in `data/`. Demo clock: **`DEMO_NOW` = 26 Sep 2026, 14:50**.

At 14:50 **all three built rules fire**. The app shows them **one at a time, in this order**: N1 → N2 → N3. The next one appears only after the student taps a button on the current one.

---

## N1 — Your usual room is taken ⭐ demo pick

| | |
|---|---|
| **Trigger (when)** | The student's usual room (`USUAL_ROOM_ID = room-204`) is not available **and** another room is free |
| **Title** | Your usual room is taken |
| **Message** | Study Room 204 is booked. Study Room 201 is free right now — want me to book it? |
| **Info pills** | `map-pin` Library 2F · `users` 4 seats · whiteboard |
| **Action button(s)** | `Book Room 201` (primary) · `No thanks` (exit) |
| **Data source** | Facility / library booking system — `get_study_rooms` → `book_study_room` (`data/rooms.json`) |

**Why this is the demo pick**
- Lands **two** judging moments in one tap: the agent *speaks first* (Tier 0) **and** *takes an action* (booking).
- **Doesn't depend on the clock** — it only checks room availability, so it fires the same way every run.
- Tapping `Book Room 201` sends that message; the agent calls `book_study_room("room-201")` and shows the "Room booked" card.

**Demo reset:** `book_study_room` writes to `data/rooms.json` (room-201 becomes unavailable). Restore `rooms.json` before every run-through, or the nudge won't find a free room the second time.

---

## N2 — Assignment due tonight

| | |
|---|---|
| **Trigger (when)** | A pending (unsubmitted) assignment is due in ≤ 12 h |
| **Title** | Problem Set 3 is due tonight |
| **Message** | Problem Set 3 – Consensus (CS301 Distributed Systems) is due at 23:59 and isn't submitted yet. |
| **Info pills** | `clock` Due 23:59 · 9 h left |
| **Action button(s)** | `Show my to-dos` (primary) · `Got it` (exit) |
| **Data source** | Learning management system — `get_assignments` (`data/assignments.json`) |

`Show my to-dos` → agent calls `todo_list` → to-do list card with all 3 pending assignments.

---

## N3 — Event starting soon

| | |
|---|---|
| **Trigger (when)** | An event today starts in ≤ 15 min |
| **Title** | AI Workshop starts in 10 min |
| **Message** | It's at Building A, Room 101 — hands-on session on LLM tool-calling and agent design. |
| **Info pills** | `clock` 15:00 · `map-pin` Building A, Room 101 |
| **Action button(s)** | `Tell me more` (primary) · `Not going` (exit) |
| **Data source** | Announcements portal — `get_events` (`data/events.json`) |

Note: at 14:50 this fires almost immediately. If the demo runs slowly and passes 15:00, it stops firing — that's fine, it's third in the queue.

---

## Idea — not built yet (roadmap / only if time allows)

| Nudge | Trigger | Message | Buttons | Data |
|---|---|---|---|---|
| Bus arriving | Student's usual bus is ≤ 5 min from their stop | Campus Loop A reaches the Library in 4 min. | `Show route` · `Got it` | `get_bus_location` |
| Cafe quieter now | Usual cafe crowd drops to low | Student Union Coffee Bar is quiet — 2 min wait. | `Directions` · `Got it` | `get_cafe_crowd` |

---

## Rules for every nudge

- **Title + max 2 sentences.** Title = what's happening. Message = the detail or offer.
- **Max 2 buttons.** One primary action, one exit. Never zero actions.
- **Every button sends a message.** Tapping `Book Room 201` posts "Book Room 201" into the chat as the user, and the agent replies normally. See [navigation.md](navigation.md).
- **One nudge at a time.** Never stack two nudge cards. Queue the rest.
- **Same nudge fires once.** After either button, that nudge doesn't fire again this session.
- **No emoji in nudge text.** The card's bell icon and amber colour already say "heads up".

## For the coder: nudge format

`backend/nudges.py` currently returns plain strings with emoji. To draw the nudge card, `/nudges` needs to return objects:

```json
{
  "nudges": [
    {
      "id": "room-usual-taken",
      "title": "Your usual room is taken",
      "body": "Study Room 204 is booked. Study Room 201 is free right now — want me to book it?",
      "pills": ["Library 2F", "4 seats · whiteboard"],
      "actions": ["Book Room 201", "No thanks"]
    }
  ]
}
```

- `id` lets the app remember which nudges were already shown (fire once).
- Return them in priority order (room → assignment → event); the app shows the first one not yet shown.
- `pills` is optional — skip it if short on time.
