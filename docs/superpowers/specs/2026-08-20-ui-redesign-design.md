# UI Redesign — Elegant & Ornamental Islamic Theme

**Date:** 2026-08-20
**Status:** Approved (all 5 design sections)
**Scope:** Architectural — full visual identity + app-shell/navigation restructure
**Repo:** waradu-alsala (ورد الصلاة / Wardu as-Sala)

## Summary

Redesign the Salawat counter app into an elegant, ornamental Islamic aesthetic: deep
emerald + antique gold, real calligraphic fonts, and code-drawn Islamic geometric
patterns. Restructure navigation from per-screen AppBars + named routes into a
single decorative app shell with 3 bottom-nav tabs. The home counter becomes a
mihrab-arched centerpiece. **No logic changes** — every counter, reminder, backup,
and stats computation keeps its current behavior; this is pure presentation +
navigation restructure.

## Goals

- Professional, polished, distinctly Islamic visual identity.
- Real calligraphic typography (Amiri) and geometric numerals (Reem Kufi).
- Code-drawn Islamic geometric motifs (8-point star / Khatam tessellation, mihrab
  arches, gold hairline dividers) — no external image assets.
- Cleaner navigation via a decorative bottom-nav shell.

## Non-goals

- No new features (no new counters, reminders, or stats computations).
- No data model or provider changes.
- No external SVG/PNG pattern assets (motifs are drawn in code).
- No new locale support beyond the existing `ar_SA`.

---

## Section 1 — Visual identity

### Color palette

Replaces the current palette in `lib/utils/app_theme.dart`.

| Token | Light | Dark | Replaces |
|---|---|---|---|
| Emerald primary | `#0B4D2C` | `#14794A` | `#1B5E20` |
| Emerald deep | `#073322` | `#0B4D2C` | `#0D3B0D` |
| Gold accent | `#C9A24B` | `#E6C976` | `#D4AF37` |
| Gold light | `#E6C976` | `#F2DFA0` | `#F5E6B8` |
| Cream surface | `#FAF6EC` | — | `#FFFBF0` |
| Night surface | — | `#0E1F15` | `#0D3B0D` |
| Ink (body, light) | `#1A2E1F` | — | `Colors.black87` |
| Parchment (on-night) | — | `#E8E2D0` | `Colors.white70` |

### Fonts

Bundled under `assets/fonts/` and wired in `pubspec.yaml`. The app currently
references `fontFamily: 'Amiri'` in several screens with **no font declared in
pubspec** — those are no-ops falling back to system fonts. This redesign makes
the calligraphic look real.

- **Amiri** (OFL, Google Fonts) — Arabic display/calligraphy. Bismillah, salawat
  text, counter name, section headers. Weights: Regular + Bold.
  - `assets/fonts/Amiri-Regular.ttf`
  - `assets/fonts/Amiri-Bold.ttf`
  - Download: https://fonts.google.com/specimen/Amiri
- **Reem Kufi** (OFL, Google Fonts) — geometric Kufi for numerals + UI labels.
  Big count number, stats numerals, button labels. Weights: Regular + Medium.
  - `assets/fonts/ReemKufi-Regular.ttf`
  - `assets/fonts/ReemKufi-Medium.ttf`
  - Download: https://fonts.google.com/specimen/Reem+Kufi

**Buildability note:** The .ttf files cannot be fetched from this environment.
All integration code and pubspec entries will be written expecting the files at
the paths above. Until the .ttfs are present, Flutter falls back to system fonts —
the app still runs and tests pass; it just won't show the calligraphic type until
the files are added.

### Text styles

New `lib/utils/app_text_styles.dart` exposing a named style map so screens
reference semantics instead of hardcoded `fontFamily`/sizes:

- `bismillah` — Amiri gold, large, centered.
- `display` — Amiri gold, section headers.
- `kufiNumber` — Reem Kufi, very large, primary color.
- `bodyArabic` — Amiri/Reem Kufi body text.
- `uiLabel` — Reem Kufi, button labels.

### Islamic geometric motifs (code-drawn)

All drawn with `CustomPaint` + `Path`/`Canvas` — zero external image assets.

- **IslamicPattern** (`lib/widgets/islamic_pattern.dart`) — 8-pointed star (Khatam)
  tessellation as a faint low-opacity background layer. Parameterized by opacity +
  color to adapt to light/dark. Used behind app header, counter card, about emblem,
  stats chart card.
