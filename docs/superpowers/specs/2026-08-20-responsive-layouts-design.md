# Responsive Layouts — Phones & Tablets

**Date:** 2026-08-20
**Status:** Approved (brainstorm)
**Scope:** Architectural — adaptive layouts across all screens + shell + scale-aware typography
**Repo:** waradu-alsala (ورد الصلاة / Wardu as-Sala)

## Summary

Make the ornamental Salawat app adapt cleanly across phone widths (compact,
~320–600dp) and tablet/large-screen widths (expanded, ≥841dp): no overflow,
fixed font sizes that scale rather than clip, a centered max-width on Home
and Settings so content doesn't stretch grotesquely wide, and a two-pane
layout for Stats on tablets. Keep the custom decorative shell and bottom-nav
on all sizes (a counter app is one-handed even on tablet). No new package
dependencies; all adaptation is `LayoutBuilder`/`MediaQuery` + a shared
breakpoints helper. **No logic changes** — every counter, reminder, backup,
and stats computation keeps its current behavior; this is pure layout +
typography adaptation on top of the existing redesign.

## Goals

- No layout overflow on any width from 320dp up.
- Fixed large font sizes (the 88px count number) scale by width instead of
  clipping on small phones or looking tiny on tablets.
- Tablet users get a richer, intentional layout (two-pane Stats), not a
  stretched phone screen.
- Single source of truth for breakpoint thresholds and content max-widths.
- Respect OS accessibility text scaling (`MediaQuery.textScaler`).

## Non-goals

- No web/desktop very-wide-window behavior beyond max-width capping.
- No `NavigationRail` / adaptive-scaffold package — the ornamental bottom-nav
  stays on all sizes.
- No new features or logic changes.
- No new locale support beyond the existing `ar_SA`.

---

## Section 1 — Breakpoints helper

New `lib/utils/breakpoints.dart` — the single source of truth for
width-based adaptation. Pure constants + tiny helpers, no widgets.

```dart
class Breakpoints {
  Breakpoints._();

  /// Smallest target phone (e.g. small Android / iPhone SE).
  static const double compactMax = 400;      // <=400  → compact (very small)
  /// Typical phone.
  static const double mediumMax = 600;      // 401–600 → medium (phone)
  /// Small tablet / large phone landscape.
  static const double expandedMax = 840;    // 601–840 → expanded (small tablet)
  // >=841 → wide (tablet)

  /// Two-pane layouts kick in here.
  static const double twoPaneMin = 840;

  /// Content max-widths so columns don't stretch on tablets.
  static const double homeMaxWidth = 520;
  static const double settingsMaxWidth = 560;

  static bool isCompact(double width) => width <= compactMax;
  static bool isMedium(double width) => width > compactMax && width <= mediumMax;
  static bool isExpanded(double width) => width > mediumMax && width <= expandedMax;
  static bool isWide(double width) => width > expandedMax;
  static bool useTwoPane(double width) => width >= twoPaneMin;
}
```

Also a tiny reusable widget in the same file:

```dart
/// Centers its child and caps content width on wide screens.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({super.key, required this.maxWidth, required this.child});
  final double maxWidth;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
```

All screens import `Breakpoints` and read the width once per build via
`MediaQuery.sizeOf(context).width` (or `LayoutBuilder` where a child needs
the *available* width, e.g. the chart).

---

## Section 2 — Scale-aware typography

The current `AppTextStyles` uses fixed sizes; the 88px `kufiNumber` is the
biggest overflow risk (on a 320dp phone with a large count like `9999`, the
text overflows the card). Make the styles width-aware without breaking the
existing call sites.

`lib/utils/app_text_styles.dart` changes:

- Keep the existing 5 method names and signatures (`bismillah`, `display`,
  `kufiNumber`, `bodyArabic`, `uiLabel`) so all screens compile unchanged.
- Inside each, derive a **scale factor** from `MediaQuery.sizeOf(context).width`:
  - compact (≤400): factor `0.82`
  - medium (401–600): factor `1.0` (current sizes)
  - expanded (601–840): factor `1.12`
  - wide (≥841): factor `1.18`
- Multiply the fixed fontSize by the factor. For `kufiNumber` specifically,
  also clamp the *rendered* size so a very long count can't exceed the card:
  the helper returns the scaled size, and Home additionally applies
  `FittedBox(fit: BoxFit.scaleDown)` around the count `Text` so the number
  always fits its column width regardless of digit count.
