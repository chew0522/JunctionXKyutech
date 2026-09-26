# Layout

Target device: **phone, portrait, 390 × 844** (iPhone 14 / most Androids). Colours, fonts and radii come from [design.md](design.md).

## Screen anatomy

```
┌──────────────────────────────────┐
│ HEADER                   68 px   │  surface, 1 px line at bottom
│ [CC] Campus Concierge      [✓]   │
│      ● Connected to 6 services   │
├──────────────────────────────────┤
│                                  │
│ MESSAGE LIST        flexible     │  background colour
│ padding 16, gap 12               │  newest at the bottom
│                                  │
│          Today · 14:50           │  time divider
│                  ┌─────────────┐ │
│                  │ user bubble │ │  right
│                  └─────────────┘ │
│ ┌──────────────┐                 │
│ │ agent bubble │                 │  left
│ └──────────────┘                 │
│ ┌──────────────────────────────┐ │
│ │ NUDGE / RESULT CARD          │ │  full width
│ └──────────────────────────────┘ │
│                                  │
├──────────────────────────────────┤
│ COMPOSER                ~140 px  │  surface, 1 px line at top
│ [chip] [chip] [chip]      44 px  │
│ [ Ask about rooms…   ] (➤) 48 px │
│ padding 12 / 16 / 20             │
└──────────────────────────────────┘
```

Flutter:
```dart
Scaffold(
  backgroundColor: AppColors.background,
  body: SafeArea(
    child: Column(children: [
      ChatHeader(),                       // 68 px
      Expanded(child: MessageList()),     // ListView, reverse: true
      Composer(),                         // chips + input
    ]),
  ),
)
```

## Header — 68 px

| Part | Spec |
|---|---|
| Padding | 0 × 16, items centred, gap 12 |
| Avatar | 40 × 40, `radiusButton`, `primary` fill, "CC" in white `appName` 16 |
| Title | "Campus Concierge", `appName` |
| Subtitle | 8 px `live` dot + "Connected to 6 campus services", `meta`, `textMuted` |
| Right button | 44 × 44 outlined, `square-check` icon → opens to-do sheet |

## Message list

- `ListView` with `reverse: true` so newest is at the bottom and it sticks there.
- Padding 16 all sides. **Gap 12** between messages; **gap 20** before a time divider.
- Time divider: centred, `label`, `textMuted`. Show one when > 10 min passed since the last message.

## The 6 message types

Everything in the list is one of these. **Result cards share one shell** — only their rows change.

### 1. User bubble
- Right-aligned, **max width 78%** of the screen
- Fill `primary`, text white `body`
- Padding 10 × 14, radius 18/18/**4**/18 (tail bottom-right)

### 2. Agent bubble
- Left-aligned, max width 78%
- Fill `surface`, 1 px `line` border, text `body`
- Padding 10 × 14, radius 18/18/18/**4** (tail bottom-left)

### 3. Trace line (agent used a tool)
- Left, no bubble. 14 px `wrench` icon + text, gap 6, `label` 12, `textMuted`
- Text: "Checked study rooms · Booked Study Room 201"
- Comes from the `tools` list the backend returns with each `/chat` reply — one line per reply, joined with " · "

| Tool | Trace text |
|---|---|
| `get_events` | Checked campus events |
| `get_study_rooms` | Checked study rooms |
| `book_study_room` | Booked {room name} |
| `get_bus_location` | Checked live bus location |
| `todo_list` / `get_assignments` | Checked your to-dos |
| `get_cafe_crowd` | Checked cafe crowds |
| `get_clinic_slots` | Checked clinic slots |
| `book_clinic_appointment` | Booked clinic appointment |

### 4. Nudge card (Tier 0)
Full width. Fill `nudgeFill`, 1 px `nudgeLine`, `radiusCard`, padding 16, gap 12 between rows.

```
┌──────────────────────────────────────┐
│ [bell] HEADS UP       You didn't ask —  │  label row: bell + "HEADS UP" (nudge, uppercase)
│                    I noticed         │    right side: meta, not uppercase
│ Your usual room is taken             │  title (Bricolage 21)
│ Study Room 204 is booked. Study Room │  body (max 2 sentences)
│ 201 is free now — want me to book it?│
│ ([pin] Library 2F) ([users] 4 seats) │  optional info pills: white, 32 px, radius pill
│ [ Book Room 201 ] [   No thanks   ]  │  2 buttons, 44 px, equal width, gap 8
└──────────────────────────────────────┘
```
- Primary button: `nudge` fill, white text. Secondary: white fill, `nudgeButtonLine` border, `nudge` text.
- After the student taps a button, **both buttons disable** (40% opacity) so it can't be tapped twice.

### 5. Result card (booking, clinic, bus, to-do, cafe)
Full width. Fill `surface`, 1 px `line`, `radiusCard`, padding 16, gap 14.

```
┌──────────────────────────────────────┐
│ (✓) Room booked                      │  header: 32 px success circle + cardTitle
├──────────────────────────────────────┤
│ Room             Study Room 201      │  key/value rows, 40 px each,
│ Where            Library, 2nd floor  │  key = meta muted, value = meta 600
│ Seats            4 · whiteboard      │  1 px lineSoft between rows
├──────────────────────────────────────┤
│ [   Next bus    ] [  Cafe crowd   ]  │  up to 2 follow-up buttons, 44 px
└──────────────────────────────────────┘
```

Variants — same shell, different header and rows. Every value comes from the connector's result (field names from `data/`):

| Card | Header icon | Title | Rows / body |
|---|---|---|---|
| Room booked | ✓ success | Room booked | Room (`name`), Where (`building`, `floor`), Seats (`capacity`, `has_whiteboard`) |
| Clinic booked | ✓ success | Appointment booked | Fields from `clinic_slots.json` (date, time, doctor/type) |
| Bus | `bus` icon in `primaryTint` square | Campus Loop A (`route`) | Big ETA on the right (`eta_minutes`, `display`, `primary`); "Now at Library → next Dormitory Block C" (`current_stop` → `next_stop`); "Moderately busy" (`capacity_status`) |
| To-do list | `square-check` | 3 things due | One row per item: empty checkbox, `task`, course, `due`. Due today shown in 600 weight. Link "View all" |
| Cafe crowd | `coffee` icon | Cafe crowds | One row per cafe: `name`, 3 bars + word **Low / Medium / High** (never colour only), `wait_minutes` |

### 6. Suggestion chips
- Height 44, padding 0 × 16, `radiusPill`, `primaryTint` fill, 1 px `primaryLine`, `primary` text `chip`
- Horizontal row, gap 8, scrolls sideways if it overflows
- Show 3 chips max. They change with context (after a booking: `Next bus`, `My to-dos`)

## Composer

- Chips row on top, input row below, gap 12. Padding 12 top / 16 sides / 20 bottom.
- Input: 48 px tall, `radiusPill`, `background` fill, 1 px `inputLine`, placeholder "Ask about rooms, buses, events…"
- Send: 48 × 48 circle, `primary` fill, white `send` icon. Disabled (40% opacity) when input is empty.

## Checklist for the coder

- [ ] Every tappable thing ≥ 44 × 44
- [ ] Only colours from design.md — amber only on nudges
- [ ] Bubbles max 78% width
- [ ] One result card widget with a variant parameter, not five separate widgets
- [ ] Every button/chip tap sends its label as a message (see [navigation.md](navigation.md))
- [ ] Test on a real phone at full brightness — projectors wash out light colours
