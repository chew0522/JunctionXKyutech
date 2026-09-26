# Dashboard — build spec for the coder

The screen the **Home button** opens. A glance at campus right now: the current nudge + 4 live tiles. Every tap opens the chat and sends a message — the chat itself is specified in [chat-ui.md](chat-ui.md).

Colours, fonts and sizes: [design.md](design.md). Nudge card: [chat-ui.md § Nudge card](chat-ui.md#nudge-card-tier-0) (use the compact version below). Device: phone, 390 × 844. Demo time: Sat 26 Sep 2026, 14:50.

```
Dashboard ──(tile / nudge / ask bar)──► Chat
    ▲                                    │
    └────────────(Home button)───────────┘
```

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
| 9 | **Bottom bar** | 5 slots — see below | — |

## Bottom bar

```
  (home)   (cal)    ( ASK )   (cap)   (cal✓)
   Home   Events   ▲raised▲  Courses  Bookings
```

| Part | Spec |
|---|---|
| Bar | 84 px tall (includes 16 px bottom safe area), `surface`, 1 px `line` top border, 5 equal columns |
| Tab (4 of them) | 56 px tap area, icon 22 + label 12. Active: `primary`, 700. Inactive: `textMuted`, 600 |
| **Ask button (centre)** | 64 px circle, `primary` fill, white `message-circle` icon 26, 4 px ring in `background` colour so it lifts off the bar. **Raised 30 px above the bar.** Label "Ask" below, `primary` 12 / 700 |
| Nudge dot | 16 px `nudge` (amber) dot with 3 px white ring, top-right of the Ask button, **only while a nudge is waiting**. Semantics label: "Ask Campus Concierge — 1 new heads-up" |

| Slot | Tab | Opens | PRD feature |
|---|---|---|---|
| 1 | Home | This Dashboard | Nudge + live tiles |
| 2 | Events | Events page *(not designed yet)* | Event Information Center |
| 3 | **Ask** | Chat, Welcome state | The agent — the wow point |
| 4 | Courses | Courses page *(not designed yet)* | Academic platform + to-dos |
| 5 | Bookings | Bookings page *(not designed yet)* | Study rooms + clinic |

**In the chat, hide the bottom bar** so the composer has room; the chat header's Home button comes back here.

Until the 3 tab pages exist, each tab can just open the chat and send a message ("What's on today?", "What are my courses?", "Show my bookings") — same answer, zero extra screens.

**Tiles:** 2 × 2 grid, gap 12. Each: `surface`, 1 px `line`, radius 20, padding 14, min height 124. Big value = Bricolage 30 / 700 `primary`.

**Data:** `get_bus_location` (first route), `todo_list` (first item + count), `get_events(today)` (next upcoming), `get_cafe_crowd` (lowest crowd), nudge from `/nudges`. Greeting word from the time: before 12 "Good morning", before 18 "Good afternoon", else "Good evening".

**No time?** Skip the Dashboard: Home clears the chat and shows Welcome.

## Widget

| Widget | Used for |
|---|---|
| `DashTile(icon, label, value, line1, line2, message)` | The 4 tiles — `message` is what gets sent to the chat on tap |
| `NudgeCard(nudge, compact: true)` | The nudge at the top (shared with the chat) |
| `BottomBar(active, hasNudge)` | Bottom bar with the raised Ask button |
