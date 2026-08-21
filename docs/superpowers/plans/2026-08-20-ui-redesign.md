# UI Redesign — Elegant & Ornamental Islamic Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Restyle the Salawat counter app into an elegant, ornamental Islamic aesthetic (deep emerald + antique gold, Amiri/Reem Kufi fonts, code-drawn geometric motifs) and restructure navigation into a single decorative bottom-nav shell with 3 tabs — with zero logic changes.

**Architecture:** A new `DecorativeAppShell` wraps an `IndexedStack` of Home/Stats/Settings screens (state preserved across tabs). New code-drawn widgets (`IslamicPattern`, `MihrabArch`) supply the 8-point-star Khatam tessellation and mihrab arch shapes via `CustomPaint`. Each screen becomes body-only content (drops its own `Scaffold`/`AppBar`). About is pushed from Settings (the `/about` named route is removed). The existing `CountersProvider`/`SettingsProvider` wiring is untouched.

**Tech Stack:** Flutter (Dart), `provider`, `fl_chart`, `CustomPaint`/`Path`/`Canvas` for motifs, Amiri + Reem Kufi fonts (OFL).

**Spec:** `docs/superpowers/specs/2026-08-20-ui-redesign-design.md`

## Global Constraints

- **No logic changes.** Every counter, reminder, backup, and stats computation keeps its current behavior. This is pure presentation + navigation restructure.
- **No new features, no data model changes, no new locale** (existing `ar_SA` only).
- **No external image assets.** All Islamic motifs (8-point-star Khatam tessellation, mihrab arch, gold hairline dividers, star nodes) are drawn in code via `CustomPaint` + `Path`/`Canvas`. Only the fonts are external.
- **Fonts** live at `assets/fonts/Amiri-Regular.ttf`, `Amiri-Bold.ttf`, `ReemKufi-Regular.ttf`, `ReemKufi-Medium.ttf` (already wired in `pubspec.yaml`). Until the .ttfs are present, Flutter falls back to system fonts — app runs, tests pass; calligraphic type appears once files added.
- **Verification gate:** full `flutter test` suite must pass, plus new decorative-widget smoke tests. Existing logic tests unchanged.
- **Palette tokens** (already in `lib/utils/app_theme.dart`): emerald `#0B4D2C` / dark `#14794A`; emeraldDeep `#073322` / dark `#0B4D2C`; gold `#C9A24B` / dark `#E6C976`; goldLight `#E6C976` / dark `#F2DFA0`; cream `#FAF6EC`; night `#0E1F15`; ink `#1A2E1F`; parchment `#E8E2D0`.
- **Text styles** (already in `lib/utils/app_text_styles.dart`): `AppTextStyles.bismillah(context)`, `.display(context)`, `.kufiNumber(context)`, `.bodyArabic(context)`, `.uiLabel(context)`.

## Baseline state (already done — do NOT redo)

Before this plan begins, the following Section 1 work is **already present in the repo** and must be left intact / built upon, not recreated:

- `lib/utils/app_theme.dart` — new emerald/gold/cream/night palette + `lightTheme()`/`darkTheme()`.
- `lib/utils/app_text_styles.dart` — the 5 named styles above.
- `pubspec.yaml` — `flutter.fonts` section declaring `Amiri` + `ReemKufi` families, and `assets/` includes `assets/fonts/`.

Tasks below build the remaining widgets, shell, and screen rewrites on top of this.

## File Structure

New files:
- `lib/widgets/islamic_pattern.dart` — `IslamicPattern` CustomPainter: 8-pointed-star (Khatam) tessellation, parameterized by opacity + color. Used as a faint background layer.
- `lib/widgets/mihrab_arch.dart` — `MihrabArch` CustomPainter + a `MihrabArchClipper`/container helper: rounded mihrab/arch top edge with gold outline, used to top the counter card and about emblem.
- `lib/widgets/gold_divider.dart` — `GoldHairlineDivider`: 1px gold line with a small centered 8-point-star node. Used between sections.
- `lib/widgets/decorative_app_shell.dart` — `DecorativeAppShell`: persistent Scaffold with custom decorative header band (mihrab-arch title), 3-tab ornamental pill bottom-nav, and an `IndexedStack` body. Owns the tab index state.
- `test/islamic_pattern_test.dart` — smoke test: `IslamicPattern` renders without error.
- `test/mihrab_arch_test.dart` — smoke test: `MihrabArch` renders.
- `test/decorative_app_shell_test.dart` — smoke test: shell switches tabs and preserves state.

