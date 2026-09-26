# Page: Buses — build spec

**Canvas board:** BusPage · **Route:** drill-in only (not a bottom-bar tab) · **File:** `BusPage.dc.html`

One line: every campus bus route's live location and ETA. View-only.

## Entry points

| From | How |
|---|---|
| Dashboard | Tap the **"Next bus"** tile only |

There's no bottom-bar tab for this page — it's one level in. Because of that, **it has no bottom bar of its own**; the header's back chevron is the only way out.

## Data needed

| Connector | Called | Returns |
|---|---|---|
| `get_bus_location()` | On page open, no args (all routes) | `route, current_stop, next_stop, eta_minutes, capacity_status` |

No mutation connectors.

## Layout, top to bottom

```
┌──────────────────────────────────┐
│ (‹)  Buses                        │  page header, 68 px — NO bottom bar on this page
├──────────────────────────────────┤
│ LIVE · UPDATED 20 S AGO           │  section label
│ ┌──────────────────────────────┐ │
│ │ 🚌 Campus Loop A      4 min  │ │  one card per route
│ │    Library → Dormitory        │ │
│ │    Block C          Moderate  │ │
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ 🚌 Campus Loop B      9 min  │ │
│ │    Main Gate → Engineering    │ │
│ │    Building         Crowded   │ │
│ └──────────────────────────────┘ │
│         (2 more cards)            │
└──────────────────────────────────┘
```

Note the icon is drawn as an SVG bus icon in a 36px square, not emoji — the diagram above uses 🚌 only as a placeholder for "bus icon".

## Header

| Part | Spec |
|---|---|
| Back button | 44×44, outlined `line`, radius 12, left-chevron. Goes to Dashboard |
| Title | "Buses", Bricolage 20 / 700 |

## Section label

"LIVE · UPDATED {n} S AGO" — 12 / 700, uppercase, `textMuted`. For the mock, hardcode "Live · updated 20 s ago"; a real implementation would track time-since-last-poll.

## Route card (one per route, each its own card — not one card with rows)

`surface`, 1 px `line`, radius 20, padding 14px.

| Element | Spec |
|---|---|
| Icon | `bus` icon, 18px, in a 36×36 `primaryTint` square, radius 10, left |
| Route name | Bricolage Grotesque 16 / 700, `text` |
| Stop line | "{current_stop} → {next_stop}", 13 / 400, `textMuted` |
| ETA | Right-aligned, Bricolage Grotesque 22 / 700, `primary`. Text: "{eta_minutes} min" |
| Status pill | Below the ETA, right-aligned, 20px tall, pill radius, 11/700 text + colored background — see mapping below |

### `capacity_status` → status pill mapping

| Raw value | Label shown | Text colour | Background |
|---|---|---|---|
| `"empty"` | Quiet | `success` (`#1E6B3F`) | `successFill` (`#E6F4EC`) |
| `"moderate"` | Moderate | `nudge` (`#8A4B00`) | `nudgeFill` (`#FFF1DC`) |
| `"crowded"` | Crowded | `danger` (`#A1331F`) | a light red, `#FBEAE7` (add this token if not already in design.md) |

**Never rely on colour alone** — the word (Quiet/Moderate/Crowded) is always shown.

### All rows (demo data — every route in `data/bus.json`, in file order)

| Route | Current stop | Next stop | ETA | Status |
|---|---|---|---|---|
| Campus Loop A | Library | Dormitory Block C | 4 min | Moderate |
| Campus Loop B | Main Gate | Engineering Building | 9 min | Crowded |
| Campus Loop C | Sports Complex | Student Union | 2 min | Quiet |
| Off-Campus Shuttle | Train Station | Main Gate | 14 min | Moderate |

Order: keep the connector's array order (don't re-sort by ETA — the demo relies on Campus Loop A, the one used by nudges/tiles, being first).

## Interaction — step by step

1. **Page opens** → loading state → call `get_bus_location()` → render one card per route.
2. **Student reads the cards** → no tap targets on this page for the demo (view only).
3. **Optional, if time allows:** pull-to-refresh re-calls `get_bus_location()` and resets the "updated Ns ago" label to 0.
4. **Student taps the back chevron** → navigate to Dashboard. (There's no bottom bar here to tap into another tab directly — that's intentional, keeping this a lightweight drill-in.)

## States

| State | What shows |
|---|---|
| **Loading** | 4 skeleton cards (grey blocks in place of name/stops/ETA) |
| **Empty** (no routes returned — shouldn't happen with this mock) | Centered: bus icon (32px, `textMuted`) + "No buses running right now." |
| **Error** | Centered: "Couldn't load bus locations." + `Try again` button |
| **Loaded** | The 4 cards as specified |

## Edge cases

- `eta_minutes` of 0 or negative (bus arriving/just left): show "Now" instead of "0 min" — note this for the coder even though the mock data never hits it.
- Unknown `capacity_status` value (future-proofing if new statuses get added to the mock data): fall back to Moderate's styling and show the raw string as the label, so nothing breaks silently.

## Widgets

| Widget | Notes |
|---|---|
| `BusPage` | Top-level page, no bottom bar |
| `BusRouteCard(route, currentStop, nextStop, etaMinutes, capacityStatus)` | One instance per route |
| `StatusPill(label, fg, bg)` | Shared with any other page needing a coloured status tag |
