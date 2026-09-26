# Design — team brief

**Read this first.** Everything the team needs from UI/UX for Campus Concierge (JunctionX Kyutech 2026, Track 02). Owner: UI/UX.

**Mockups:** [Campus Concierge Chat UI canvas](https://claude.ai/artifact/NtfYEffJuhq1eSvM8qeFjn) — 9 screens + a UI kit board. Press Play on a screen to click through (Home → Dashboard → tiles). (Ask UI/UX to share it with you if the link doesn't open.)

| Canvas board | Shows |
|---|---|
| 0 · Welcome | First page: Welcome, {username}, round search bar, chips, Home button |
| 1 · Proactive nudge | Room nudge arrives unasked |
| 2 · Room booking | Tap "Book Room 201" → booked |
| 3 · Bus + to-dos | Bus card, to-do list card |
| 4 · Cafe crowd | Which cafe is quiet |
| 5 · Clinic booking | Pick a slot → appointment booked |
| Dashboard | Where Home goes: nudge + 4 live tiles |
| To-do bottom sheet | Pending assignments, Mark submitted |
| States | Thinking, error, nudges 2 and 3, a nudge after a tap |
| Chat UI kit | Colours, type, message pieces |

All names, times and numbers in these docs **follow the coder's mock data in `data/` and `backend/nudges.py`**. If the data changes, the design follows.

## The files

| File | What's in it | Who needs it most |
|---|---|---|
| [design.md](design.md) | Theme colours, fonts, sizes, corner radii, icons, Flutter `AppColors` + `ThemeData` | Coder, Slides |
| [layout.md](layout.md) | Screen anatomy (390 × 844), specs for all 6 message types, coder checklist | Coder |
| [navigation.md](navigation.md) | One-screen app, "every tap is a message" rule, loading/error states, 3-min demo flow | Coder, Pitch |
| [nudges.md](nudges.md) | The 3 built nudges (Tier 0), demo order, and the JSON format the nudge card needs | Everyone |
| [tone.md](tone.md) | How the agent talks: voice rules, sample replies, nudge + UI copy, **ready-to-paste `SYSTEM_PROMPT`** | Coder, Pitch |

## Decisions already made

1. **Phone, English, portrait.** Demo runs on a phone.
2. **Two screens: Dashboard + Chat.** Chat opens on a **Welcome** page ("Welcome, {username}" + round search bar). A **Home button (top right)** on every chat screen goes to the **Dashboard**: the current nudge + 4 live tiles (bus, due next, next event, quietest cafe). No tabs, menus or login. Plus one to-do bottom sheet.
3. **Theme colour: Indigo `#2B3A8F`.** Amber is reserved for nudges only. Details in [design.md](design.md).
4. **Demo nudge: N1 "Your usual room is taken"** — the agent speaks first *and* books a room in one tap.
5. **Every button and chip sends its label as a chat message.** One handler, and judges see every step.
6. **Generic campus.** The app is **Campus Concierge** — it works for any university. No real university's name, logo or colours appear in the app.

## Where the idea comes from (for the pitch)

A typical university spreads student services across many separate websites and apps, each with its own login. We map each **type of system** to connectors:

| Type of campus system | What it does | Our connectors | In the demo? |
|---|---|---|---|
| Announcements portal | Campus news, events, notices | `get_events` | ✅ |
| Facility / library booking | Reserve study rooms | `get_study_rooms`, `book_study_room` | ✅ ⭐ |
| Campus bus system | Shuttle routes and live location | `get_bus_location` | ✅ |
| Learning management system (LMS) | Courses, materials, assignments | `get_courses`, `get_course_materials`, `get_assignments`, `submit_assignment`, `todo_list` | ✅ |
| Cafe / canteen | How busy each cafe is | `get_cafe_crowd` | Optional |
| Clinic booking | Health centre appointments | `get_clinic_slots`, `book_clinic_appointment` | Tier 2 |
| Digital student ID | Virtual student card, QR check-in | none | ❌ Tier 3 — roadmap slide only |
| Student information system (SIS) | Course registration, exam results | none | ❌ Tier 3 — roadmap slide only |

**Before / after line for the pitch:**
> **Before:** open the admin portal → find the booking page → see your room is taken → search for another → book it → open the LMS to check deadlines.
> **After:** the agent says "Your usual room is taken — Study Room 201 is free, want it?" One tap.

Real-world reference: we studied one Malaysian public university's student systems as an example of this fragmentation. Say "a typical university" in the pitch; show a real portal on the problem slide only if the team agrees.

⚠️ **Privacy:** any screenshot of a real university portal on a slide must have the student's name, photo and ID number blurred.

## Demo facts

**Single source of truth — taken from `data/` and `backend/nudges.py`.** Mockups and the pitch script use exactly these values. If the coder changes the data, update this table and the canvas.

Demo clock: **Saturday 26 Sep 2026, 14:50** (`DEMO_NOW`). The student is at the Library.

| Feature | Value (from mock data) |
|---|---|
| App name | Campus Concierge |
| Header subtitle | Chat: "Online · 6 services" · Welcome footer: "Connected to 6 campus services" |
| Demo user name | Alex (placeholder) |
| Clinic slots (tomorrow) | **Sun 27 Sep 09:00** Dr. Tanaka, General Checkup (`slot-4`) · **15:00** Dr. Suzuki, Mental Health Counseling (`slot-5`) |
| **Usual room (nudge)** | **Study Room 204** · Library 3F · 8 seats — **booked** (`room-204`) |
| **Room offered + booked** | **Study Room 201** · Library 2F · **4 seats · whiteboard** (`room-201`) |
| Events today | **AI Workshop**, 15:00, Building A, Room 101 · **Career Fair**, 17:00, Main Hall |
| Bus | **Campus Loop A** — now at **Library**, next stop **Dormitory Block C**, **4 min**, moderately busy |
| Assignments / to-dos | **Problem Set 3 – Consensus** (CS301) due **today 23:59** · **Lab 5 – Balanced Trees** (CS210) due **Tue 29 Sep 18:00** · **Homework 2 – Fourier Series** (EE150) due **Wed 30 Sep 23:59** |
| Cafes | Main Library Cafe **high**, 12 min wait · Student Union Coffee Bar **low**, 2 min · Engineering Kiosk **medium**, 6 min |

## For the coder: 3 backend changes the UI needs

| # | Change | Why | If no time |
|---|---|---|---|
| 1 | `/nudges` returns **objects** (`id`, `title`, `body`, `actions`) instead of plain strings — format in [nudges.md](nudges.md#for-the-coder-nudge-format) | The nudge card needs a title and buttons | Show the string as the body with a fixed `Got it` button |
| 2 | `/chat` also returns **`tools`**: the list of tools called + their results, e.g. `[{"name": "book_study_room", "result": {...}}]` | Draws the trace line ("Booked Study Room 201") and picks the result card | Plain agent bubble only |
| 3 | **Remove emoji** from nudge strings and the `book_study_room` message (`✅`) | Design uses icons, not emoji | — |

Also: `book_study_room` writes to `data/rooms.json`. **Reset that file before each demo run.**

## What each teammate should do now

| Role | Next action |
|---|---|
| **Coder** | Set up `AppColors` + `ThemeData` from [design.md](design.md). Build the chat screen from [layout.md](layout.md). Do the 3 backend changes above. Paste the new `SYSTEM_PROMPT` from [tone.md](tone.md#ready-to-paste-system_prompt). |
| **Competitor analysis + slides** | Use indigo + amber in the deck. Use **Demo facts** for any screenshots or examples. For the "before" slide, show a typical tile-grid campus portal (personal details blurred). |
| **Business / pitch** | Rehearse the demo flow in [navigation.md](navigation.md#demo-flow-3-min-for-the-pitch). Practise pausing for the nudge. |
| **UI/UX** | Test the agent's replies against [tone.md](tone.md#how-to-test-the-tone-uiux-task). Then test the built app on a real phone. |
