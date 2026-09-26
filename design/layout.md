# Layout

Target device: **phone, portrait, 390 × 844** (iPhone 14 / most Androids). Colours, fonts and radii come from [design.md](design.md).

## Welcome state (first page)

Shown when the chat has no messages yet. Canvas board "0 · Welcome".

```
┌──────────────────────────────────┐
│ [CC] Campus Concierge   [home]   │  68 px, no border, background colour
│                                  │
│                                  │
│        Welcome, {username}       │  Bricolage 32 / 38, 700, centred
│   Ask me anything about campus — │  body 15 / 22, textMuted, centred,
│   rooms, buses, events and what's│  max width 290
│   due.                           │
│                                  │  gap 24
│ ([search] Ask anything…     (send))│  search bar
│                                  │  gap 24
│  [What's on today?] [Next bus]   │  chips, centred, wrap
│          [My to-dos]             │
│                                  │
│  ● Connected to 6 campus services│  footer 56 px, meta, textMuted
└──────────────────────────────────┘
```

| Part | Spec |
|---|---|
| Header | 68 px, padding 0 × 16. Left: 32 × 32 `CC` mark (radius 10) + "Campus Concierge" Bricolage 16. Right: **Home button** 44 × 44, outlined (`line`), radius 12, `house` icon |
| Content block | Vertically centred in the space between header and footer, nudged up slightly (72 px bottom padding). Side padding 20 |
| **Search bar** | Height 56, **fully round** (`radiusPill`), `surface` fill, 1 px `inputLine`. Left: 20 px `search` icon in `textMuted`. Input text 16 (16+ stops iOS zooming in). Right: 44 × 44 round `primary` send button, 6 px from the edge |
| Chips | Same as chat chips (44 px). Row wraps and centres |
| Footer | `live` dot + "Connected to 6 campus services" |

Transition to chat: on first send, the search bar animates down to the composer position (300 ms) and the welcome text fades out (200 ms).

## Dashboard

Canvas board "Dashboard". Background `background`, side padding 16.

| Part | Spec |
|---|---|
| Header | 68 px, no border. Left: 32 px `CC` mark + "Campus Concierge". Right: date + time, `meta` 600, `textMuted` |
| Greeting | "Good afternoon, {username}" Bricolage 28 / 34 · "Here's your campus right now." body, `textMuted` |
| Nudge | Compact nudge card: padding 14 × 16, title 18, body 14, **no info pills**, same 2 buttons |
| Section label | "RIGHT NOW" — `label`, uppercase |
| Tiles | 2 × 2 grid, gap 12. Each tile: `surface`, 1 px `line`, `radiusCard`, padding 14, min height 124. Row 1: 16 px icon + label (`meta`, muted). Row 2: big value (`display` 30, `primary`). Row 3: name (600) + detail (muted), 13 / 18 |
| Ask bar | Same as the Welcome search bar, pinned 20 px from the bottom |

Cafe tile shows 3 bars (6 px wide, 10 / 16 / 22 px tall; filled = `primary`, empty = `inputLine`) + the word Low / Medium / High.

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
| Subtitle text | "Online · 6 services" (short, so two buttons fit) |
| Right buttons | Two 44 × 44 outlined buttons, gap 8: `square-check` → opens to-do sheet · `house` → **Home (Dashboard)**, always the rightmost |

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
| `submit_assignment` | Marked {assignment title} as submitted |

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
| Cafe crowd | `coffee` icon | Cafe crowds | One row per cafe, **quietest first**: `name` + `location`; right side 3 bars + word **Low / Medium / High** (never colour only) + "{wait_minutes} min wait" |
| Clinic slots (options) | `stethoscope` | Clinic · {date} | One **tappable row per free slot** (56 px, `primaryTint`, radius 14): time (Bricolage 18, `primary`), doctor + type, "Book". Tap sends "Book 09:00 with Dr. Tanaka" |
| Appointment booked | ✓ success | Appointment booked | When, Doctor, Type |

## To-do bottom sheet

Opens from the header to-do button (canvas board "To-do bottom sheet").

- Scrim over the chat: `#1A1C20` at 45%. Tap it to close.
- Sheet: `surface`, top corners radius 24, padding 10 / 16 / 28. Drag handle 40 × 5, `inputLine`.
- Title "Your to-dos" Bricolage 22 + "From your courses · 3 not submitted" (`meta`). Round 44 px close button (`background` fill, `x` icon).
- One row per pending assignment: empty checkbox, title (15, 600), course (13, muted), due (13, muted). Rows: radius 16, 1 px `line`, padding 14.
- **Due today** row: `primaryTint` fill, due shown as an indigo pill "Today 23:59", plus a `Mark submitted` button that sends "Mark Problem Set 3 as submitted" (agent calls `submit_assignment`).
- Footer line: check icon + "1 submitted this week · Problem Set 2".

## States

Canvas board "States + nudges 2 and 3".

| State | Spec |
|---|---|
| Agent thinking | Agent bubble 44 px tall, three 8 px dots in `textMuted` at 100 / 60 / 30% (animate them in turn) |
| Error | Agent bubble "Sorry, I couldn't reach campus services just now. Want to try again?" + `Try again` chip |
| Nudge after a tap | Collapses to one line: check icon + "{title} · You chose "{button}"", 60% opacity. Stays in the history |

## Screen anatomy

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
