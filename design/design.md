# Design system

Campus Concierge — a single chat screen on a phone. Small system on purpose: **2 fonts, 4 colour roles + neutrals, 4 corner radii**. **Light mode only** (no dark mode for the hackathon). Anything not listed here, don't invent — ask UI/UX first.

Look in one line: **calm, warm paper background, one strong indigo, and amber reserved only for the agent speaking first.**

## Theme at a glance (send this to the team)

**Main theme colour: Indigo `#2B3A8F`**

| Role | Hex | One job |
|---|---|---|
| **Primary** — Indigo | `#2B3A8F` | The brand. User bubbles, send, main buttons, links |
| **Nudge** — Amber | `#8A4B00` on `#FFF1DC` | **Only** when the agent speaks first |
| **Success** — Green | `#1E6B3F` on `#E6F4EC` | An action worked ("Room booked") |
| **Danger** — Red | `#A1331F` | "Cancel booking" only |
| Background | `#F5F3EE` | Chat background |
| Surface | `#FFFFFF` | Header, agent bubbles, cards |
| Text / muted | `#1A1C20` / `#5B5F66` | Main text / timestamps, subtitles |
| Border | `#E3E0D8` | All borders |

**Fonts:** Bricolage Grotesque (headings) + Figtree (body).

**3 rules:** (1) Indigo is the brand, amber is only for nudges. (2) No colours outside this file. (3) No shadows — 1 px borders.

Slides and pitch deck: use the same indigo as the main colour and amber as the highlight, so the deck and the app look like one product.

---

## Fonts

