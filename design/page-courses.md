# Page: Courses — build spec

**Canvas board:** CoursesPage · **Route:** bottom-bar tab #4 · **File:** `CoursesPage.dc.html`

One line: the student's to-dos (pending assignments) and their 3 courses, with a drill-in to materials and an in-page submit flow. The most interactive of the 5 pages — it has real state changes (submitting an assignment).

## Entry points

| From | How |
|---|---|
| Bottom bar | Tap **Courses** tab |
| Dashboard | Tap the **"Due next"** tile — lands on this page, **scrolled to the To-dos section** (which is already at the top, so no special scroll behaviour needed) |

## Data needed

| Connector | Called | Returns / does |
|---|---|---|
| `get_assignments(pending_only=True)` | On page open | `id, course_id, title, due_date, due_time, submitted` — only unsubmitted ones |
| `get_courses()` | On page open | `id, code, name, instructor, semester` |
| `get_course_materials(course_id)` | When a course row is tapped | `id, course_id, week, title, type` filtered to that course |
| `submit_assignment(assignment_id)` | When the student confirms a submission | Mutates `assignments.json`: sets `submitted: true`. Returns `{success, message}` |

**`todo_list()` is not called directly here** — CLAUDE.md says `todo_list` derives from `get_assignments(pending_only=True)`, so this page can call `get_assignments` directly and get the same data, or call `todo_list()` if the coder prefers reusing that endpoint. Either is fine; they return equivalent data.

## Layout, top to bottom (default / list state)

```
┌──────────────────────────────────┐
│ (‹)  Courses                      │  page header
├──────────────────────────────────┤
│ TO-DOS · 3 NOT SUBMITTED          │  section label
│ ┌──────────────────────────────┐ │
│ │ ☐ Problem Set 3 – Consensus   │ │
│ │   CS301 Distributed Systems   │ │
│ │                  [Today 23:59]│ │  ← indigo pill, urgent
│ │ ☐ Lab 5 – Balanced Trees      │ │
│ │   CS210 Data Structures       │ │
│ │                      Tue 18:00│ │  ← plain text, not urgent
│ │ ☐ Homework 2 – Fourier Series │ │
│ │   EE150 Signals and Systems   │ │
│ │                      Wed 23:59│ │
│ └──────────────────────────────┘ │
│ MY COURSES                        │
│ ┌──────────────────────────────┐ │
│ │ 🎓 CS301 Distributed Systems ›│ │
│ │    Prof. Yamamoto · 1 due     │ │
│ │ 🎓 CS210 Data Structures &    │ │
│ │    Algorithms               › │ │
│ │    Prof. Ito · 1 due          │ │
│ │ 🎓 EE150 Signals and Systems ›│ │
│ │    Prof. Kobayashi · 1 due    │ │
│ └──────────────────────────────┘ │
├──────────────────────────────────┤
│ Home  Events  (ASK)  Courses  Bookings │  "Courses" active
└──────────────────────────────────┘
```

## Header

| Part | Spec |
|---|---|
| Back button | 44×44, outlined `line`, radius 12, left-chevron. Goes to Dashboard |
| Title | "Courses", Bricolage 20 / 700 |

## Section 1: To-dos

**Label:** "TO-DOS · {n} NOT SUBMITTED" where n = count of pending assignments. 12/700, uppercase, `textMuted`.

**Card:** `surface`, 1 px `line`, radius 20, one row per pending assignment, 1px `lineSoft` dividers.

### Row anatomy
| Element | Spec |
|---|---|
| Checkbox | 20×20, empty (unchecked), 2px `textMuted` border, radius 6. **Tapping the row (not just the checkbox) opens the submit flow** — see step-by-step below |
| Title | 14 / 600, `text` |
| Course line | "{course code} {course name}", 13 / 400, `textMuted` — join via `course_id` → `get_courses()` |
| Due indicator, right | **If due today:** indigo pill, `primary` fill, white text, 12/700, pill radius, text "Today {due_time}". **Otherwise:** plain text, 12/400, `textMuted`, text "{weekday} {due_time}" |

### Rows (demo data — `get_assignments(pending_only=True)`, sorted by `due_date` then `due_time` ascending)

| Title | Course | Due | Row style |
|---|---|---|---|
| Problem Set 3 – Consensus | CS301 Distributed Systems | Today, 23:59 | **Urgent — indigo pill** (due_date = 2026-09-26 = today) |
| Lab 5 – Balanced Trees Implementation | CS210 Data Structures & Algorithms | Tue 18:00 | Plain |
| Homework 2 – Fourier Series | EE150 Signals and Systems | Wed 23:59 | Plain |

Note: `assign-4` (Problem Set 2, `submitted: true`) is **excluded** — `pending_only=True` filters it out.

**"Today" rule:** compare `due_date` to `DEMO_NOW`'s date (2026-09-26). If equal → urgent styling + "Today {time}". Else → "{short weekday} {time}" (Tue, Wed, etc.), no pill.

## Section 2: My courses

**Label:** "MY COURSES" — 12/700, uppercase, `textMuted`.

**Card:** `surface`, 1 px `line`, radius 20, one **tappable** row per course, 1px `lineSoft` dividers.