- **MihrabArch** (`lib/widgets/mihrab_arch.dart`) — rounded mihrab/arch shape on the
  top edge, used to top the counter card and the about emblem. Gold outline.
- **Gold hairline dividers** — 1px gold line with a small centered 8-point star
  node, between sections.

---

## Section 2 — App shell & navigation (full restructure)

### Decorative app shell

New `lib/widgets/decorative_app_shell.dart` — a persistent custom Scaffold:

- **No default AppBar.** A custom decorative header band: a mihrab-arch shape
  drawn in code (gold outline on emerald) containing the app name in Amiri + a
  faint 8-point-star pattern behind it. Full header on Home only; sub-screens get
  a slimmer arch title bar.
- **Bottom navigation:** a 3-tab ornamental pill bar floating with a gold top
  hairline — الرئيسية (Home, mosque icon), الإحصائيات (Stats, bar_chart),
  الإعدادات (Settings, settings). Active tab gets a small gold star node above
  its label instead of the Material underline.
- **About moves into Settings** as the last tile ("حول التطبيق") — the separate
  `/about` route is removed.

### Navigation mechanics

`lib/main.dart` changes from 4 named routes to an `IndexedStack` of 3 screens
inside `DecorativeAppShell`, so tabs preserve state (counter, stats range
selection) when switching. The routes map is removed. About is reached via an
inline `Navigator.push` from Settings, not a shell tab.

The existing `CountersProvider`/`SettingsProvider` wiring in `main.dart` stays
untouched — the shell is purely presentation.

### Files

- New: `lib/widgets/decorative_app_shell.dart`
- New: `lib/widgets/islamic_pattern.dart`
- New: `lib/widgets/mihrab_arch.dart`
- Modify: `lib/main.dart` (IndexedStack shell, drop `/about` route)
- Modify: each screen (remove own Scaffold/AppBar, become body-only content)

---

## Section 3 — Home screen redesign (centerpiece)

The home becomes the signature screen. Top to bottom:

- **Bismillah band** — "بسم الله الرحمن الرحيم" in Amiri gold, centered, with a
  thin gold hairline + star divider beneath. Smaller than today.
- **Counter switcher** — restyled from flat `ChoiceChip`s into rounded "medallion"
  chips: active = gold ring + emerald fill; others = outlined cream with gold text.
  Same data (`counters.counters`), same `setActive` call. "+ إضافة" ActionChip
  restyled.
- **Counter card (centerpiece)** — large card with mihrab-arch top edge:
  - Counter name in Amiri gold.
  - Big count number in Reem Kufi, ~88px, emerald (light) / gold (dark) — the
    visual anchor.
  - "اليوم" label + "الإجمالي: N" beneath, smaller, secondary color.
  - Target progress: replace flat `LinearProgressIndicator` with **decorative
    segmented progress** — N small gold segments filling toward the target (tasbih
    beads). "N / target" centered below. On target met, segments glow + a small
    "تم الهدف" badge with a star appears.
  - Streak: small pill "🔥 N يوم متتالي" restyled (gold fire icon on cream).
  - Faint 8-point-star pattern behind the card content at ~4% opacity.
- **Tap-to-count button** — large circular/wide-rounded emerald button with a
  subtle gold inner border + small star motif. Existing scale animation plays.
  Label "اضغط للعد" in Reem Kufi white. Big count animates a brief scale/pop on
  each increment (new short Tween via the existing `SingleTickerProviderStateMixin`
  controller).
- **Undo / Reset** — two outlined gold text-buttons in a row beneath, replacing
  the current `ElevatedButton.icon` pair. Reset keeps its confirmation dialog.

### Behavior (unchanged)

All logic stays: `counters.increment/undo/reset`,
`settings.settings.vibrationEnabled` → `HapticFeedback`, target-reached
`notifyDailyTargetReached`. Only presentation changes.

### Files

Rewrite `lib/screens/home_screen.dart`. Consume new widgets
(`mihrab_arch`, `islamic_pattern`, `AppTextStyles`). Provider wiring identical.

---

## Section 4 — Stats, Settings, About

Restyle onto the new identity and adapt to the shell.

### Stats screen (`lib/screens/stats_screen.dart`)

