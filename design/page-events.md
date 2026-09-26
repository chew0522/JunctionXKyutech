# Page: Events — build spec

**Canvas board:** EventsPage · **Route:** bottom-bar tab #2 · **File:** `EventsPage.dc.html`

One line: a scrollable list of every campus event, grouped by day, soonest first. View-only — no booking on this page.

## Entry points

| From | How |
|---|---|
| Bottom bar | Tap **Events** tab (always visible except in Chat) |
| Dashboard | Tap the **"Next event"** tile |

Both entry points land on the **same page** — there's no separate "detail" state per entry point.

## Data needed

| Connector | Called | Returns |
|---|---|---|
| `get_events()` | On page open, no args (get all, not just today) | `id, name, description, category, date, time, venue, organizer` — see full list below |

No mutation connectors — this page never writes data.

## Layout, top to bottom

```
┌──────────────────────────────────┐
│ (‹)  Events                      │  page header, 68 px
├──────────────────────────────────┤
│ TODAY · SAT 26 SEP                │  section label
│ ┌──────────────────────────────┐ │
│ │ 15:00  AI Workshop    Workshop│ │  card, one row per event
│ │        Building A, Rm 101 ·   │ │
│ │        Computer Science Club  │ │
│ ├──────────────────────────────┤ │
│ │ 17:00  Career Fair     Career │ │
│ │        Main Hall ·            │ │
│ │        Career Services Office │ │
│ └──────────────────────────────┘ │
│ SUN 27 SEP                        │
│ ┌──────────────────────────────┐ │
│ │ 07:30  Morning Yoga  Wellness │ │
│ │ ...                            │ │
│ └──────────────────────────────┘ │
│         (scrolls for more)        │
├──────────────────────────────────┤
│ Home  Events  (ASK)  Courses  Bookings │  bottom bar, "Events" active
└──────────────────────────────────┘
```

## Header

| Part | Spec |
|---|---|
| Back button | 44×44, outlined `line`, radius 12, left-chevron. Goes to Dashboard |
| Title | "Events", Bricolage 20 / 700 |
| No right-side element | — |

## Section labels

- First group whose date = today: **"TODAY · {weekday} {D MMM}"**, e.g. "TODAY · SAT 26 SEP"
- Every other group: **"{weekday} {D MMM}"**, e.g. "SUN 27 SEP"
- Style: 12 / 700, uppercase, +6% letter-spacing, `textMuted`
- Groups are sorted by date ascending; **past days are never shown** (filter out `date < today`)

## Event card (one per day-group)

`surface` background, 1 px `line` border, radius 20, no internal padding on the container — each row has its own padding so dividers run edge-to-edge inside the card.

### Row anatomy
| Element | Spec |
|---|---|
| Time | Bricolage Grotesque 16 / 700, `primary`, fixed width 52 px so all times align in a column |
| Name | Figtree 15 / 600, `text`, 1 line, ellipsis if too long |
| Detail line | "{venue} · {organizer}", Figtree 13 / 400, `textMuted`, may wrap to 2 lines |
| Category pill | Right-aligned, `primaryTint` fill, `primary` text, 11 / 700, pill radius, padding 4×8, height 22 |
| Row padding | 14px vertical, 16px horizontal (card's own padding) |
| Divider | 1px `lineSoft` between rows, none after the last row in a card |

### All rows (demo data — every event in `data/events.json`)

| Date | Time | Name | Venue | Organizer | Category |
|---|---|---|---|---|---|
| Sat 26 Sep | 15:00 | AI Workshop | Building A, Room 101 | Computer Science Club | Workshop |
| Sat 26 Sep | 17:00 | Career Fair | Main Hall | Career Services Office | Career |
| Sun 27 Sep | 07:30 | Morning Yoga | Sports Complex, Studio 2 | Campus Wellness Center | Wellness |
| Sun 27 Sep | 13:00 | Robotics Showcase | Engineering Building, Atrium | Robotics Society | Showcase |
| Mon 28 Sep | 10:00 | Guest Lecture: Climate Data Modeling | Building B, Lecture Hall 3 | Environmental Science Department | Lecture |
| Mon 28 Sep | 12:00 | International Food Festival | Central Courtyard | International Students Association | Culture |
| Tue 29 Sep | 18:00 | Midterm Study Jam | Library, 3rd Floor | Student Union | Academic |
| Wed 30 Sep | 19:00 | Startup Pitch Night | Innovation Hub, Auditorium | Entrepreneurship Club | Career |

Sort within a day: by `time` ascending. Sort days: by `date` ascending.

## Interaction — step by step

1. **Page opens** (tab tapped or tile tapped) → show the loading state (below) → call `get_events()` → group by date → render.
2. **Student scrolls** → standard vertical scroll, list can be long (8+ events); no pagination needed for the demo.
3. **Student taps a row** → **no required behavior for the demo.** Optional, only if time allows: open a small detail sheet showing the full `description` field (not otherwise shown in the list) with a "Got it" close button. If not built, rows are visually static (no tap ripple needed, but don't remove the row's semantics — screen readers should still read it as a listitem, not a button, if it's not tappable).
4. **Student taps a bottom-bar tab** → navigate away; this page's scroll position does not need to persist.
5. **Student taps the back chevron** → navigate to Dashboard.

## States

| State | What shows |
|---|---|
| **Loading** (first open, before `get_events()` returns) | 3 skeleton rows: grey rounded rectangles in place of time/name/detail, shimmer optional. Keep the header and bottom bar visible |
| **Empty** (no events at all — shouldn't happen with this mock data, but handle it) | Centered: calendar icon (32px, `textMuted`) + "No events right now." (15, `textMuted`) |
| **Error** (`get_events()` fails / times out) | Centered: "Couldn't load events." (15) + a `Try again` button (pill, `primaryTint`) that re-calls the connector |
| **Loaded** | The grouped list as specified above |

## Edge cases

- An event whose `date` is more than ~2 weeks out: still show it (no cutoff in the mock data), don't add artificial pagination.
- Two events same day same time: keep both rows, order by array order in the JSON (stable sort).
- Very long `name` or `organizer` string: name truncates with ellipsis at 1 line; organizer line wraps to 2 lines max, then ellipsis.

## Widgets

| Widget | Notes |
|---|---|
| `EventsPage` | Top-level page, owns the `get_events()` call and grouping logic |
| `DayGroupCard(dateLabel, events)` | Renders one card + its label |
| `EventRow(time, name, venue, organizer, category)` | Reusable — could also back a "Today's events" widget on the Dashboard if ever added |
| `BottomBar(active: "events")` | Shared, see [dashboard.md](dashboard.md) |
