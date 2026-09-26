# Page: Cafes — build spec

**Canvas board:** CafePage · **Route:** drill-in only (not a bottom-bar tab) · **File:** `CafePage.dc.html`

One line: every campus cafe's crowd level, quietest first. View-only.

## Entry points

| From | How |
|---|---|
| Dashboard | Tap the **"Quietest cafe"** tile only |

No bottom-bar tab, no bottom bar on this page — same pattern as Buses. Back chevron is the only exit.

## Data needed

| Connector | Called | Returns |
|---|---|---|
| `get_cafe_crowd()` | On page open, no args (all cafes) | `id, name, location, crowd_level, wait_minutes` |

No mutation connectors.

## Layout, top to bottom

```
┌──────────────────────────────────┐
│ (‹)  Cafes                        │  page header — NO bottom bar
├──────────────────────────────────┤
│ QUIETEST FIRST                    │  section label
│ ┌──────────────────────────────┐ │
│ │ ☕ Student Union Coffee Bar    │ │  ONE card, one row per cafe
│ │    Student Union, 1st Floor   │ │
│ │              ▂▄▆ Low · 2 min  │ │
│ ├──────────────────────────────┤ │
│ │ ☕ Engineering Building Kiosk  │ │
│ │    Engineering Building,      │ │
│ │    Lobby                      │ │
│ │           ▂▄▆ Medium · 6 min  │ │
│ ├──────────────────────────────┤ │
│ │ ☕ Main Library Cafe           │ │
│ │    Library, Ground Floor      │ │
│ │            ▂▄▆ High · 12 min  │ │
│ └──────────────────────────────┘ │
└──────────────────────────────────┘
```

(Coffee icon is an SVG in a square, not emoji — placeholder above.)

## Header

| Part | Spec |
|---|---|
| Back button | 44×44, outlined `line`, radius 12, left-chevron. Goes to Dashboard |
| Title | "Cafes", Bricolage 20 / 700 |

## Section label

"QUIETEST FIRST" — 12 / 700, uppercase, `textMuted`.

## The card

**One card holding all 3 cafes as rows** (not 3 separate cards) — `surface`, 1 px `line`, radius 20, no outer padding; each row has its own padding with a 1px `lineSoft` divider between rows, none after the last.

### Row anatomy

| Element | Spec |
|---|---|
| Icon | `coffee` icon, 18px, in a 36×36 `primaryTint` square, radius 10, left |
| Name | 15 / 600, `text` |
| Location | 13 / 400, `textMuted`, directly under the name |
| Crowd bars | 3 bars, 5px wide, heights 8/12/16px, radius 2, gap 2px between bars. Filled bars = `primary`, unfilled = `inputLine`. **Low = 1 filled, Medium = 2 filled, High = 3 filled** |
| Crowd word | Next to the bars, 14 / 700, `text`. Always shown — never rely on the bars alone |
| Wait time | Below the bars+word line, right-aligned, 12 / 400, `textMuted`. Text: "{wait_minutes} min wait" |
| Row padding | 14px vertical |

### All rows (demo data — every cafe in `data/cafes.json`, **sorted quietest first**)

| Name | Location | Crowd | Bars filled | Wait |
|---|---|---|---|---|
| Student Union Coffee Bar | Student Union, 1st Floor | Low | 1 | 2 min |
| Engineering Building Kiosk | Engineering Building, Lobby | Medium | 2 | 6 min |
| Main Library Cafe | Library, Ground Floor | High | 3 | 12 min |

**Sort rule:** by `crowd_level` ascending (low → medium → high); if tied, by `wait_minutes` ascending. This is a client-side sort — `get_cafe_crowd()` doesn't sort for you.

## Interaction — step by step

1. **Page opens** → loading state → call `get_cafe_crowd()` → sort quietest-first → render the one card with 3 rows.
2. **Student reads the list** → no tap targets for the demo (view only).
3. **Optional, if time allows:** pull-to-refresh re-calls the connector.
4. **Student taps the back chevron** → navigate to Dashboard.

## States

| State | What shows |
|---|---|
| **Loading** | One card with 3 skeleton rows |
| **Empty** (shouldn't happen with this mock) | Centered: coffee icon (32px, `textMuted`) + "No cafe data right now." |
| **Error** | Centered: "Couldn't load cafe crowds." + `Try again` button |
| **Loaded** | The sorted card as specified |

## Edge cases

- Two cafes tied on both `crowd_level` and `wait_minutes`: keep original array order between them (stable sort).
- Unknown `crowd_level` value: fall back to showing the raw string as the word, with 0 bars filled, rather than crashing.

## Widgets

| Widget | Notes |
|---|---|
| `CafePage` | Top-level page, no bottom bar, owns the sort |
| `CafeRow(name, location, crowdLevel, waitMinutes)` | One instance per cafe |
| `CrowdBars(level)` | Shared — this exact 3-bar widget also appears on the Dashboard's "Quietest cafe" tile, so build it once and reuse |
