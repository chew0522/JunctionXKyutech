# Dashboard (Home) — build spec for the coder

The **Home** tab of the bottom bar, and the app's launch screen. A glance at campus right now: search, the current nudge, 3 live tiles, the Health Center banner, and a preview of upcoming events. **Tapping anything navigates to its own page** (see [page-events.md](page-events.md), [page-buses.md](page-buses.md), [page-cafes.md](page-cafes.md), [page-courses.md](page-courses.md), [page-bookings.md](page-bookings.md), [page-healthcare.md](page-healthcare.md), [page-profile.md](page-profile.md)) — it does **not** open the chat. Only the **Ask** button opens the chat.

Colours, fonts and sizes: [design.md](design.md). Nudge card: [chat-ui.md § Nudge card](chat-ui.md#nudge-card-tier-0) (use the compact version below). Device: phone, 390 × 844. Demo time: Sat 26 Sep 2026, 14:50.

```
 Home   Courses   ( ASK )   Bookings   Profile     ← floating bottom bar, on every tab page
   ▲       │      opens Chat    │         │
   │       ▼                   ▼         ▼
   │   CoursesPage.dc.html  BookingsPage  ProfilePage
   │
   ├─ tile: Next bus ──────► BusPage.dc.html
   ├─ tile: Due next ──────► CoursesPage.dc.html (its to-dos section)
   ├─ tile: Cafes ─────────► CafePage.dc.html
   ├─ Health Center banner ► HealthcarePage.dc.html
   └─ "Show all events" ───► EventsPage.dc.html (no longer a bottom-bar tab)
```

**Events moved off the bottom bar.** It's still a full page ([page-events.md](page-events.md)), but the only way in now is the Dashboard's own "Upcoming events" section — there's no dedicated tile for it either, since the events preview lives directly on the Dashboard.

Canvas board: **Dashboard**. Route `/`. Background `background`, side padding 16.

## Layout, top to bottom

| # | Element | Content (demo) | Tap → |
|---|---|---|---|
| 1 | **Header** | A search bar ("Search campus…", 48 px pill, `surface` fill, 1 px `inputLine`) filling most of the width, plus a 44 px round **profile icon** (`primary` fill, white profile glyph) at the far right | Profile icon → **ProfilePage.dc.html**. Search bar → see "Open question" below |
| 2 | Greeting | "Good afternoon, Alex" (Bricolage 26 / 32) · "Here's your campus right now." (15, `textMuted`) | — |
| 3 | Nudge card (compact) | HEADS UP · "Your usual room is taken" (18) · "Study Room 204 is booked. Study Room 201 is free right now." (14) · no pills | `Book Room 201` → navigate to **BookingsPage.dc.html** with the booking already done · `No thanks` → dismiss |
| 4 | Section label | "RIGHT NOW" (12 / 700, uppercase, `textMuted`) | — |
| 5 | **3-column tile row** | See below | — |
| 6 | Health Center banner | `stethoscope` "Health Center" · **"Next slot: tomorrow, 09:00"** — full-width row | **HealthcarePage.dc.html** |
| 7 | Section label | "UPCOMING EVENTS" | — |
| 8 | 2 large event cards | **15:00 AI Workshop** — Building A, Room 101 · Computer Science Club · **17:00 Career Fair** — Main Hall · Career Services Office. Each: time (Bricolage 18, `primary`, 52 px column) + name (16/700) + detail (13, `textMuted`) + chevron | Both → **EventsPage.dc.html** |
| 9 | "Show all events" button | Secondary pill, `primaryTint` fill, 44 px | **EventsPage.dc.html** |
| 10 | **Floating bottom bar** | 5 slots — see below | — |

### 3-column tile row (was 2×2, now 3 tiles in one row)

**"Next event" is no longer a tile** — it moved into its own "Upcoming events" section (rows 7–9 above). The remaining 3 tiles:

| Tile | Icon | Value | Detail | Tap → |
|---|---|---|---|---|
| Next bus | `bus` | **4 min** | Campus Loop A / at the Library | **BusPage.dc.html** |
| Due next | `square-check` | **23:59** | Problem Set 3 / today · 3 due | **CoursesPage.dc.html** |
| Cafes | `coffee` | **Low** | Student Union / 2 min wait | **CafePage.dc.html** |

Spec: `grid-template-columns: repeat(3, 1fr)`, gap 10. Each tile: `surface`, 1 px `line`, radius 18, padding 12×10, min height 118. Value text shrinks from the old 30px to **22px** (Bricolage 700) to fit 3 narrower columns. **Each tile has a small chevron in its top-right corner** (absolute positioned, 12px inset) signalling it's tappable — this is new; the old 4-tile grid didn't have one.

## Floating bottom bar

```
  (home)  (cap)   ( ASK )  (cal✓)  (person)
   Home  Courses ▲raised▲ Bookings Profile
```

| Part | Spec |
|---|---|
| Outer wrapper | `padding: 0 16px 16px` around the pill — this margin is what makes it "float" instead of sitting flush against the screen edges |
| Bar | 72 px tall, `surface`, **1 px `line` border all the way around** (not just the top, since it's no longer docked to an edge), **radius 36 (full pill)**, 5 equal grid columns, padding 0 × 10 |
| Tab (4 of them) | 48 px tap area, icon 20 + label 11. Active: `primary`, 700, `aria-current="page"`. Inactive: `textMuted`, 600 |
| **Ask button (centre)** | 64 px circle, `primary` fill, white speech-bubble icon 26, 4 px ring in `background` colour. **Absolutely positioned, top: -28px, left: 50%, translateX(-50%)** — taken out of the grid flow so the other 4 tabs lay out in a clean 4-column-equivalent grid (5 grid cells, the middle one an empty spacer `<div>`) |
| Nudge dot | 16 px `nudge` (amber) dot with 3 px white ring, top-right of the Ask button, **only while a nudge is waiting** |

| Slot | Tab | Opens |
|---|---|---|
| 1 | Home | This Dashboard |
| 2 | Courses | **CoursesPage.dc.html** |
| 3 | **Ask** | **Chat**, Welcome state — the only way into the chat |
| 4 | Bookings | **BookingsPage.dc.html** |
| 5 | **Profile** | **ProfilePage.dc.html** — new |

**Events is gone from the bar entirely.** Reasons: it freed a slot for Profile, and Events is pure browsing (no action to take), so a permanent tab wasn't earning its place — the Dashboard's own preview + "Show all" covers it.

**The floating bar is on every tab page** (Home, Courses, Bookings, Profile) and **hidden in the chat** (the composer needs the space; the chat header's own Home button goes back to the Dashboard). It is **not** shown on the drill-in pages (Buses, Cafes, Healthcare, Events, and the Course Hub sub-pages) — those use only a back chevron, keeping them feeling like quick "peeks" rather than full sections.

**Data:** `get_bus_location` (first route), `todo_list` (first item + count), `get_cafe_crowd` (lowest crowd), `get_clinic_slots()` (earliest available slot), `get_events()` (first 2 upcoming, for the events preview), nudge from `/nudges`. Greeting word from the time: before 12 "Good morning", before 18 "Good afternoon", else "Good evening".

**No time to build all the pages?** Fall back to the old plan in [chat-ui.md](chat-ui.md): every tile and tab sends a message into the chat instead of opening a page.

## Open question — not decided yet

**What does the search bar do when tapped?** It's currently a **static, non-functional visual only**. The obvious behaviours all conflict with something already decided:
- Opening the Chat would create a second door into the chat, contradicting "Ask is the only way in."
- A real campus-wide search needs its own results UI and data model, not designed yet.

Don't wire it to anything until this is resolved. If asked to guess, the safest default is a plain non-interactive placeholder, exactly as built.

## Widgets

| Widget | Used for |
|---|---|
| `SearchBar` | Header, static for now |
| `DashTile(icon, label, value, line1, line2, route)` | The 3 tile-row cards, now with a chevron |
| `DashBannerTile(icon, label, value, route)` | The Health Center row |
| `EventPreviewCard(time, name, venue, organizer)` | The 2 large event cards |
| `NudgeCard(nudge, compact: true)` | The nudge at the top (shared with the chat) |
| `FloatingBottomBar(active, hasNudge)` | The floating pill nav — used on every tab page |
