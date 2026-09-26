# Page: Bookings — build spec

**Canvas board:** BookingsPage · **Route:** bottom-bar tab #5 · **File:** `BookingsPage.dc.html`

One line: browse and book study rooms and clinic slots, both in-page — no chat involved. The other interactive page (alongside Courses), with a real write action.

## Entry points

| From | How |
|---|---|
| Bottom bar | Tap **Bookings** tab |
| Dashboard nudge | Tapping **"Book Room 201"** on the room nudge navigates here with that booking already completed (see "Nudge hand-off" below) |

## Data needed

| Connector | Called | Returns / does |
|---|---|---|
| `get_study_rooms()` | On page open | `id, name, building, floor, capacity, has_whiteboard, available` — all 7 rooms |
| `book_study_room(room_id)` | When student taps **Book** on a room row | Mutates `rooms.json`: sets that room's `available: false`. Returns `{success, message}` |
| `get_clinic_slots()` | On page open | `id, date, time, doctor, type, available` — filter to future dates + `available: true` client-side |
| `book_clinic_appointment(slot_id)` | When student taps **Book** on a slot row | Mutates `clinic_slots.json`: sets that slot's `available: false`. Returns `{success, message}` |

## Layout, top to bottom (default / list state)

```
┌──────────────────────────────────┐
│ (‹)  Bookings                     │  page header
├──────────────────────────────────┤
│ STUDY ROOMS · 4 FREE              │  section label
│ ┌──────────────────────────────┐ │
│ │ 🚪 Study Room 201     [Book]  │ │
│ │    Library, 2nd floor ·       │ │
│ │    4 seats · whiteboard       │ │
│ │ 🚪 Study Room 202     [Book]  │ │
│ │    Library, 2nd floor ·       │ │
│ │    6 seats · whiteboard       │ │
│ │ 🚪 Study Room 203      Taken  │ │
│ │    Library, 2nd floor ·       │ │
│ │    4 seats                    │ │
│ │           (4 more rows)        │ │
│ └──────────────────────────────┘ │
│ CLINIC · NEXT AVAILABLE           │
│ ┌──────────────────────────────┐ │
│ │ 🩺 Sun 27 Sep, 09:00  [Book]  │ │
│ │    Dr. Tanaka · General       │ │
│ │    Checkup                    │ │
│ │ 🩺 Sun 27 Sep, 15:00  [Book]  │ │
│ │    Dr. Suzuki · Mental Health │ │
│ │    Counseling                 │ │
│ └──────────────────────────────┘ │
├──────────────────────────────────┤
│ Home  Events  (ASK)  Courses  Bookings │  "Bookings" active
└──────────────────────────────────┘
```

## Header

| Part | Spec |
|---|---|
| Back button | 44×44, outlined `line`, radius 12, left-chevron. Goes to Dashboard |
| Title | "Bookings", Bricolage 20 / 700 |

## Section 1: Study rooms

**Label:** "STUDY ROOMS · {n} FREE" where n = count of `available: true` rooms. 12/700, uppercase, `textMuted`.

**Card:** `surface`, 1 px `line`, radius 20, one row per room (**all 7 shown**, not just available ones — taken rooms show as unavailable rather than being hidden, so the student can see the full picture), 1px `lineSoft` dividers.

### Row anatomy
| Element | Spec |
|---|---|
| Icon | `door`, 18px, in a 36×36 square, radius 10. `primaryTint`/`primary` if available, `background`/`textMuted` if taken (dimmed) |
| Name | 14 / 600, `text` (dimmed to `textMuted` if taken) |
| Detail line | "{building}, {floor as "2nd floor" etc.} · {capacity} seats{ · whiteboard if has_whiteboard}", 13 / 400, `textMuted` |
| Right side, if available | **Book** button: pill, `primary` fill, white text, 13/600, height 32, padding 0 16px |
| Right side, if taken | "Taken" text, `danger` colour, 12/600, no button |

### All rows (demo data — every room in `data/rooms.json`, file order)

| Name | Location | Seats | Whiteboard | Available? |
|---|---|---|---|---|
| Study Room 201 | Library, 2nd floor | 4 | Yes | ✅ Book |
| Study Room 202 | Library, 2nd floor | 6 | Yes | ✅ Book |
| Study Room 203 | Library, 2nd floor | 4 | No | ❌ Taken |
| Study Room 204 | Library, 3rd floor | 8 | Yes | ❌ Taken |
| Study Room 205 | Library, 3rd floor | 2 | No | ✅ Book |
| Group Pod A | Student Union, 1st floor | 10 | Yes | ❌ Taken |
| Group Pod B | Student Union, 1st floor | 6 | Yes | ✅ Book |

`floor` field is an integer (2, 3, 1) — format as "2nd floor" / "3rd floor" / "1st floor" for display.

## Section 2: Clinic

**Label:** "CLINIC · NEXT AVAILABLE" — 12/700, uppercase, `textMuted`.