Both are free Google Fonts. In Flutter use the [`google_fonts`](https://pub.dev/packages/google_fonts) package.

| Role | Font | Why |
|---|---|---|
| **Display** — app name, card titles, big numbers (bus ETA) | **Bricolage Grotesque** (600, 700) | Has character, so the app doesn't look like a default template. Used sparingly. |
| **Body** — messages, buttons, labels, everything else | **Figtree** (400, 500, 600, 700) | Friendly, very readable at small sizes on phones. |

### Type scale

| Token | Font | Size / line height | Weight | Used for |
|---|---|---|---|---|
| `welcome` | Bricolage Grotesque | 32 / 38 | 700 | "Welcome, {username}" on the first page only |
| `display` | Bricolage Grotesque | 30 / 32 | 700 | Big numbers only (bus ETA "4 min", in `primary`) |
| `title` | Bricolage Grotesque | 21 / 26 | 700 | Nudge card title |
| `cardTitle` | Bricolage Grotesque | 18 / 24 | 700 | Result card title ("Room booked", "Campus Loop A") |
| `appName` | Bricolage Grotesque | 18 / 24 | 700 | Header |
| `body` | Figtree | 15 / 22 | 400 | Message text |
| `button` | Figtree | 15 / 20 | 600 | Buttons |
| `chip` | Figtree | 14 / 20 | 600 | Suggestion chips |
| `meta` | Figtree | 13–14 / 18 | 400 (600 for values) | Subtitles, card key/value rows (key 400 muted, value 600), info pills (600) |
| `label` | Figtree | 12 / 16 | 600–700 | Time dividers, trace lines, "HEADS UP" (uppercase, +6% letter spacing) |

**Rule:** minimum text size is 12. Never go below.

```dart
final display = GoogleFonts.bricolageGrotesque(fontSize: 30, height: 32 / 30, fontWeight: FontWeight.w700);
final body    = GoogleFonts.figtree(fontSize: 15, height: 22 / 15);
```

---

## Colour

Four roles. Each has one job — don't reuse a colour for a different job.

### Primary — Indigo (the student + the app)
| Token | Hex | Used for |
|---|---|---|
| `primary` | `#2B3A8F` | User bubbles, send button, links, primary buttons, app avatar |
| `primaryTint` | `#EEF0FA` | Suggestion chips, secondary buttons |
| `primaryLine` | `#C9CEE8` | Chip / secondary button border |

### Nudge — Amber (only when the agent speaks first)
| Token | Hex | Used for |
|---|---|---|
| `nudge` | `#8A4B00` | "HEADS UP" label, nudge primary button |
| `nudgeFill` | `#FFF1DC` | Nudge card background |
| `nudgeLine` | `#F2C98B` | Nudge card border |
| `nudgeButtonLine` | `#E0B574` | Nudge secondary button border |

> **Amber is reserved.** Nothing else in the app is amber. That's how judges instantly see "the agent started this, not the student."

### Success — Green (an action worked)
| Token | Hex | Used for |
|---|---|---|
| `success` | `#1E6B3F` | Check icon on result cards |
| `successFill` | `#E6F4EC` | Circle behind the check icon |
| `live` | `#2E8B57` | Small "online" / "live" dots only |

### Danger — Red (destructive only)
| Token | Hex | Used for |
|---|---|---|
| `danger` | `#A1331F` | "Cancel booking" text. Nothing else. |

### Neutrals
| Token | Hex | Used for |
|---|---|---|
| `background` | `#F5F3EE` | Chat background, input fill |
| `surface` | `#FFFFFF` | Header, agent bubbles, cards, composer |
| `text` | `#1A1C20` | Main text |
| `textMuted` | `#5B5F66` | Subtitles, timestamps, trace lines, input placeholder |
| `line` | `#E3E0D8` | Borders, dividers |
| `lineSoft` | `#EFECE5` | Rows inside a card |
| `inputLine` | `#D6D2C8` | Text input border |

### Contrast (checked)
All text pairs pass WCAG AA (4.5:1): white on `primary` ≈ 10:1, `nudge` on `nudgeFill` ≈ 6.5:1, `textMuted` on `background` ≈ 5.9:1, `success` on `successFill` ≈ 5.8:1.

**Colour is never the only signal.** A nudge also has a bell icon and the "HEADS UP" label; the cafe crowd level also shows the word (Low / Medium / High).

```dart
class AppColors {
  static const primary     = Color(0xFF2B3A8F);
  static const primaryTint = Color(0xFFEEF0FA);
  static const primaryLine = Color(0xFFC9CEE8);
  static const nudge       = Color(0xFF8A4B00);
  static const nudgeFill   = Color(0xFFFFF1DC);
  static const nudgeLine   = Color(0xFFF2C98B);
  static const nudgeButtonLine = Color(0xFFE0B574);
  static const success     = Color(0xFF1E6B3F);
  static const successFill = Color(0xFFE6F4EC);
  static const live        = Color(0xFF2E8B57);
  static const danger      = Color(0xFFA1331F);
  static const background  = Color(0xFFF5F3EE);
  static const surface     = Color(0xFFFFFFFF);
  static const text        = Color(0xFF1A1C20);
  static const textMuted   = Color(0xFF5B5F66);
  static const line        = Color(0xFFE3E0D8);
  static const lineSoft    = Color(0xFFEFECE5);
  static const inputLine   = Color(0xFFD6D2C8);
}
```

App-wide theme (put in `MaterialApp(theme: ...)`):
```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.surface,
    error: AppColors.danger,
  ).copyWith(surfaceTint: Colors.transparent), // stops Material 3 tinting white surfaces purple-ish
  scaffoldBackgroundColor: AppColors.background,
  textTheme: GoogleFonts.figtreeTextTheme().apply(bodyColor: AppColors.text, displayColor: AppColors.text),
  appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 0, backgroundColor: AppColors.surface),
)
```

---

## Shape and spacing

| Token | Value | Used for |
|---|---|---|
| `radiusButton` | 12 | Buttons, header icon button |
| `radiusBubble` | 18 (4 on the "tail" corner) | Message bubbles |
| `radiusCard` | 20 | Nudge and result cards |
| `radiusPill` | full | Chips, input, send button |
| Spacing scale | 4 · 8 · 12 · 16 · 20 · 24 | Default for all padding and gaps |
| Spacing exceptions | 6 (icon ↔ text), 10 × 14 (bubble padding), 14 (gap inside result cards) | Only these three places |
| Touch target | ≥ 44 × 44 | Every tappable thing |
| Border | 1 px | Everywhere a border is used |

**No shadows.** Separation comes from 1 px borders and the background colour. Flat is faster to build and looks cleaner on a projector.

## States

| State | How it looks |
|---|---|
| Pressed | Darken fill ~10% (Flutter default ink splash is fine) |
| Disabled | 40% opacity — send button when input is empty; nudge buttons after one is tapped |
| Loading | 3 animated dots in an agent bubble |

## Motion

| What | Animation |
|---|---|
| New message | Fade + slide up 8 px, 200 ms |
| Nudge card arrives | Slide up from bottom, 250 ms, ease-out + light haptic (`HapticFeedback.lightImpact()`) |
| Everything else | No animation — keep it simple |

## Icons

Simple 2 px stroke icons (Lucide style — Flutter: [`lucide_icons`](https://pub.dev/packages/lucide_icons)). **No emoji.**

| Icon | Where |
|---|---|
| `bell` | Nudge label |
| `check` | Success on result cards |
| `clock` | Time pills |
| `map-pin` | Location pills ("Library 2F") |
| `users` | Seats pill ("4 seats") |
| `bus` | Bus card |
| `coffee` | Cafe crowd card |
| `square` (empty) | Unchecked to-do |
| `square-check` | Header to-do button |
| `house` | Home button (back to dashboard) |
| `calendar` | Dashboard "Next event" tile |
| `stethoscope` | Clinic slots card |
| `x` | Close the to-do sheet |
| `search` | Welcome search bar |
| `wrench` | Agent trace line |
| `send` | Send button |