### Row anatomy
| Element | Spec |
|---|---|
| Icon | `graduation-cap`, 18px, in a 36×36 `primaryTint` square, radius 10 |
| Course name | "{code} {name}", 14 / 600, `text`. Wraps to 2 lines if long (e.g. "CS210 Data Structures & Algorithms") |
| Detail line | "{instructor} · {n} due", 13 / 400, `textMuted` — `n` = count of that course's pending assignments |
| Chevron | Right-aligned, 18px, `textMuted`, indicates the row is tappable |
| Whole row is a button | min height 56px for a comfortable tap target |

### Rows (demo data — `get_courses()`, all 3, in file order)

| Code + name | Instructor | Due count |
|---|---|---|
| CS301 Distributed Systems | Prof. Yamamoto | 1 |
| CS210 Data Structures & Algorithms | Prof. Ito | 1 |
| EE150 Signals and Systems | Prof. Kobayashi | 1 |

## Interaction — step by step

### Opening the page
1. Page opens (tab or tile tapped) → loading state → call `get_assignments(pending_only=True)` and `get_courses()` in parallel → render both sections.

### Tapping a to-do row (submit flow — in-page, no chat)
2. Student taps anywhere on a to-do row (e.g. "Problem Set 3 – Consensus") → the page shows a **confirm card** in place of (or as an overlay/bottom-sheet over) the current content — coder's choice of presentation, but it must not silently submit without confirmation, since it can't be undone:
   - Card title: "Submit this assignment?" (upload icon, `primaryTint` circle)
   - Body: "Marks it as handed in. You can't undo it." (14, `textMuted`)
   - Row: "Assignment" → "Problem Set 3 – Consensus", "Due" → "Today 23:59 · CS301"
   - Buttons: **Submit it** (primary, `primary` fill) · **Not yet** (secondary, white + `line` border)
3. Student taps **Not yet** → confirm card dismisses, back to the to-do list, nothing changed.
4. Student taps **Submit it** → call `submit_assignment("assign-1")` → on success:
   - Show the **success card**: green check icon, "Assignment submitted", rows "Assignment" → title, "Submitted" → current time (e.g. "Today, 14:58")
   - After the student dismisses it (a "Done" button, or auto-dismiss after ~2s — coder's choice), **remove that row from the To-dos list** and update the section label's count ("3 not submitted" → "2 not submitted")
5. If `submit_assignment` returns `{success: false, ...}` (e.g. double-submit race): show the message from the connector's response in a small inline error, don't crash.

### Tapping a course row (materials drill-in)
6. Student taps a course row (e.g. "CS301 Distributed Systems") → call `get_course_materials("course-cs301")` → show its materials. **For the demo, present this as a full-screen replace of the page content** (title becomes "CS301 · Week 4", with its own back chevron back to the Courses list) rather than a 6th separate route — keeps the routing table simple.
   - Materials card: one row per material — icon by `type` (`presentation` for slides, `book-open` for reading, `video` for video), title with the "(Slides)"/"(Reading)" suffix **stripped** (the type is already shown as a label, not repeated in the title), "Week {n}" as the detail line, type label on the right.
   - Rows for CS301 (Week 4): "Consensus Algorithms" — Slides · "Raft Paper" — Reading.
   - Materials rows are **not tappable** (no real files to open in the mock).
7. Student taps the materials view's back chevron → return to the Courses page (To-dos + My courses), not the Dashboard.

### Leaving the page
8. Student taps a bottom-bar tab → navigate away.
9. Student taps the page header's back chevron (when on the main Courses view, not the materials sub-view) → navigate to Dashboard.

## States

| State | What shows |
|---|---|
| **Loading** | Both section labels shown, 3 skeleton rows under To-dos, 3 under My courses |
| **To-dos empty** (all assignments submitted) | To-dos card replaced with: check icon + "You're all caught up." (15, `textMuted`). Section label becomes "TO-DOS · ALL SUBMITTED" |
| **Error** (either connector fails) | Centered: "Couldn't load your courses." + `Try again` button, retries both calls |
| **Submitting** (between tapping "Submit it" and the response) | Disable both buttons on the confirm card, show a small spinner or dim them to 40% opacity — must not allow a double-tap double-submit |
| **Loaded** | Both sections as specified |

## Edge cases

- A course with 0 pending assignments: still show it in My courses, with "{instructor} · 0 due" (no special-casing needed, just don't say "1 due" when it's 0).
- `submit_assignment` called twice quickly (double-tap): the button-disable in the Submitting state above prevents this; if it still happens, the connector's own guard (`if assignment["submitted"]: return success: false`) means the second call fails gracefully — show its message, don't show a duplicate success card.
- Long assignment titles ("Homework 2 – Fourier Series"): title wraps to 2 lines before truncating.

## Widgets

| Widget | Notes |
|---|---|
| `CoursesPage` | Top-level page; owns both connector calls and the submit flow's local state (pending list, which row is mid-submit) |
| `TodoRow(title, courseLabel, dueLabel, isUrgent, onTap)` | Reused from the chat's to-do card design where possible |
| `CourseRow(code, name, instructor, dueCount, onTap)` | — |
| `SubmitConfirmCard` / `SubmitSuccessCard` | Same visual design as [chat-ui.md § C10](chat-ui.md), reused here without the surrounding chat bubbles |
| `MaterialsView(courseCode, week, materials)` | The drill-in sub-view |
| `BottomBar(active: "courses")` | Shared, see [dashboard.md](dashboard.md) |