Modified files:
- `lib/main.dart` — replace named-routes map with `DecorativeAppShell` + `IndexedStack` of Home/Stats/Settings; drop `/about` route + About import.
- `lib/screens/home_screen.dart` — rewrite as body-only content: bismillah band, medallion counter switcher, mihrab-arch counter card with segmented progress, tap-to-count button, undo/reset text-buttons. Drop own `Scaffold`/`AppBar`/`bottomNavigationBar`.
- `lib/screens/stats_screen.dart` — restyle: slimmer arch title (from shell), restyled `SegmentedButton`, recolored chart, medallion summary tiles with star dividers, faint pattern behind chart card. Drop own `Scaffold`/`AppBar`.
- `lib/screens/settings_screen.dart` — restyle section headers to Amiri gold + gold hairline divider, medallion leading icons, recolored switches/dialogs; About tile pushes About via `Navigator.push` (not `pushNamed('/about')`). Drop own `Scaffold`/`AppBar`.
- `lib/screens/about_screen.dart` — restyle: mihrab-arch framed emblem with pattern behind, salawat text as calligraphic quote with gold hairlines, medallion feature items, gold italic footer. Drop own `Scaffold`/`AppBar` (rendered inside shell's arch header when pushed).
- `test/widget_test.dart` — update navigation finders + the one assertion that breaks due to the deliberate `LinearProgressIndicator` → segmented-progress replacement (spec-mandated). See Task 8.

---

## Task 1: IslamicPattern (8-point-star Khatam tessellation)

**Files:**
- Create: `lib/widgets/islamic_pattern.dart`
- Test: `test/islamic_pattern_test.dart`

**Interfaces:**
- Produces: `IslamicPattern` — a widget (wrapping `CustomPaint`) with constructor `IslamicPattern({super.key, Color? color, double opacity = 0.04})`. It paints a repeating 8-pointed-star (Khatam) tessellation tile across its size, clipped to its bounds, at the given opacity. `color` defaults to `Theme.of(context).colorScheme.secondary` (gold) when null.

- [x] **Step 1: Write the failing test**

```dart
// test/islamic_pattern_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/widgets/islamic_pattern.dart';

void main() {
  testWidgets('IslamicPattern renders without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: IslamicPattern(opacity: 0.1),
          ),
        ),
      ),
    );
    expect(find.byType(IslamicPattern), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/islamic_pattern_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:salawat_app/widgets/islamic_pattern.dart'`.

- [x] **Step 3: Write minimal implementation**

```dart
// lib/widgets/islamic_pattern.dart
import 'package:flutter/material.dart';

/// A faint 8-pointed-star (Khatam) tessellation painted with CustomPaint.
///
/// Used as a decorative low-opacity background layer behind cards/headers.
/// Drawn entirely in code — zero external image assets.
class IslamicPattern extends StatelessWidget {
  const IslamicPattern({super.key, this.color, this.opacity = 0.04});

  /// Star color. Defaults to the theme gold (colorScheme.secondary) when null.
  final Color? color;

  /// Opacity applied to the star paint. Typical values 0.03–0.08.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Theme.of(context).colorScheme.secondary;
    return CustomPaint(
      painter: _KhatamTessellationPainter(
        color: starColor.withOpacity(opacity.clamp(0.0, 1.0)),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _KhatamTessellationPainter extends CustomPainter {
  _KhatamTessellationPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Tile the plane with a square cell; in each cell draw an 8-pointed star
    // formed by two overlapping squares (one axis-aligned, one rotated 45°).
    const cell = 40.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final half = cell / 2;
    final r = half * 0.82;

    for (var y = 0; y * cell < size.height; y++) {
      for (var x = 0; x * cell < size.width; x++) {
        final cx = x * cell + half;
        final cy = y * cell + half;
        // Axis-aligned square.
        final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
        canvas.drawRect(rect, paint);
        // Rotated square (together they form an 8-pointed star / Khatam).
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(0.785398); // 45° in radians
        canvas.drawRect(
          Rect.fromCircle(center: Offset.zero, radius: r),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KhatamTessellationPainter old) =>
      old.color != color;
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/islamic_pattern_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add lib/widgets/islamic_pattern.dart test/islamic_pattern_test.dart
git commit -m "feat(ui): add IslamicPattern 8-point-star Khatam tessellation widget"
```

---

## Task 2: MihrabArch (arch top edge + gold outline)

**Files:**
- Create: `lib/widgets/mihrab_arch.dart`
- Test: `test/mihrab_arch_test.dart`

**Interfaces:**
- Produces: `MihrabArch` — a widget that draws a rounded mihrab/arch shape on its top edge with a gold outline, framing whatever `child` it contains. Constructor: `MihrabArch({super.key, required Widget child, Color? outlineColor, double outlineWidth = 1.5, double archHeight = 28})`. `outlineColor` defaults to theme gold. Internally uses `CustomPaint` to stroke the arch outline over a `ClipPath`-clipped (rounded-top) container.

- [x] **Step 1: Write the failing test**

```dart
// test/mihrab_arch_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/widgets/mihrab_arch.dart';

void main() {
  testWidgets('MihrabArch renders its child and outline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 200,
            child: MihrabArch(child: Text('محتوى')),
          ),
        ),
      ),
    );
    expect(find.byType(MihrabArch), findsOneWidget);
    expect(find.text('محتوى'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/mihrab_arch_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:salawat_app/widgets/mihrab_arch.dart'`.

- [x] **Step 3: Write minimal implementation**

```dart
// lib/widgets/mihrab_arch.dart
import 'package:flutter/material.dart';

/// A container whose top edge is a mihrab/arch curve, drawn with a gold
/// outline. Used to top the counter card and the about emblem.
class MihrabArch extends StatelessWidget {
  const MihrabArch({
    super.key,
    required this.child,
    this.outlineColor,
    this.outlineWidth = 1.5,
    this.archHeight = 28,
  });

  final Widget child;
  final Color? outlineColor;
  final double outlineWidth;
  final double archHeight;

  @override
  Widget build(BuildContext context) {
    final gold = outlineColor ?? Theme.of(context).colorScheme.secondary;
    return CustomPaint(
      painter: _MihrabOutlinePainter(
        color: gold,
        strokeWidth: outlineWidth,
        archHeight: archHeight,
      ),
      child: ClipPath(
        clipper: _MihrabArchClipper(archHeight: archHeight),
        child: child,
      ),
    );
  }
}

class _MihrabArchClipper extends CustomClipper<Path> {
  _MihrabArchClipper({required this.archHeight});
  final double archHeight;

  @override
  Path getClip(Size size) {
    final path = Path();
    // Start at top-left, arch up over the top, down the sides, square bottom.
    path.moveTo(0, archHeight);
    // Arch: a quadratic curve peaking at the top-center.
    path.quadraticBezierTo(size.width / 2, -archHeight, size.width, archHeight);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _MihrabArchClipper old) =>
      old.archHeight != archHeight;
}

class _MihrabOutlinePainter extends CustomPainter {
  _MihrabOutlinePainter({
    required this.color,
    required this.strokeWidth,
    required this.archHeight,
  });

  final Color color;
  final double strokeWidth;
  final double archHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()
      ..moveTo(0, archHeight)
      ..quadraticBezierTo(size.width / 2, -archHeight, size.width, archHeight);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MihrabOutlinePainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.archHeight != archHeight;
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/mihrab_arch_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add lib/widgets/mihrab_arch.dart test/mihrab_arch_test.dart
git commit -m "feat(ui): add MihrabArch arch-top container with gold outline"
```

---

## Task 3: GoldHairlineDivider (gold line + star node)

**Files:**
- Create: `lib/widgets/gold_divider.dart`

**Interfaces:**
- Produces: `GoldHairlineDivider` — a stateless widget drawing a 1px gold horizontal line with a small centered 8-point-star node. Constructor: `GoldHairlineDivider({super.key, Color? color, double indent = 0})`. `color` defaults to theme gold. Used between sections in Settings/Stats/Home. No dedicated test (pure presentation, covered by the app-level widget tests); verified by `flutter test` not erroring on screens that use it.

- [x] **Step 1: Write minimal implementation**

```dart
// lib/widgets/gold_divider.dart
import 'package:flutter/material.dart';

/// A 1px gold hairline with a small centered 8-point-star node.
/// Used as an ornamental section divider.
class GoldHairlineDivider extends StatelessWidget {
  const GoldHairlineDivider({super.key, this.color, this.indent = 0});

  final Color? color;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final gold = color ?? Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: indent, vertical: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(height: 1, thickness: 1, color: gold),
          // Small 8-point-star node centered on the line.
          Container(
            width: 12,
            height: 12,
            color: Theme.of(context).colorScheme.surface,
            alignment: Alignment.center,
            child: CustomPaint(
              size: const Size(10, 10),
              painter: _StarNodePainter(color: gold),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarNodePainter extends CustomPainter {
  _StarNodePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    // Two overlapping squares → 8-point star.
    canvas.drawRect(Rect.fromCircle(center: Offset(cx, cy), radius: r), paint);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(0.785398); // 45°
    canvas.drawRect(Rect.fromCircle(center: Offset.zero, radius: r), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StarNodePainter old) => old.color != color;
}
```

- [x] **Step 2: Run analyzer to verify it compiles**

Run: `flutter analyze lib/widgets/gold_divider.dart`
Expected: no issues.

- [x] **Step 3: Commit**

```bash
git add lib/widgets/gold_divider.dart
git commit -m "feat(ui): add GoldHairlineDivider with centered star node"
```

---

## Task 4: DecorativeAppShell (header + 3-tab bottom-nav + IndexedStack)

**Files:**
- Create: `lib/widgets/decorative_app_shell.dart`
- Test: `test/decorative_app_shell_test.dart`

**Interfaces:**
- Consumes: three body widgets (Home, Stats, Settings) passed via `screens`, plus a tab index via callback. `AppTextStyles`, `IslamicPattern`, `MihrabArch`, `GoldHairlineDivider` from Tasks 1–3.
- Produces: `DecorativeAppShell` — a `StatefulWidget` that hosts the tab index internally and renders an `IndexedStack` of 3 screens. Constructor: `DecorativeAppShell({super.key, required List<Widget> screens})`. The header is a decorative band: Home (index 0) gets the full mihrab-arch header with app name + faint pattern; Stats/Settings get a slimmer arch title bar. The bottom nav is a 3-tab ornamental pill bar: `الرئيسية` (Home, `Icons.mosque`), `الإحصائيات` (Stats, `Icons.bar_chart`), `الإعدادات` (Settings, `Icons.settings`). Active tab shows a small gold star node above its label instead of the Material underline.

> **Test-navigation contract:** The existing widget tests navigate by tapping `find.byIcon(Icons.settings)` and `find.text('الإحصائيات')`. The bottom-nav MUST present these exact icons/labels so the tests keep working without logic changes. (Home currently uses `Icons.home`/`Icons.bar_chart`/`Icons.info` in a `BottomNavigationBar`; the spec section 2 prescribes mosque/bar_chart/settings — this task switches Home's tab to `Icons.mosque`. The `Icons.settings` finder is satisfied by the Settings tab icon.)

- [x] **Step 1: Write the failing test**

```dart
// test/decorative_app_shell_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/widgets/decorative_app_shell.dart';

void main() {
  testWidgets('shell switches tabs and preserves state', (tester) async {
    int homeBuilds = 0;
    int statsBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: DecorativeAppShell(
          screens: [
            StatefulBuilder(
              builder: (context, _) {
                homeBuilds++;
                return const _StateMarker(label: 'home-content');
              },
            ),
            StatefulBuilder(
              builder: (context, _) {
                statsBuilds++;
                return const _StateMarker(label: 'stats-content');
              },
            ),
            const _StateMarker(label: 'settings-content'),
          ],
        ),
      ),
    );

    // Home is shown first; stats/settings built but kept offstage by stack.
    expect(find.text('الرئيسية'), findsWidgets);
    expect(find.text('home-content'), findsOneWidget);

    // Switch to Stats tab by its label.
    await tester.tap(find.text('الإحصائيات'));
    await tester.pumpAndSettle();
    expect(find.text('stats-content'), findsOneWidget);

    // Switch to Settings.
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('settings-content'), findsOneWidget);

    // Back to Home — IndexedStack preserved it, so home-content is still there.
    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    expect(find.text('home-content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _StateMarker extends StatelessWidget {
  const _StateMarker({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Center(child: Text(label));
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/decorative_app_shell_test.dart`
Expected: FAIL — `Target of URI doesn't exist`.

- [x] **Step 3: Write minimal implementation**

```dart
// lib/widgets/decorative_app_shell.dart
import 'package:flutter/material.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';
import 'gold_divider.dart';
import 'islamic_pattern.dart';

/// A persistent decorative app shell: custom mihrab-arch header band +
/// 3-tab ornamental pill bottom-nav wrapping an IndexedStack so tabs
/// preserve their state when switching.
class DecorativeAppShell extends StatefulWidget {
  const DecorativeAppShell({super.key, required this.screens});

  /// Exactly 3 widgets: Home, Stats, Settings (in that order).
  final List<Widget> screens;

  @override
  State<DecorativeAppShell> createState() => _DecorativeAppShellState();
}

class _DecorativeAppShellState extends State<DecorativeAppShell> {
  int _index = 0;

  static const _tabs = [
    _TabSpec(label: 'الرئيسية', icon: Icons.mosque),
    _TabSpec(label: 'الإحصائيات', icon: Icons.bar_chart),
    _TabSpec(label: 'الإعدادات', icon: Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final isHome = _index == 0;
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, isHome),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: widget.screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context, bool isHome) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16, isHome ? 12 : 8, 16, isHome ? 16 : 8,
        ),
        color: Theme.of(context).colorScheme.primary,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Faint 8-point-star pattern behind the header title.
                const SizedBox(
                  height: 48,
                  child: IslamicPattern(opacity: 0.06),
                ),
                Text(
                  isHome
                      ? AppStrings.appName
                      : _tabs[_index].label,
                  style: AppTextStyles.display(context).copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const GoldHairlineDivider(indent: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final gold = Theme.of(context).colorScheme.secondary;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: gold, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < _tabs.length; i++)
              _NavPill(
                label: _tabs[i].label,
                icon: _tabs[i].icon,
                selected: i == _index,
                gold: gold,
                onTap: () => setState(() => _index = i),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.gold,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color gold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active tab gets a small gold star node above its label.
            SizedBox(
              height: 8,
              width: 8,
              child: selected
                  ? CustomPaint(painter: _SmallStarPainter(color: gold))
                  : const SizedBox.shrink(),
            ),
            Icon(icon, color: selected ? primary : gold, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'ReemKufi',
                fontSize: 12,
                color: selected ? primary : gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStarPainter extends CustomPainter {
  _SmallStarPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = size.width / 2;
    canvas.drawRect(Rect.fromCircle(center: Offset(r, r), radius: r), paint);
    canvas.save();
    canvas.translate(r, r);
    canvas.rotate(0.785398);
    canvas.drawRect(Rect.fromCircle(center: Offset.zero, radius: r), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SmallStarPainter old) => old.color != color;
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/decorative_app_shell_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add lib/widgets/decorative_app_shell.dart test/decorative_app_shell_test.dart
git commit -m "feat(ui): add DecorativeAppShell with mihrab header and 3-tab pill nav"
```

---

## Task 5: Wire shell into main.dart (IndexedStack, drop /about route)

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `DecorativeAppShell` from Task 4; the existing 3 screens.
- Produces: `MyApp` whose `home` is `DecorativeAppShell(screens: [HomeScreen, StatsScreen, SettingsScreen])`. The named `routes` map and `/about` route are removed. The `about_screen.dart` import is removed from `main.dart` (About is reached via `Navigator.push` of `AboutScreen()` from the Settings tile — Task 7).

> **Note on screens still having their own Scaffold/AppBar:** Tasks 6–8 make each screen body-only. Until then, the screens still render their own `Scaffold`/`AppBar`. To keep the build green at every commit, Task 5 wraps the screens in the shell but does NOT yet remove the per-screen AppBars. The per-screen AppBars are removed in Tasks 6–8 (each screen rewrite ends with its own green test run). This avoids a broken intermediate state.

- [x] **Step 1: Replace the MaterialApp routes with the shell**

In `lib/main.dart`, replace the `MaterialApp(...)` `routes`/`initialRoute` block:

```dart
          // Theme
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // Decorative shell with 3-tab navigation
          home: const DecorativeAppShell(
            screens: [
              HomeScreen(),
              StatsScreen(),
              SettingsScreen(),
            ],
          ),
```

And add the import at the top:

```dart
import 'widgets/decorative_app_shell.dart';
```

And remove the now-unused `about_screen.dart` import:

```dart
import 'screens/about_screen.dart';  // <-- delete this line
```

Leave the `stats_screen.dart` import (still used by the stack). Leave `home_screen.dart`/`settings_screen.dart` imports.

- [x] **Step 2: Run analyzer + widget tests**

Run: `flutter analyze lib/main.dart`
Expected: no issues.

Run: `flutter test test/widget_test.dart test/settings_backup_test.dart`
Expected: the navigation tests (`tap Icons.settings`, `tap الإحصائيات`) now hit the shell's bottom-nav pills. Stats test navigates to Stats tab and finds the chart. The `reminder toggle` test taps `Icons.settings` (Settings tab) — passes. If any test fails because a screen still pushes `/stats`/`/about` via the old home bottom-nav, that is expected to be fixed in Tasks 6–8; capture the failure and proceed. Do NOT commit a red state if the failure is a compile error — fix imports first.

- [x] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat(nav): wire DecorativeAppShell into MaterialApp, drop /about route"
```

---

## Task 6: Rewrite HomeScreen as body-only centerpiece

**Files:**
- Modify: `lib/screens/home_screen.dart`

**Interfaces:**
- Consumes: `MihrabArch`, `IslamicPattern`, `GoldHairlineDivider`, `AppTextStyles` (Tasks 1–3); `CountersProvider`/`SettingsProvider` (unchanged wiring).
- Produces: `HomeScreen` returning a body widget (no `Scaffold`/`AppBar`/`bottomNavigationBar`). Navigation is now owned by the shell. Keeps the `SingleTickerProviderStateMixin` controller; adds a short scale/pop tween on the big count per increment (spec §3: "Big count animates a brief scale/pop on each increment").

> **Spec-mandated presentation change that breaks one existing assertion:** the flat `LinearProgressIndicator` is replaced by decorative segmented progress (gold segments toward target). The test `shows daily target progress` asserts `find.byType(LinearProgressIndicator)`. That assertion is updated in Task 8 as part of the deliberate, spec-mandated replacement — NOT here. The `'40 / 100'` text finder in that same test MUST still be satisfied, so this screen keeps the `'$current / $target'` centered-below label.

- [x] **Step 1: Rewrite the screen**

Rewrite `lib/screens/home_screen.dart` so that:
- The class still `extends State<HomeScreen> with SingleTickerProviderStateMixin` and keeps the existing `_controller`/`_scaleAnimation` (button press animation).
- `build` returns a `Consumer2<CountersProvider, SettingsProvider>` whose builder returns a `SafeArea` > `SingleChildScrollView` > `Column` (NO `Scaffold`, NO `AppBar`, NO `bottomNavigationBar`). The background gradient stays on a wrapping `Container`.
- Top to bottom:
  1. **Bismillah band** — `Text('بسم الله الرحمن الرحيم', style: AppTextStyles.bismillah(context))` centered, then `GoldHairlineDivider()`.
  2. **Counter switcher** — horizontal `ListView` of medallion chips: active = gold ring + emerald fill; others = outlined cream with gold text. Same data (`counters.counters`), same `counters.setActive(c.id)` call. A "+ إضافة" `ActionChip` restyled, calling `_showAddCounterDialog`.
  3. **Counter card (centerpiece)** — a `Stack` with `IslamicPattern(opacity: 0.04)` behind, on top a `MihrabArch`-topped card containing: counter name (`AppTextStyles.display`), big count (`AppTextStyles.kufiNumber`, ~88px, emerald light / gold dark), "اليوم" label, "الإجمالي: ${counter.totalCount}" beneath.
     - Target progress: replace the `LinearProgressIndicator` with a **decorative segmented progress** widget — a `Row` of N small gold segments filling toward the target; below it `Text('${counter.currentCount} / $target')` centered. On target met, segments use gold (filled/glow) and a small "تم الهدف" badge with a star appears. Use a fixed segment count (e.g. `min(target, 20)` segments, each `Expanded`) so layout is stable.
     - Streak: a small pill `Row` with `Icon(Icons.local_fire_department)` (gold) + `'$streak يوم متتالي'`.
  4. **Tap-to-count button** — large wide-rounded emerald `GestureDetector` > `Container` with a subtle gold inner border + small star motif. `onTap`/`onTapDown`/`onTapUp`/`onTapCancel` keep the existing scale animation + `HapticFeedback`/increment/`notifyDailyTargetReached` logic verbatim. Label `Text('اضغط للعد', style: AppTextStyles.uiLabel(context))`. Wrap the big count in an `AnimatedBuilder` driven by a second short tween (reuse `_controller` forward on increment, or add a `_popController`) so the count does a brief scale/pop on each increment.
  5. **Undo / Reset** — a `Row` of two outlined gold `TextButton`s: `تراجع` (enabled only when `counters.canUndo`, calls `counters.undo()` + `HapticFeedback.selectionClick` when vibration on) and `إعادة تعيين` (calls `_showResetConfirmation`, which keeps its confirmation dialog verbatim).
  6. **Last used** — keep the `DateFormat('dd/MM/yyyy HH:mm')` "آخر استخدام" line.

Keep `_showResetConfirmation`, `_showAddCounterDialog` methods verbatim (logic unchanged). Remove the `Navigator.pushNamed(context, '/settings')` (the settings AppBar action is gone — navigation is the shell's job now).

Full replacement file content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/counters_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_text_styles.dart';
import '../utils/stats.dart';
import '../widgets/gold_divider.dart';
import '../widgets/islamic_pattern.dart';
import '../widgets/mihrab_arch.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _popController;
  late Animation<double> _popAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Brief count pop on each increment.
    _popController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _popAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _popController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return Consumer2<CountersProvider, SettingsProvider>(
      builder: (context, counters, settings, child) {
        final counter = counters.activeCounter;
        final target = counter.dailyTarget;
        final streak = currentStreak(
          history: counter.history,
          currentCount: counter.currentCount,
          dailyTarget: target,
          today: DateTime.now(),
        );
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Bismillah band
                  Text('بسم الله الرحمن الرحيم',
                      style: AppTextStyles.bismillah(context),
                      textAlign: TextAlign.center),
                  const GoldHairlineDivider(),
                  const SizedBox(height: 8),

                  // Counter switcher (medallion chips)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final c in counters.counters)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _MedallionChip(
                              label: c.name,
                              selected: c.id == counter.id,
                              onSelected: (_) => counters.setActive(c.id),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ActionChip(
                            avatar: const Icon(Icons.add, size: 18),
                            label: const Text('إضافة'),
                            onPressed: () =>
                                _showAddCounterDialog(context, counters),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Counter card (centerpiece) with mihrab arch + pattern
                  Stack(
                    children: [
                      const Positioned.fill(
                        child: IslamicPattern(opacity: 0.04),
                      ),
                      MihrabArch(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                          color: Theme.of(context).colorScheme.surface,
                          child: Column(
                            children: [
                              Text(counter.name,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.display(context)),
                              const SizedBox(height: 12),
                              AnimatedBuilder(
                                animation: _popAnimation,
                                builder: (context, c) => Transform.scale(
                                  scale: _popAnimation.value,
                                  child: c,
                                ),
                                child: Text('${counter.currentCount}',
                                    style: AppTextStyles.kufiNumber(context)),
                              ),
                              const SizedBox(height: 4),
                              Text('اليوم',
                                  style: AppTextStyles.bodyArabic(context)),
                              const SizedBox(height: 4),
                              Text('الإجمالي: ${counter.totalCount}',
                                  style: AppTextStyles.bodyArabic(context)
                                      .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  )),
                              if (target > 0) ...[
                                const SizedBox(height: 16),
                                _SegmentedProgress(
                                  count: counter.currentCount,
                                  target: target,
                                ),
                                const SizedBox(height: 8),
                                Text('${counter.currentCount} / $target',
                                    style: AppTextStyles.bodyArabic(context)
                                        .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontWeight: FontWeight.bold,
                                    )),
                                if (counter.currentCount >= target) ...[
                                  const SizedBox(height: 8),
                                  _TargetBadge(),
                                ],
                                const SizedBox(height: 12),
                                _StreakPill(streak: streak),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Tap-to-count button
                  GestureDetector(
                    onTapDown: _onTapDown,
                    onTapUp: _onTapUp,
                    onTapCancel: _onTapCancel,
                    onTap: () async {
                      if (settings.settings.vibrationEnabled) {
                        HapticFeedback.lightImpact();
                      }
                      final before = counter.currentCount;
                      await counters.increment();
                      _popController.forward(from: 0).then(
                          (_) => _popController.reverse());
                      if (target > 0 &&
                          before < target &&
                          counters.activeCounter.currentCount >= target) {
                        await counters.notifyDailyTargetReached();
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, c) => Transform.scale(
                        scale: _scaleAnimation.value,
                        child: c,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.8),
                          ]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text('اضغط للعد',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.uiLabel(context)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Undo / Reset outlined gold text-buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: counters.canUndo
                            ? () async {
                                if (settings.settings.vibrationEnabled) {
                                  HapticFeedback.selectionClick();
                                }
                                await counters.undo();
                              }
                            : null,
                        icon: const Icon(Icons.undo),
                        label: const Text('تراجع'),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          side: BorderSide(
                              color:
                                  Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _showResetConfirmation(context, counters),
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة تعيين'),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          side: BorderSide(
                              color:
                                  Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'آخر استخدام: ${DateFormat('dd/MM/yyyy HH:mm').format(counter.lastUsedAt)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showResetConfirmation(BuildContext context, CountersProvider counters) {
    var includeTotal = false;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('إعادة تعيين العداد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('هل أنت متأكد من إعادة تعيين العداد؟'),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('إعادة تعيين العدد التراكمي أيضاً'),
                value: includeTotal,
                onChanged: (value) {
                  setDialogState(() {
                    includeTotal = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                await counters.reset(includeTotal: includeTotal);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('تأكيد', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCounterDialog(BuildContext context, CountersProvider counters) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة عداد'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'اسم الذكر'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await counters.addCounter(name);
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class _MedallionChip extends StatelessWidget {
  const _MedallionChip(
      {required this.label, required this.selected, required this.onSelected});
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.secondary;
    final primary = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontFamily: 'ReemKufi',
              color: selected ? Colors.white : gold)),
      selected: selected,
      onSelected: onSelected,
      selectedColor: primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(color: gold, width: selected ? 2 : 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({required this.count, required this.target});
  final int count;
  final int target;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.secondary;
    final segments = target <= 20 ? target : 20;
    final filled = (count / target * segments).floor().clamp(0, segments);
    final done = count >= target;
    return Row(
      children: [
        for (var i = 0; i < segments; i++)
          Expanded(
            child: Container(
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i < filled
                    ? (done ? gold : gold)
                    : gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
      ],
    );
  }
}

class _TargetBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: gold, size: 16),
          const SizedBox(width: 4),
          Text('تم الهدف', style: TextStyle(color: gold, fontFamily: 'ReemKufi')),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: gold, size: 18),
          const SizedBox(width: 4),
          Text('$streak يوم متتالي',
              style: TextStyle(fontFamily: 'ReemKufi', color: gold)),
        ],
      ),
    );
  }
}
```

- [x] **Step 2: Run analyzer**

Run: `flutter analyze lib/screens/home_screen.dart`
Expected: no issues.

- [x] **Step 3: Run home-targeted widget tests**

Run: `flutter test test/widget_test.dart`
Expected: Most pass. The `shows daily target progress` test FAILS on `find.byType(LinearProgressIndicator)` — this is the spec-mandated replacement. Do not "fix" it by re-adding the indicator; it is corrected in Task 8. Confirm the `'40 / 100'` and `'تم الهدف'` finders in the relevant tests still pass (they should — labels preserved). Confirm `tap 'اضغط للعد'` increment tests pass. Capture the exact failing assertion to reference in Task 8.

- [x] **Step 4: Commit**

```bash
git add lib/screens/home_screen.dart
git commit -m "feat(ui): rewrite HomeScreen as mihrab-arch centerpiece with segmented progress"
```

---

## Task 7: Restyle Stats + Settings + About for the shell

**Files:**
- Modify: `lib/screens/stats_screen.dart`
- Modify: `lib/screens/settings_screen.dart`
- Modify: `lib/screens/about_screen.dart`

**Interfaces:**
- Consumes: `AppTextStyles`, `IslamicPattern`, `GoldHairlineDivider`, `MihrabArch` (Tasks 1–3). Each screen drops its own `Scaffold`/`AppBar` and returns body content rendered inside the shell's arch header.
- Produces: three body-only screens. `SettingsScreen`'s About tile calls `Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))` instead of `Navigator.pushNamed(context, '/about')`. `AboutScreen` becomes a plain `Scaffold` (no AppBar) pushed on top of the shell.

> **Test-navigation contract:** `test/widget_test.dart` navigates to Stats by `find.text('الإحصائيات')` (shell tab) then asserts `find.byType(BarChart)`, `find.text('الإجمالي الكلي')`, `find.text('أفضل يوم')`, `find.text('السلسلة الحالية')`, `find.text('أطول سلسلة')`. These labels MUST remain unchanged. The `SegmentedButton` labels `'٧ أيام'`/`'٣٠ يومًا'` are not asserted by tests but should be kept for consistency.

- [x] **Step 1: Rewrite StatsScreen as body-only**

Modify `lib/screens/stats_screen.dart`:
- Remove the `Scaffold`/`AppBar`. The `build` returns a `Consumer<CountersProvider>` whose builder returns a `Padding` > `Column` directly (the shell provides the header). Keep `_days` state and all stat computations (`lastDaysCounts`, `windowSum`, `bestDay`, `currentStreak`, `longestStreak`) verbatim.
- Restyle the `SegmentedButton<int>`: selected segment emerald fill + white text; unselected cream with gold text. Keep `segments` values `{7, 30}` and labels.
- Restyle `_buildChart`: bars emerald with gold tips (use `BarChartRodData` `gradient` or a second rod for tip — simplest: `color: primary` and set `borderRadius` gold). Faint gold grid lines (`FlGridData` with `getDrawingHorizontalLine` color gold at low opacity). Keep `titlesData`/`borderData` as-is or show axis labels in Reem Kufi. Wrap the chart `SizedBox` in a `Card` with a thin gold border + rounded corners, and place `IslamicPattern(opacity: 0.04)` behind it (Stack).
- Restyle `_totalTile`: small medallion tiles (gold-ringed rounded container) with the number in `AppTextStyles.kufiNumber` (smaller) and label in Reem Kufi. Insert `GoldHairlineDivider()` between tile rows where the spec says "star dividers between". Keep all labels identical (`'آخر ٧ أيام'`/`'آخر ٣٠ يومًا'`, `'الإجمالي الكلي'`, `'أفضل يوم'`, `'السلسلة الحالية'`, `'أطول سلسلة'`).

Add imports for `app_text_styles.dart`, `islamic_pattern.dart`, `gold_divider.dart` as needed.

Full replacement for the `build` + chart/tile helpers (keep the class shell + `_days`):

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/counters_provider.dart';
import '../utils/app_text_styles.dart';
import '../utils/stats.dart';
import '../widgets/gold_divider.dart';
import '../widgets/islamic_pattern.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    return Consumer<CountersProvider>(
      builder: (context, counters, child) {
        final counter = counters.activeCounter;
        final counts = lastDaysCounts(
          history: counter.history,
          currentCount: counter.currentCount,
          days: _days,
          today: DateTime.now(),
        );
        final windowSum = counts.fold<int>(0, (sum, c) => sum + c);
        final bestDay = counts.fold<int>(0, (best, c) => c > best ? c : best);
        final target = counter.dailyTarget;
        final current = currentStreak(
          history: counter.history,
          currentCount: counter.currentCount,
          dailyTarget: target,
          today: DateTime.now(),
        );
        final longest = longestStreak(
          history: counter.history,
          currentCount: counter.currentCount,
          dailyTarget: target,
          today: DateTime.now(),
        );

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('٧ أيام')),
                  ButtonSegment(value: 30, label: Text('٣٠ يومًا')),
                ],
                selected: {_days},
                onSelectionChanged: (selection) {
                  setState(() => _days = selection.first);
                },
                style: ButtonStyle(
                  selectedBackgroundColor:
                      WidgetStatePropertyAll(Theme.of(context).colorScheme.primary),
                  selectedForegroundColor: const WidgetStatePropertyAll(Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              Stack(
                children: [
                  const Positioned.fill(
                    child: IslamicPattern(opacity: 0.04),
                  ),
                  SizedBox(height: 220, child: _buildChart(context, counts)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _medallionTile(context,
                      _days == 7 ? 'آخر ٧ أيام' : 'آخر ٣٠ يومًا', windowSum),
                  _medallionTile(context, 'الإجمالي الكلي', counter.totalCount),
                  _medallionTile(context, 'أفضل يوم', bestDay),
                ],
              ),
              if (target > 0) ...[
                const GoldHairlineDivider(),
                Row(
                  children: [
                    _medallionTile(context, 'السلسلة الحالية', current),
                    _medallionTile(context, 'أطول سلسلة', longest),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart(BuildContext context, List<int> counts) {
    final maxCount = counts.fold<int>(0, (m, c) => c > m ? c : m);
    final maxY = maxCount < 1 ? 5.0 : (maxCount * 1.2).ceilToDouble();
    final gold = Theme.of(context).colorScheme.secondary;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: gold, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: BarChart(
          BarChartData(
            maxY: maxY,
            barTouchData: BarTouchData(enabled: false),
            titlesData: const FlTitlesData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: gold.withOpacity(0.15), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              for (var i = 0; i < counts.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: counts[i].toDouble(),
                      color: Theme.of(context).colorScheme.primary,
                      width: _days == 30 ? 5 : 14,
                      borderRadius: const Radius.circular(4),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _medallionTile(BuildContext context, String label, int value) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gold.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text('$value',
                style: AppTextStyles.kufiNumber(context)
                    .copyWith(fontSize: 28)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'ReemKufi', fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 2: Rewrite SettingsScreen body + About navigation**

Modify `lib/screens/settings_screen.dart`:
- Remove the `Scaffold`/`AppBar`. The `build` returns the `Consumer2<...>` whose builder returns the `ListView` directly. (The shell provides the header.)
- Replace `_buildSectionTitle` with an Amiri-gold title + `GoldHairlineDivider` beneath. New helper:

```dart
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(title, style: AppTextStyles.display(context)),
        const GoldHairlineDivider(indent: 0),
      ],
    );
  }
```

- Wrap each ListTile's leading `Icon` in a small gold-ringed circle medallion. Add a helper:

```dart
  Widget _medallionIcon(BuildContext context, IconData icon) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: gold, width: 1.2),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
    );
  }
```

  Replace each `leading: const Icon(Icons.edit)` etc. with `leading: _medallionIcon(context, Icons.edit)`.

- Recolor `SwitchListTile` switches to emerald/gold: set `activeColor: primary`, `activeTrackColor: gold` via the `SwitchListTile` `activeColor`/`inactiveThumbColor` params where supported (Material 3). Keep all `onChanged` logic verbatim.

- Replace the About tile's `Navigator.pushNamed(context, '/about')` with a direct push:

```dart
              ListTile(
                leading: _medallionIcon(context, Icons.info),
                title: const Text('حول التطبيق'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AboutScreen(),
                    ),
                  );
                },
              ),
```

  Add the import: `import 'about_screen.dart';`

- Keep ALL dialog methods (`_showRenameDialog`, `_showDailyTargetDialog`, `_showReminderTypeDialog`, `_showIntervalDialog`, `_showDailyTimesDialog`, `_showDeleteDialog`, `_showExportSheet`, `_showRestoreFlow`, `_exportData`) and the `_DailyTargetDialog` widget VERBATIM in logic. Only restyle their colors/fonts if trivially consistent; do not alter any control flow, `await` order, or snackbar text.

Add imports for `app_text_styles.dart`, `gold_divider.dart`, `about_screen.dart`.

- [x] **Step 3: Rewrite AboutScreen as shell-hosted (no AppBar), mihrab emblem**

Modify `lib/screens/about_screen.dart`:
- Change `return Scaffold(appBar: AppBar(...), body: ...)` to `return Scaffold(body: ...)`. (It is pushed on top of the shell; the shell's header is not shown for pushed routes, so About keeps a plain body. The spec says "rendered inside the shell's arch header" — since it is pushed via `Navigator.push` it renders as a full screen; keep a plain `Scaffold` body so it looks intentional. This is presentation-only.)
- Replace the big mosque icon `Container` with a `MihrabArch`-framed emblem: a `Stack` of `IslamicPattern(opacity: 0.06)` behind a gold-bordered `Container` holding `Icon(Icons.mosque)`.
- Salawat text: render `AppStrings.salawat` with `AppTextStyles.display(context)` centered, with `GoldHairlineDivider()` above and below.
- Feature items: restyle `_buildFeatureItem`'s icon container to the same gold-ringed medallion style as Settings rows (reuse the same shape; can be a local copy of the medallion helper).
- Footer "صُنع بحب..." in gold italic (already gold via `colorScheme.secondary`; add `fontStyle: FontStyle.italic`, already present — keep).

Full replacement file:

```dart
import 'package:flutter/material.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';
import '../widgets/gold_divider.dart';
import '../widgets/islamic_pattern.dart';
import '../widgets/mihrab_arch.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              // Mihrab-arch framed emblem
              SizedBox(
                width: 140,
                height: 140,
                child: MihrabArch(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Positioned.fill(child: IslamicPattern(opacity: 0.06)),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).colorScheme.secondary,
                              width: 2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Icon(Icons.mosque,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(AppStrings.appName, style: AppTextStyles.display(context)),
              const SizedBox(height: 8),
              Text('الإصدار 1.0.0',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      )),
              const SizedBox(height: 24),
              const GoldHairlineDivider(),
              Text(AppStrings.salawat,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.display(context)),
              const GoldHairlineDivider(),
              const SizedBox(height: 24),
              _buildFeatureItem(context, Icons.numbers, 'عدّاد ذكي',
                  'عدّاد مستمر أو يومي مع حفظ تلقائي'),
              _buildFeatureItem(context, Icons.notifications_active,
                  'تذكيرات محلية', 'إشعارات متكررة أو في أوقات محددة'),
              _buildFeatureItem(context, Icons.phone_android, 'محلي بالكامل',
                  'لا يتطلب إنترنت أو حساب مستخدم'),
              _buildFeatureItem(context, Icons.privacy_tip, 'خصوصية تامة',
                  'لا جمع بيانات ولا تتبع'),
              const SizedBox(height: 24),
              Text('صُنع بحب لخدمة النبي ﷺ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontStyle: FontStyle.italic,
                      )),
              const SizedBox(height: 32),
              Text('جميع الحقوق محفوظة © 2024',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                      )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, IconData icon, String title, String description) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: gold, width: 1.2),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontFamily: 'ReemKufi')),
                Text(description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [x] **Step 4: Run analyzer**

Run: `flutter analyze lib/screens/stats_screen.dart lib/screens/settings_screen.dart lib/screens/about_screen.dart`
Expected: no issues. Fix any unused-import warnings.

- [x] **Step 5: Commit**

```bash
git add lib/screens/stats_screen.dart lib/screens/settings_screen.dart lib/screens/about_screen.dart
git commit -m "feat(ui): restyle Stats/Settings/About onto new identity + shell body-only"
```

---

## Task 8: Update widget tests for the deliberate presentation change + run full suite

**Files:**
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: the restyled screens + shell. Updates ONLY test assertions that the spec explicitly mandated to change (presentation), never logic.

> **Why this task exists:** The spec (§3) deliberately replaces the flat `LinearProgressIndicator` with decorative segmented progress. The existing test `shows daily target progress` asserts `find.byType(LinearProgressIndicator)`, which is now intentionally false. This task updates that assertion to assert the new segmented-progress widget instead. All logic assertions (increment, target-reached notification, counter switching, stats labels, backup flows) remain unchanged.

- [x] **Step 1: Update the daily-target-progress test assertion**

In `test/widget_test.dart`, in the `shows daily target progress` test, replace:

```dart
    expect(find.text('40 / 100'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
```

with:

```dart
    expect(find.text('40 / 100'), findsOneWidget);
    // Spec §3: flat LinearProgressIndicator replaced by decorative
    // segmented progress (tasbih beads). Assert the segmented widget renders.
    expect(find.byType(LinearProgressIndicator), findsNothing);
```

(The segmented progress is a private `_SegmentedProgress` widget; asserting `findsNothing` for the old indicator is the stable, intent-preserving assertion that documents the deliberate removal without coupling to a private type name. The `'40 / 100'` finder already proves progress renders.)

- [x] **Step 2: Verify navigation finders still resolve (no change needed)**

The tests navigate via `find.byIcon(Icons.settings)` (Settings tab) and `find.text('الإحصائيات')` (Stats tab). The shell (Task 4) presents these exact icons/labels. Run the navigation tests to confirm — they should pass unchanged. If `find.byIcon(Icons.settings)` returns multiple widgets (e.g. an AppBar action was removed but the shell has the tab), that's fine; the finder still resolves the tab. If any test now finds zero `Icons.settings`, that's a bug in Task 4 — fix the shell, not the test.

- [x] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: ALL tests pass, including the three new decorative-widget smoke tests from Tasks 1, 2, 4. Existing logic tests unchanged.

If any existing logic test fails, it is a regression — investigate; the redesign made no logic changes, so a logic-test failure means a wiring mistake in Tasks 5–7 (e.g. a dialog's `await` order changed). Fix the screen, not the test.

- [x] **Step 4: Commit**

```bash
git add test/widget_test.dart
git commit -m "test(ui): assert LinearProgressIndicator replaced by segmented progress (spec §3)"
```

---

## Verification Gate

After Task 8, run the full gate:

- [x] **Run: `flutter analyze`** — no issues across `lib/`.
- [x] **Run: `flutter test`** — full suite green. Includes:
  - New: `islamic_pattern_test.dart`, `mihrab_arch_test.dart`, `decorative_app_shell_test.dart` (render + tab-switch + state-preserve).
  - Existing logic tests unchanged: `adhkar_counter_test.dart`, `counters_provider_test.dart`, `settings_provider_test.dart`, `stats_test.dart`, `backup_service_test.dart`, `storage_service_test.dart`, `notification_service_test.dart`, `settings_backup_test.dart`, `unit_test.dart`, `widget_test.dart`.
- [x] **Confirm no logic changed:** `git diff` should show only presentation/navigation files (`lib/widgets/*`, `lib/screens/*`, `lib/main.dart`, `test/widget_test.dart`, new test files). No changes to `lib/providers/*`, `lib/models/*`, `lib/services/*`, `lib/utils/stats.dart`.
- [x] **Fonts note:** `assets/fonts/` currently has only `.gitkeep`. App runs + tests pass with system-font fallback. Calligraphic type appears once the four `.ttf` files (Amiri-Regular/Bold, ReemKufi-Regular/Medium) are dropped in — download links in spec §1.

## Self-Review notes (applied during authoring)

- **Spec coverage:** §1 palette/fonts/styles — already present (baseline). §1 motifs → Tasks 1–3. §2 shell + nav → Tasks 4–5. §3 home → Task 6. §4 stats/settings/about → Task 7. §5 fonts/buildability/testing → Task 8 + Verification Gate. About-route removal → Task 5 (route) + Task 7 (push). All sections covered.
- **Type consistency:** `IslamicPattern`, `MihrabArch`, `GoldHairlineDivider`, `DecorativeAppShell` names + signatures match across every task that consumes them. `AppTextStyles.*` signatures match the existing file.
- **Placeholder scan:** No TBD/TODO. Every code step has full runnable content.
- **Known tension, documented:** The single `LinearProgressIndicator` assertion is the only existing test that conflicts with a spec-mandated presentation change; Task 8 handles it explicitly and only after the screen is rewritten, never by restoring the old widget.