**Card:** `surface`, 1 px `line`, radius 20, one row per **available, future** slot only (unlike rooms, taken/past slots are simply not shown — there's no value in listing a slot nobody can book), 1px `lineSoft` dividers.

### Row anatomy
| Element | Spec |
|---|---|
| Icon | `stethoscope`, 18px, in a 36×36 `primaryTint` square, radius 10 |
| Date + time | "{weekday} {D MMM}, {time}", 14 / 600, `text` |
| Detail line | "{doctor} · {type}", 13 / 400, `textMuted` |
| Right side | **Book** button, same style as room rows |

### Rows (demo data — `get_clinic_slots()` filtered to `date` ≥ today AND `available: true`)

`slot-1` (26 Sep 10:00) and `slot-3` (26 Sep 14:30) are filtered out — **today's slots are gone** (this is a deliberate mock-data property the demo relies on: it lets the "book tomorrow" flow always trigger). `slot-2` is also excluded (`available: false`).

| Date | Time | Doctor | Type |
|---|---|---|---|
| Sun 27 Sep | 09:00 | Dr. Tanaka | General Checkup |
| Sun 27 Sep | 15:00 | Dr. Suzuki | Mental Health Counseling |

## Interaction — step by step

### Opening the page
1. Page opens (tab tapped, or via nudge hand-off) → loading state → call `get_study_rooms()` and `get_clinic_slots()` in parallel → filter clinic slots to future+available → render both sections.

### Booking a room (in-page, no chat)
2. Student taps **Book** on an available room row (e.g. Study Room 201) → **disable that row's button immediately** (prevents double-tap) → call `book_study_room("room-201")`.
3. On success → show a **result card** at the top of the Study rooms section (or as a dismissible banner over the page — coder's choice): green check icon, "Room booked", rows "Room" → "Study Room 201", "Where" → "Library, 2nd floor", "Seats" → "4 · whiteboard". A **Done** button dismisses the card.
4. After dismissing → **that room's row updates in place**: button becomes "Taken" text, icon dims, section label count decrements ("4 free" → "3 free"). No page reload needed — update local state from the `book_study_room` response or by re-fetching `get_study_rooms()`.
5. If `book_study_room` returns `{success: false}` (e.g. someone else "booked" it first in a race): show that message as a small inline error under the row, re-enable its button by re-fetching the room list (its `available` may now be false anyway, in which case the row just updates to "Taken").

### Booking a clinic slot (in-page, no chat)
6. Same pattern as rooms: tap **Book** on a slot row → disable it → call `book_clinic_appointment(slot_id)` → on success, show a result card ("Appointment booked", rows "When" → date+time, "Doctor", "Type") → dismiss → **remove that row from the list** (a booked slot has nothing further to show, unlike a room which can show "Taken") → section label count decrements.

### Nudge hand-off (from the Dashboard)
7. When the student taps **Book Room 201** on the Dashboard's room nudge: navigate to this page **and immediately perform step 2–4 as if the student had tapped Book here** (call `book_study_room("room-201")`, show the result card, update the row). This keeps "one action, one result" true regardless of which screen the tap started on — the nudge is a shortcut into this exact flow, not a different code path.

### Leaving the page
8. Student taps a bottom-bar tab → navigate away.
9. Student taps the header's back chevron → navigate to Dashboard.

## States

| State | What shows |
|---|---|
| **Loading** | Both section labels shown, 4 skeleton rows under Study rooms, 2 under Clinic |
| **All rooms taken** (edge case, not in the demo data but handle it) | Section label "STUDY ROOMS · 0 FREE"; every row shows "Taken", no Book buttons |
| **No clinic slots available** | Clinic card replaced with: calendar icon + "No slots available right now." |
| **Error** (either connector fails on load) | Centered: "Couldn't load bookings." + `Try again` |
| **Booking in progress** (between tapping Book and the response) | That row's button shows a small spinner or "Booking…" text, disabled |
| **Booking failed** | Inline error text under the row (`danger` colour, 12/400), button re-enables |
| **Loaded** | Both sections as specified |

## Edge cases

- Tapping Book on two different rooms quickly: each row's own disable-on-tap handles this independently — no global lock needed, since each call is independent.
- `has_whiteboard: false`: the detail line simply omits "· whiteboard" rather than saying "no whiteboard".
- A room becoming unavailable between page load and tap (rare, single-user demo): handled by the `{success:false}` path in step 5.

## Widgets

| Widget | Notes |
|---|---|
| `BookingsPage` | Top-level page; owns both connector calls, both lists' local state, and the booking-in-progress flags |
| `RoomRow(name, building, floor, capacity, hasWhiteboard, available, onBook)` | — |
| `ClinicSlotRow(date, time, doctor, type, onBook)` | — |
| `BookingResultCard(icon, title, rows, onDone)` | Same visual design as the chat's "Room booked" / "Appointment booked" cards ([chat-ui.md § C2, C5](chat-ui.md)), reused here without chat bubbles |
| `BottomBar(active: "bookings")` | Shared, see [dashboard.md](dashboard.md) |