- Each style also composes with `MediaQuery.textScalerOf(context)` so OS
  accessibility scaling still applies on top of the width factor. (Flutter's
  `TextStyle` fontSize is automatically scaled by `textScaler` when rendered
  via `Text`, so no manual multiply is needed for accessibility — only the
  width factor is manual. Document this in the file.)

`AppTextStyles` gains one internal helper:

```dart
static double _scaleFor(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w <= Breakpoints.compactMax) return 0.82;
  if (w <= Breakpoints.mediumMax) return 1.0;
  if (w <= Breakpoints.expandedMax) return 1.12;
  return 1.18;
}
```

No new public API beyond what exists; existing call sites stay valid.

---

## Section 3 — Home screen adaptation

Home becomes a **centered max-width column** on all sizes (capped at
`Breakpoints.homeMaxWidth` = 520), wrapped in `MaxWidthBox`. On a phone this
is a no-op (content is already narrower than 520); on a tablet the card and
button stop at 520 and center, so the mihrab centerpiece stays proportional.

Changes in `lib/screens/home_screen.dart`:

- Outer `Container`/`SafeArea`/`SingleChildScrollView` stays; insert
  `MaxWidthBox(maxWidth: Breakpoints.homeMaxWidth)` between the scroll view
  and the `Column` so the whole stack is centered+constrained.
- Padding: replace `EdgeInsets.all(24.0)` with width-aware padding via a
  local helper using `Breakpoints`: compact `16`, medium `24`, expanded+ `24`
  (horizontal centering handles the rest). Read width once in `build`.
- Counter card: keep `width: double.infinity` (fills the capped 520), keep
  `MihrabArch` + pattern. Add `FittedBox(fit: BoxFit.scaleDown)` around the
  count `Text` so multi-digit counts never overflow the card column.
- Segmented progress: unchanged (it's already an `Expanded`-based `Row` of
  flexible segments — adapts naturally).
- Tap-to-count button: keep full-width within the capped column; padding
  scales with the width-aware padding helper (compact a touch less vertical).
- Medallion counter chips: already a horizontal `ListView` — no change
  needed (scrolls if many counters).

No logic changes — `Consumer2`, `increment`, `undo`, `reset`,
`notifyDailyTargetReached`, haptics all untouched.

---

## Section 4 — Stats screen adaptation (two-pane on tablet)

Stats gets the richest adaptation: single column on phones, **two-pane on
wide screens** (`Breakpoints.useTwoPane`, ≥840).

Changes in `lib/screens/stats_screen.dart`:

- Wrap content in `MaxWidthBox`? **No** — Stats is the one screen that
  *uses* the wide space (two-pane), so it is NOT max-width capped. Instead
  it reads `width` and switches layout.
- **Single column (width < 840):** current structure — `SegmentedButton`,
  chart (220 → width-scaled height), 3-tile `Row`, then 2-tile `Row` below
  a `GoldHairlineDivider`. Keep as-is except:
  - Chart `SizedBox` height scales: compact 180, medium 220, expanded+ 260
    (via a small helper).
  - The 3-tile `Row` becomes a `Wrap` (or stays `Row` of `Expanded` — `Row`
    of 3 `Expanded` already works down to ~320; keep `Row`).
- **Two-pane (width ≥ 840):** an `IntrinsicHeight` + `Row` with two
  `Expanded` children:
  - Left pane: the chart card (`Expanded` with the chart at a taller height,
    e.g. 320).
  - Right pane: a `SingleChildScrollView` `Column` with the `SegmentedButton`
    on top, then all summary medallion tiles in a `Wrap`/grid (3 across),
    then the streak row.
  - The `SegmentedButton` can sit above the split (spanning full width) or
    in the right pane; simpler: keep it spanning full width above the
    `Row`, then the two panes below. This keeps the 7/30 toggle prominent.
- Medallion tiles (`_medallionTile`): unchanged widget; placed in `Row` of
  `Expanded` on single-column, in a `Wrap`/grid inside the right pane on
  two-pane. The tile's fixed `padding: all(12)` and `fontSize: 28` already
  adapt; optionally scale the number font via `AppTextStyles` (already
  width-aware after Section 2).

No logic changes — `lastDaysCounts`, `windowSum`, `bestDay`, `currentStreak`,
`longestStreak`, `_days` state all untouched.

---

## Section 5 — Settings & About adaptation

### Settings (`lib/screens/settings_screen.dart`)