- Slimmer arch title bar from the shell (no per-screen AppBar). Title "الإحصائيات"
  in Amiri gold.
- 7/30-day `SegmentedButton` restyled (emerald selected, cream unselected).
- fl_chart bars recolored emerald with gold tips; grid lines faint gold; axis
  labels in Reem Kufi numerals. Card gets a thin gold border + rounded corners.
- Summary tiles (window sum, best day, current/longest streak) → small medallion
  tiles with star dividers between. Same data, restyled.
- 8-point-star pattern faint behind the chart card.

### Settings screen (`lib/screens/settings_screen.dart`, ~609 lines)

- Section headers ("العداد الحالي", "التذكيرات", "النسخ الاحتياطي", etc.) → Amiri
  gold with a gold hairline divider beneath, replacing `_buildSectionTitle`.
- ListTiles: leading icons in small gold-ringed circles (medallions) instead of
  bare icons. Tiles keep their existing onTap dialogs (rename, daily target,
  reminder type, export/restore) — dialogs restyle to new palette/fonts, identical
  logic.
- Switches recolored emerald/gold.
- **About is the final tile here:** "حول التطبيق" → pushes a restyled About as a
  full screen (`about_screen.dart` content), not a shell tab.

### About screen (`lib/screens/about_screen.dart`)

- Rendered inside the shell's arch header (pushed from Settings). Big mosque icon
  container → mihrab-arch framed emblem with 8-point-star pattern behind, gold
  border.
- Salawat text in Amiri gold, larger, centered as a calligraphic quote with gold
  hairline dividers above/below.
- Feature items restyle to gold-ringed medallion icons, matching settings rows.
- Footer "صُنع بحب..." in gold italic.

### No logic changes

Every dialog, export, reminder, and stat computation keeps its current behavior.
Only colors, fonts, shapes, and decorative widgets change.

---

## Section 5 — Assets, fonts, buildability, testing

### Fonts (the one external dependency)

- Buildability plan: I write all integration code + pubspec entries expecting the
  font files at exact paths; you drop the .ttf files in before building.
- Files needed in `assets/fonts/`:
  - `Amiri-Regular.ttf`, `Amiri-Bold.ttf`
  - `ReemKufi-Regular.ttf`, `ReemKufi-Medium.ttf`
- Wire `pubspec.yaml` (`flutter.fonts` section + `assets/` entries) + create
  `lib/utils/app_text_styles.dart`. Until .ttfs present, Flutter falls back to
  system fonts — app runs, tests pass; calligraphic type appears once files added.
- Download links documented in this spec (Section 1, Fonts).

### Patterns (code-drawn, no external assets)

- 8-point-star Khatam tessellation, mihrab arch, gold hairline dividers, star
  nodes — all Flutter `CustomPaint` + `Path`/`Canvas` in `lib/widgets/`. Zero
  external image assets. The ornamental look is fully buildable from code alone;
  only the fonts are external.

### Testing approach

- Redesign is pure presentation. Existing widget tests
  (`test/widget_test.dart`, `settings_backup_test.dart`,
  `counters_provider_widget_test.dart`) exercise logic (increment, reset, target,
  backup) via finders + provider behavior — must keep passing unchanged because
  logic is untouched. **Full `flutter test` suite is the verification gate.**
- New widget tests for decorative widgets: `islamic_pattern` renders without
  error, `mihrab_arch` renders, `decorative_app_shell` switches tabs and preserves
  state. Cheap CustomPaint/widget smoke tests.
- No new logic to TDD — the redesign adds no features, so the test burden is
  "nothing broke + new widgets render."

### Scope & risk

- Touches every screen + `main.dart` + theme + new widgets. Large but
  mechanically simple: restyling + navigation restructure, no data/logic changes.
- Main risk: About-route removal + shell wiring in `main.dart`. The `/about`
  named route is removed; About is reachable only via the Settings tile push. This
  is acceptable since the app has no external deep links pointing at `/about`
  (verified: no intent filters, no push notification routes reference it).
- Working tree is dirty with prior refactor + backup work. The redesign commits
  on a new branch off the current state, touching only redesign-related files
  (not unrelated dirty changes).

---

## Verification gate

`flutter test` (full suite) must pass. New decorative-widget smoke tests must
pass. Existing logic tests unchanged.

## Next step

Transition to `writing-plans` skill to create the implementation plan.
