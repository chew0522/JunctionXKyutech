# Campus Concierge — design overview

One page that ties the whole design together: every PRD feature, where it lives, and every flow a student can take through the app. Use this to see the shape of the whole thing before diving into a single file.

**Canvas (all screens):** [Campus Concierge Chat UI](https://claude.ai/artifact/NtfYEffJuhq1eSvM8qeFjn) — press Play on any board to click through.

**The other files, one per part:** [dashboard.md](dashboard.md) · [page-events.md](page-events.md) · [page-buses.md](page-buses.md) · [page-cafes.md](page-cafes.md) · [page-courses.md](page-courses.md) · [page-bookings.md](page-bookings.md) · [chat-ui.md](chat-ui.md) · [nudges.md](nudges.md) · [tone.md](tone.md) · [layout.md](layout.md) · [design.md](design.md) (colours/fonts) · [navigation.md](navigation.md) (the map + demo script + demo facts).

---

## The shape of the app

```
                    ┌──────────┐
                    │   ASK    │────────► Chat (Welcome → conversation)
                    └──────────┘           the only door into the chat
Home ─── Events ─── Courses ─── Bookings
  │         ▲            ▲           ▲
  │         │            │           │
  ├─ Next bus ──────► Buses (drill-in, no bottom bar)
  ├─ Due next ─────────────┘
  ├─ Next event ───────┘
  └─ Quietest cafe ─► Cafes (drill-in, no bottom bar)
```

**5 top-level surfaces:** Dashboard (Home), Events, Courses, Bookings, Chat.
**2 drill-in pages:** Buses, Cafes (reached only from a Dashboard tile, no bottom-bar tab).
**Everywhere outside the chat:** a tap navigates or acts directly (books a room, submits an assignment) — it never sends a chat message. **Inside the chat:** every tap sends a message; see [navigation.md § The one rule](navigation.md).

---

## Features, by PRD tier

### Tier 0 — Proactive nudges
The single highest-leverage feature: the agent speaks first, unasked.

| | |
|---|---|
| **Where it shows** | Dashboard (compact card) and inside the Chat (full card) |
| **Connector** | `/nudges`, reusing `get_study_rooms`, `get_assignments`, `get_events` |
| **Design docs** | [nudges.md](nudges.md) (all 3 nudges + wording), [chat-ui.md § Nudge card](chat-ui.md#nudge-card-tier-0) (full card), [dashboard.md](dashboard.md) (compact card) |
| **The 3 nudges** | N1 Room taken ⭐ demo pick · N2 Assignment due tonight · N3 Event starting soon |

**Flow — Nudge on the Dashboard (the demo's must-land moment):**
1. Student is anywhere in the app; the Dashboard polls `/nudges` in the background.
2. A nudge appears on the Dashboard, unprompted: "Your usual room is taken."
3. Student taps **Book Room 201** → this runs the exact same booking flow as tapping Book on the Bookings page (see Tier 1 below) → the room is booked, no chat involved.
4. Or student taps **No thanks** → nudge dismisses, nothing happens.

**Flow — Nudge inside the Chat:**
1. Student has opened the Chat via Ask; a nudge card slides into the conversation.
2. Tapping its action button posts that label as a chat message ("Book Room 201") → the agent calls the tool → replies with a result card.

---

### Tier 1 — Event Information Center
| | |
|---|---|
| **Where it shows** | **EventsPage** (bottom-bar tab, or the "Next event" tile) is the primary surface; also answerable in Chat |
| **Connector** | `get_events()` |
| **Design docs** | [page-events.md](page-events.md) (page), [chat-ui.md § C7](chat-ui.md) (chat card) |

**Flow — Browse events (primary):**
1. Student taps **Events** in the bottom bar, or the Dashboard's "Next event" tile.
2. Page loads, calls `get_events()`, groups all 8 events by day, soonest first.
3. Student scrolls the list. View-only — no booking here.
4. Student taps a bottom-bar tab or the back chevron to leave.

**Flow — Ask in Chat (secondary):**
1. Student taps Ask → types or taps "What's on today?"
2. Agent calls `get_events`, replies in 1–2 sentences, shows the events card.

---

### Tier 1 — Library study room reservation
| | |
|---|---|
| **Where it shows** | **BookingsPage** (bottom-bar tab) is the primary surface; also reachable from the room nudge and from Chat |
| **Connectors** | `get_study_rooms()`, `book_study_room(room_id)` |
| **Design docs** | [page-bookings.md](page-bookings.md) (page, incl. nudge hand-off), [chat-ui.md § C2, C8](chat-ui.md) (chat cards) |

**Flow — Book a room (primary, in-page):**
1. Student taps **Bookings** in the bottom bar.
2. Page loads all 7 rooms; 4 show a **Book** button, 3 show "Taken".
3. Student taps **Book** on Study Room 201 → button disables → `book_study_room("room-201")` is called.
4. A "Room booked" result card appears in-page (room, location, seats) → student dismisses it.
5. That row updates in place to "Taken"; the "X free" count decrements. No chat involved at any point.

**Flow — Book from the nudge (shortcut into the same flow):**
1. Student taps **Book Room 201** on the room nudge, wherever it's shown (Dashboard or Chat).
2. The app navigates to BookingsPage **and immediately runs steps 3–5 above** — same code path, not a separate one.

**Flow — Ask in Chat (secondary):**
1. Student asks "Is there a study room free?" → agent shows the available-rooms card.
2. Student says "Book Room 201" → agent books it, shows the result card, all inside the conversation.

---

### Tier 1 — School bus tracker
| | |
|---|---|
| **Where it shows** | **BusPage** (drill-in from the "Next bus" tile only); also answerable in Chat |
| **Connector** | `get_bus_location()` |
| **Design docs** | [page-buses.md](page-buses.md) (page), [chat-ui.md § C3](chat-ui.md) (chat card) |

**Flow — Check the bus (primary):**
1. Student taps the Dashboard's **"Next bus"** tile.
2. Page loads, calls `get_bus_location()`, shows all 4 routes as cards: current stop, next stop, ETA, a Quiet/Moderate/Crowded pill.
3. View-only. Student taps the back chevron to return to the Dashboard (this page has no bottom bar of its own).

**Flow — Ask in Chat (secondary):**
1. Student asks "Next bus?" → agent shows the bus card for Campus Loop A.

---

### Tier 1 — Academic platform (courses, materials, submit)
| | |
|---|---|
| **Where it shows** | **CoursesPage** (bottom-bar tab, or the "Due next" tile) is the primary surface; also answerable in Chat |
| **Connectors** | `get_courses()`, `get_course_materials(course_id)`, `get_assignments(pending_only=True)`, `submit_assignment(id)` |
| **Design docs** | [page-courses.md](page-courses.md) (page, full submit + materials flow), [chat-ui.md § C9, C10](chat-ui.md) (chat cards) |

**Flow — View to-dos and submit (primary, in-page):**
1. Student taps **Courses** in the bottom bar, or the Dashboard's "Due next" tile.
2. Page loads the To-dos section (3 pending assignments, Problem Set 3 marked urgent) and the Courses section (3 courses).
3. Student taps the Problem Set 3 row → a confirm card appears: "Submit this assignment? You can't undo it." with **Submit it** / **Not yet**.
4. Student taps **Submit it** → `submit_assignment("assign-1")` is called → a success card shows ("Assignment submitted") → the row disappears from the to-do list, count updates to "2 not submitted".

**Flow — View course materials (primary, in-page):**
1. From the same Courses page, student taps a course row (e.g. CS301).
2. The view drills into that course's materials: "Consensus Algorithms" (Slides), "Raft Paper" (Reading).
3. Student taps back to return to the Courses list (not the Dashboard).

**Flow — Ask in Chat (secondary):**
1. Student asks "What are my courses?" → agent lists them, offers to show materials.
2. Student asks "Materials for CS301" → agent shows the materials card in the conversation.
3. Student says "Submit Problem Set 3" → agent shows a confirm step in-chat before calling the tool (tone.md's rule: never submit without asking first).

---

### Tier 1 — Built-in to-do list
Not a separate feature to design — it's the **To-dos section of CoursesPage** (above) plus the equivalent card in Chat. `todo_list()` derives from `get_assignments(pending_only=True)`; there is deliberately no personal-add path.

---

### Tier 2 — Cafe crowd
| | |
|---|---|
| **Where it shows** | **CafePage** (drill-in from the "Quietest cafe" tile only); also answerable in Chat |
| **Connector** | `get_cafe_crowd()` |
| **Design docs** | [page-cafes.md](page-cafes.md) (page), [chat-ui.md § C4](chat-ui.md) (chat card) |

**Flow — Check cafes (primary):**
1. Student taps the Dashboard's **"Quietest cafe"** tile.
2. Page loads, calls `get_cafe_crowd()`, sorts quietest-first, shows all 3 cafes with bars + word + wait time.
3. View-only. Back chevron returns to the Dashboard.

**Flow — Ask in Chat (secondary):**
1. Student asks "Where can I get coffee without a queue?" → agent recommends the Student Union, shows the full cafe card.

---

### Tier 2 — School clinic reservation
| | |
|---|---|
| **Where it shows** | **BookingsPage**, Clinic section (bottom-bar tab); also answerable in Chat |
| **Connectors** | `get_clinic_slots()`, `book_clinic_appointment(slot_id)` |
| **Design docs** | [page-bookings.md](page-bookings.md) (page), [chat-ui.md § C5](chat-ui.md) (chat cards) |

**Flow — Book a clinic slot (primary, in-page):**
1. Student taps **Bookings** in the bottom bar, scrolls to the Clinic section.
2. Today's slots are gone; two tomorrow slots show (09:00 Dr. Tanaka, 15:00 Dr. Suzuki), each with a **Book** button.
3. Student taps **Book** on the 09:00 slot → `book_clinic_appointment("slot-4")` is called.
4. An "Appointment booked" result card appears in-page → student dismisses it → that row disappears from the list.

**Flow — Ask in Chat (secondary):**
1. Student says "I need to see a doctor" → agent shows the available slots as tappable rows in the conversation → tapping one books it and shows the result card.

---

### Tier 2 — Student service assistance
No dedicated screen — this is the agent's general Q&A ability inside Chat. Any question not covered by a specific connector gets a plain, honest reply (see [tone.md](tone.md) for the voice and the "can't do that" wording for Tier 3 topics).

---

### Tier 2.5 — Cross-connector reasoning (the other "wow" moment)
| | |
|---|---|
| **Where it shows** | **Chat only** — this is the one feature that only makes sense as a conversation |
| **Connectors** | 3 or more of: `get_events`, `get_cafe_crowd`, `get_study_rooms`, `get_assignments` |
| **Design docs** | [chat-ui.md § C11](chat-ui.md) |

**Flow — Combined answer:**
1. Student taps Ask, then asks "Can I grab a coffee before the AI Workshop?"
2. Agent calls 4 connectors in one turn, replies "Yes — the Student Union is quiet right now," and shows a plan card: coffee now → the workshop at 15:00 → Study Room 201 free after → Problem Set 3 due tonight, each row tagged with which service it came from.
3. Student can tap a follow-up button on the card (e.g. "Book Room 201") to act on the plan directly from the chat.

---

### Tier 3 — Not built (registration, exam results, student ID)
No screen. If asked, the agent explains in one sentence that it can't help with that and points at what it can do instead ([tone.md](tone.md) has the exact wording). This is a deliberate, permanent limit — not a time-crunch cut.

---

## Every flow, in one list

For quick reference — every path a student can take, grouped by where it starts.

**From the Dashboard**
1. Open the app → see the Dashboard (greeting, nudge if any, 4 tiles, bottom bar).
2. Tap **Next bus** → BusPage → back chevron → Dashboard.
3. Tap **Due next** → CoursesPage (see Courses flows below).
4. Tap **Next event** → EventsPage (see Events flow above).
5. Tap **Quietest cafe** → CafePage → back chevron → Dashboard.
6. A nudge appears → tap its action → runs that feature's booking/reply flow directly from the Dashboard.
7. Tap **Ask** → Chat, Welcome state.

**From the bottom bar (visible everywhere except Chat)**
8. Tap **Home** → Dashboard.
9. Tap **Events** → EventsPage.
10. Tap **Courses** → CoursesPage.
11. Tap **Bookings** → BookingsPage.
12. Tap **Ask** (raised, centre) → Chat, Welcome state, from any page.

**Inside CoursesPage**
13. Tap a to-do row → confirm card → Submit it → success card → row removed.
14. Tap a to-do row → confirm card → Not yet → back to the list, nothing changed.
15. Tap a course row → materials drill-in → back chevron → Courses list (not Dashboard).

**Inside BookingsPage**
16. Tap Book on a free room → result card → row updates to Taken.
17. Tap Book on a clinic slot → result card → row removed.

**Inside the Chat (reached only via Ask)**
18. Welcome state → type or tap a chip → first message sent → conversation view.
19. A nudge fires mid-conversation → tap its action → agent carries out that action, replies with a result card.
20. Ask any general question → plain agent reply (Tier 2 "student service assistance").
21. Ask a combined question ("coffee before my 2pm class") → plan card, Tier 2.5.
22. Ask about registration/results/ID → agent explains it can't help, Tier 3.
23. A tool call fails → error bubble + "Try again" chip → resends the last message.
24. Tap the Chat header's **Home** button → back to the Dashboard.

---

## What's still open

These are called out in the individual files but worth repeating here:

- **BusPage and CafePage have no bottom bar** — confirm that's what you want (a lighter, one-level-in drill-in) versus making them full tabs.
- **The old chat-only screens** (Events, Rooms, Courses, Cafe, Clinic boards on the canvas) are kept only because their card designs are reused inside the new pages — say if you want them deleted from the canvas.
- **Demo script** in [navigation.md](navigation.md) walks through a suggested order for the pitch: browse → book → nudge → Ask → combined answer.