- Wrap the `ListView` body in `MaxWidthBox(maxWidth: Breakpoints.settingsMaxWidth)`
  (560). On phones this is a no-op; on tablets the list centers and stops
  stretching. Simplest, consistent, no two-pane grouping (a settings list is
  fine single-column at 560 even on a tablet).
- Padding: width-aware via the same helper (compact 16, else 16 — settings
  already uses 16; keep 16, no change needed). No other layout change.

### About (`lib/screens/about_screen.dart`)

- Already a centered `SingleChildScrollView` `Column`. Wrap its body in
  `MaxWidthBox(maxWidth: 560)` so the salawat quote and feature rows don't
  stretch on tablets. The feature rows (`_buildFeatureItem`) are `Row`s with
  `Expanded` text — they adapt. No two-pane; About stays a single centered
  column (it's a short informational screen).

No logic changes anywhere in Settings/About — all dialogs, export, restore,
reminder flows untouched.

---

## Section 6 — Shell & bottom-nav

`lib/widgets/decorative_app_shell.dart`:

- Header: keep full-width on all sizes (it's a decorative band). The title
  font already goes through `AppTextStyles.display` (now width-aware), so it
  scales. No structural change.
- Bottom-nav: **keep on all sizes**. A counter app is one-handed even on a
  tablet; swapping to a `NavigationRail` adds complexity and breaks the
  ornamental pill design for little gain. Optionally increase horizontal
  pill padding on wide screens (e.g. `Expanded`/`Spacer` between pills) so
  the 3 pills don't hug the far edges — wrap the `Row` in a `MaxWidthBox`
  (max ~480) and center, keeping the pill bar visually tight on tablets.
- No change to `IndexedStack` state-preservation behavior.

---

## Section 7 — Testing approach

Responsive work is layout-only; existing logic tests (increment, reset,
target, backup, stats computations) keep passing unchanged. New tests are
cheap widget smoke tests at specific widths using `tester.view.physicalSize`
+ `devicePixelRatio`:

- `test/responsive_test.dart`:
  - Home renders without overflow at `Size(320, 640)` (very small phone) —
    `find.byType(HomeScreen)` renders, `tester.takeException()` is null, no
    `RenderFlex overflow` errors.
  - Home centers content at `Size(1200, 800)` (tablet) — the counter card
    width is ≤ 520 (assert the `MihrabArch` widget's rendered width is
    bounded, or assert no exception + a max-width `ConstrainedBox` present).
  - Stats two-pane: at `Size(1200, 800)`, both panes render (assert two
    chart/tile containers present, no overflow). At `Size(400, 800)`,
    single column (assert chart present, no second pane).
  - `AppTextStyles.kufiNumber` returns a smaller fontSize at compact width
    than at wide width (a unit-style widget test pumping a `MaterialApp`
    at two sizes and comparing the returned `TextStyle.fontSize`).
- Existing widget tests already set a default test surface size (~800x600
  in some, 800x1600 in `settings_backup_test`); they keep passing. Verify
  none break due to `MaxWidthBox`/`LayoutBuilder` inserts — they shouldn't,
  since max-width capping is a no-op below the cap.
- **Verification gate:** full `flutter test` suite passes, plus the new
  responsive smoke tests. `flutter analyze lib` stays at 0 errors/warnings.

### Scope & risk

- Touches all 4 screens + shell + `AppTextStyles` + new `breakpoints.dart`.
  Mechanically simple: width reads + `MaxWidthBox` wraps + one two-pane
  branch in Stats + scaling math in text styles. No data/logic changes.
- Main risk: the `FittedBox` around the count + width-aware font scaling
  interacting with the count-pop `Transform.scale` animation — verify the
  pop animation still looks right (the `FittedBox` wraps the `AnimatedBuilder`
  child, so scaling is composed correctly). Test the increment animation at
  small width to confirm no jank/overflow.
- Second risk: existing widget tests that set custom `tester.view` sizes
  (800x1600) now hit the two-pane Stats path — confirm the stats test
  (which taps `الإحصائيات` and asserts the chart + labels) still passes at
  that size (it should — two-pane still shows the chart and the same labels).

---

## Verification gate

`flutter test` (full suite) must pass. New `responsive_test.dart` must pass.
`flutter analyze lib` stays at 0 errors/warnings. No logic files
(`lib/providers/*`, `lib/models/*`, `lib/services/*`, `lib/utils/stats.dart`,
`lib/utils/app_strings.dart`) modified.

## Next step

Transition to `writing-plans` skill to create the implementation plan.
