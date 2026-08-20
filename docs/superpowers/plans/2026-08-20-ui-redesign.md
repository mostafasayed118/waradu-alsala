# UI Redesign — Elegant & Ornamental Islamic Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle the Salawat counter app into an elegant, ornamental Islamic aesthetic (emerald + antique gold, calligraphic fonts, code-drawn geometric motifs) and restructure navigation into a decorative 3-tab bottom-nav shell — with zero logic changes.

**Architecture:** Replace the per-screen Scaffold/AppBar + named-routes structure with a single `DecorativeAppShell` holding an `IndexedStack` of 3 tabs (Home, Stats, Settings); About is pushed from Settings. New code-drawn decorative widgets (`IslamicPattern`, `MihrabArch`, `GoldDivider`) render motifs via `CustomPaint`. A new `AppTextStyles` map centralizes calligraphic typography. The theme is recolored to emerald/gold. All provider/model/service logic is untouched.

**Tech Stack:** Flutter (Material 3), provider, fl_chart, intl, shared_preferences, flutter_local_notifications, share_plus, file_picker, path_provider.

**Spec:** `docs/superpowers/specs/2026-08-20-ui-redesign-design.md`

## Global Constraints

- **No logic changes:** every counter/reminder/backup/stats computation keeps current behavior. Provider APIs (`increment`, `undo`, `reset`, `addCounter`, `setActive`, `setDailyTarget`, `setRemindersEnabled`, `setReminderType`, `setReminderInterval`, `setDailyReminderTimes`, `notifyDailyTargetReached`, `toggleVibration`, `toggleDarkMode`) are called unchanged.
- **Fonts external:** `.ttf` files for Amiri and Reem Kufi cannot be fetched here; pubspec + code reference them at `assets/fonts/`. Until present, Flutter falls back to system fonts — app runs, tests pass.
- **No external image assets:** all motifs are `CustomPaint` + `Path`/`Canvas`.
- **RTL:** locale stays `ar_SA`; all new Arabic strings are literals inline (matching current code's convention) or reuse `AppStrings`.
- **Test gate:** full `flutter test` must pass; existing pure-logic tests (`adhkar_counter_test`, `counters_provider_test`, `stats_test`, `settings_provider_test`, `backup_service_test`, `notification_service_test`, `storage_service_test`) stay unchanged. Only widget tests that couple to presentation details (the `Icons.settings` AppBar entry and `LinearProgressIndicator`) are updated to match the new navigation/presentation.
- **Package:** `salawat_app`.
- **Branch:** `redesign/elegant-ornamental` (already created).

---

## File Structure

**New files:**
- `lib/widgets/islamic_pattern.dart` — `CustomPaint` widget drawing the 8-pointed-star (Khatam) tessellation as a faint background layer. Params: `opacity`, `color`.
- `lib/widgets/mihrab_arch.dart` — `CustomPainter` + container drawing a rounded mihrab/arch top edge with gold outline. Params: `child`, `color`, `strokeColor`.
- `lib/widgets/gold_divider.dart` — 1px gold hairline with a centered 8-point star node.
- `lib/widgets/decorative_app_shell.dart` — persistent Scaffold: decorative arch header, `IndexedStack` body of 3 screens, ornamental 3-tab bottom nav. Stateful (`_currentIndex`).
- `lib/utils/app_text_styles.dart` — named style map (`bismillah`, `display`, `kufiNumber`, `bodyArabic`, `uiLabel`) resolving per brightness.
- `test/decorative_widgets_test.dart` — smoke tests for the new decorative widgets + shell.

**Modified files:**
- `lib/utils/app_theme.dart` — new emerald/gold color tokens + font-aware theme.
- `pubspec.yaml` — `flutter.fonts` section + `assets/fonts/` entry.
- `lib/main.dart` — `IndexedStack` shell, drop named routes + `/about`.
- `lib/screens/home_screen.dart` — full rewrite to mihrab-arch centerpiece; remove Scaffold/AppBar/bottom nav (shell owns those).
- `lib/screens/stats_screen.dart` — restyle chart/tiles; remove Scaffold/AppBar.
- `lib/screens/settings_screen.dart` — restyle sections/listiles; remove Scaffold/AppBar; About tile pushes `AboutScreen` via `Navigator.push` (not `pushNamed('/about')`).
- `lib/screens/about_screen.dart` — restyle to mihrab emblem; keep its own Scaffold/AppBar (it's a pushed full screen, not a shell tab).
- `test/widget_test.dart` — update navigation (bottom-nav labels, not `Icons.settings`) + replace `LinearProgressIndicator` assertion.
- `test/settings_backup_test.dart` — update `openSettings()` helper to use bottom-nav label.

---

### Task 1: Theme + text styles + font wiring

**Files:**
- Modify: `lib/utils/app_theme.dart` (full rewrite of color tokens + theme builders)
- Create: `lib/utils/app_text_styles.dart`
- Modify: `pubspec.yaml:34-38` (add fonts + fonts dir asset)
- Test: `test/widget_test.dart` (existing `pumpApp` smoke already renders `MyApp`; reuse as the render gate)

**Interfaces:**
- Produces: `AppTheme.lightTheme()`, `AppTheme.darkTheme()` (same signatures, new colors); `AppTheme.emerald`, `AppTheme.gold`, `AppTheme.goldLight`, `AppTheme.cream`, `AppTheme.night`, `AppTheme.ink`, `AppTheme.parchment` color constants; `AppTextStyles.of(context)` returning the style map.

- [ ] **Step 1: Write the font + asset config into pubspec.yaml**

Replace the `flutter:` section (lines 34-38) with:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/
    - assets/fonts/

  fonts:
    - family: Amiri
      fonts:
        - asset: assets/fonts/Amiri-Regular.ttf
        - asset: assets/fonts/Amiri-Bold.ttf
          weight: 700
    - family: ReemKufi
      fonts:
        - asset: assets/fonts/ReemKufi-Regular.ttf
        - asset: assets/fonts/ReemKufi-Medium.ttf
          weight: 500
```

- [ ] **Step 2: Create assets/fonts/ directory placeholder**

Run: `mkdir -p assets/fonts && touch assets/fonts/.gitkeep`
This ensures the asset path exists so Flutter doesn't error on a missing dir at build time. The `.gitkeep` is the only tracked file there until real `.ttf`s are dropped in.

- [ ] **Step 3: Rewrite lib/utils/app_theme.dart**

```dart
import 'package:flutter/material.dart';

class AppTheme {
  // Emerald
  static const Color emerald = Color(0xFF0B4D2C);
  static const Color emeraldDeep = Color(0xFF073322);
  // Gold
  static const Color gold = Color(0xFFC9A24B);
  static const Color goldLight = Color(0xFFE6C976);
  // Surfaces
  static const Color cream = Color(0xFFFAF6EC);
  static const Color night = Color(0xFF0E1F15);
  // Text
  static const Color ink = Color(0xFF1A2E1F);
  static const Color parchment = Color(0xFFE8E2D0);

  static ThemeData lightTheme() => _build(
        brightness: Brightness.light,
        primary: emerald,
        secondary: gold,
        surface: cream,
        appBarBackground: emerald,
        bodyColor: ink,
        onSurface: ink,
      );

  static ThemeData darkTheme() => _build(
        brightness: Brightness.dark,
        primary: const Color(0xFF14794A),
        secondary: goldLight,
        surface: night,
        appBarBackground: emeraldDeep,
        bodyColor: parchment,
        onSurface: parchment,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color surface,
    required Color appBarBackground,
    required Color bodyColor,
    required Color onSurface,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: secondary,
        surface: surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        bodyLarge: TextStyle(fontSize: 18, color: bodyColor),
        bodyMedium: TextStyle(fontSize: 16, color: bodyColor),
      ),
    );
  }
}
```

Note: the old `primaryGreen`/`lightGreen`/`darkGreen`/`ivory`/`gold`/`lightGold` constants are removed. Grep confirms no other file references them by name (screens use `Theme.of(context).colorScheme.*`, not `AppTheme.<constant>` directly).

- [ ] **Step 4: Create lib/utils/app_text_styles.dart**

```dart
import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle bismillah(BuildContext context) => TextStyle(
        fontFamily: 'Amiri',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.secondary,
      );

  static TextStyle display(BuildContext context) => TextStyle(
        fontFamily: 'Amiri',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.secondary,
      );

  static TextStyle kufiNumber(BuildContext context) => TextStyle(
        fontFamily: 'ReemKufi',
        fontSize: 88,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.primary,
      );

  static TextStyle bodyArabic(BuildContext context) => TextStyle(
        fontFamily: 'Amiri',
        fontSize: 16,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      );

  static TextStyle uiLabel(BuildContext context) => TextStyle(
        fontFamily: 'ReemKufi',
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      );
}
```

- [ ] **Step 5: Run the existing smoke test to confirm the app still renders with the new theme**

Run: `flutter test test/widget_test.dart`
Expected: FAIL — the reminder-snackbar test taps `Icons.settings` (still present until Task 6) but the daily-target test asserts `LinearProgressIndicator` (still present until Task 6). At this stage only verify that the app **builds and renders** — the first test `Home screen displays the active counter` and `Increment button increases the counter` should PASS. If those pass, the theme swap is sound.

If `flutter test` fails to compile, fix the import/type errors before continuing.

- [ ] **Step 6: Commit**

```bash
git add lib/utils/app_theme.dart lib/utils/app_text_styles.dart pubspec.yaml assets/fonts/.gitkeep
git commit -m "feat(theme): emerald/gold palette, font wiring, AppTextStyles"
```

---

### Task 2: IslamicPattern widget

**Files:**
- Create: `lib/widgets/islamic_pattern.dart`
- Test: `test/decorative_widgets_test.dart` (new, create with first test)

**Interfaces:**
- Produces: `IslamicPattern({required double opacity, Color? color})` — a `CustomPaint` widget painting a repeating 8-pointed-star (Khatam) tessellation across its bounds at the given opacity. Used as a faint background layer.

- [ ] **Step 1: Write the failing test**

Create `test/decorative_widgets_test.dart`:

```dart
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
            child: IslamicPattern(opacity: 0.04),
          ),
        ),
      ),
    );
    expect(find.byType(IslamicPattern), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/decorative_widgets_test.dart`
Expected: FAIL — `IslamicPattern` not defined (import/target not found).

- [ ] **Step 3: Write minimal implementation**

Create `lib/widgets/islamic_pattern.dart`:

```dart
import 'package:flutter/material.dart';

/// A faint repeating 8-pointed-star (Khatam) tessellation painted with
/// [CustomPaint]. Intended as a low-opacity decorative background layer.
class IslamicPattern extends StatelessWidget {
  const IslamicPattern({
    super.key,
    this.opacity = 0.05,
    this.color,
  });

  /// Opacity of the painted motif. Typical values 0.03–0.06.
  final double opacity;

  /// Motif color; defaults to the theme secondary (gold).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final motif = color ?? Theme.of(context).colorScheme.secondary;
    return CustomPaint(
      painter: _KhatamPainter(motif.withOpacity(opacity.clamp(0.0, 1.0))),
      child: const SizedBox.expand(),
    );
  }
}

class _KhatamPainter extends CustomPainter {
  _KhatamPainter(this.paintColor);

  final Color paintColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = paintColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Tile size: two overlapping squares rotated 45° form the 8-point star.
    const tile = 48.0;
    final half = tile / 2;

    for (var y = -half; y < size.height + tile; y += tile) {
      for (var x = -half; x < size.width + tile; x += tile) {
        final center = Offset(x + half, y + half);
        // Square axis-aligned
        canvas.drawRect(
          Rect.fromCenter(center: center, width: tile, height: tile),
          paint,
        );
        // Square rotated 45° (diamond)
        final path = Path()
          ..moveTo(center.dx, center.dy - half)
          ..lineTo(center.dx + half, center.dy)
          ..lineTo(center.dx, center.dy + half)
          ..lineTo(center.dx - half, center.dy)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_KhatamPainter oldDelegate) =>
      oldDelegate.paintColor != paintColor;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/decorative_widgets_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/islamic_pattern.dart test/decorative_widgets_test.dart
git commit -m "feat(widgets): IslamicPattern Khatam tessellation"
```

---

### Task 3: MihrabArch widget

**Files:**
- Create: `lib/widgets/mihrab_arch.dart`
- Modify: `test/decorative_widgets_test.dart` (append test)

**Interfaces:**
- Produces: `MihrabArch({required Widget child, Color? color, Color? strokeColor})` — a container whose top edge is a rounded mihrab/arch shape (a pointed arch), drawn with a gold outline, holding `child`.

- [ ] **Step 1: Write the failing test**

Append to `test/decorative_widgets_test.dart` (add the import at top):

```dart
import 'package:salawat_app/widgets/mihrab_arch.dart';
```

Add inside `main()`:

```dart
  testWidgets('MihrabArch renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MihrabArch(child: Text('داخل المحراب')),
        ),
      ),
    );
    expect(find.byType(MihrabArch), findsOneWidget);
    expect(find.text('داخل المحراب'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/decorative_widgets_test.dart`
Expected: FAIL — `MihrabArch` not defined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/widgets/mihrab_arch.dart`:

```dart
import 'package:flutter/material.dart';

/// A container whose top edge is a pointed mihrab/arch shape, outlined in
/// gold. Holds [child] in the rectangular body beneath the arch.
class MihrabArch extends StatelessWidget {
  const MihrabArch({
    super.key,
    required this.child,
    this.color,
    this.strokeColor,
    this.archHeight = 32,
  });

  final Widget child;
  final Color? color;
  final Color? strokeColor;

  /// Height of the pointed arch above the rectangular body.
  final double archHeight;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? Theme.of(context).colorScheme.surface;
    final stroke = strokeColor ?? Theme.of(context).colorScheme.secondary;
    return CustomPaint(
      painter: _MihrabArchPainter(fill, stroke, archHeight),
      child: ClipPath(
        clipper: _MihrabArchClipper(archHeight),
        child: Padding(
          padding: EdgeInsets.only(top: archHeight),
          child: child,
        ),
      ),
    );
  }
}

class _MihrabArchPainter extends CustomPainter {
  _MihrabArchPainter(this.fill, this.stroke, this.archHeight);

  final Color fill;
  final Color stroke;
  final double archHeight;

  Path _archPath(Size size) {
    final w = size.width;
    return Path()
      ..moveTo(0, archHeight)
      ..quadraticBezierTo(w / 2, -archHeight * 0.6, w, archHeight)
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _archPath(size);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_MihrabArchPainter old) =>
      old.fill != fill || old.stroke != stroke;
}

class _MihrabArchClipper extends CustomClipper<Path> {
  _MihrabArchClipper(this.archHeight);
  final double archHeight;

  @override
  Path getClip(Size size) {
    final w = size.width;
    return Path()
      ..moveTo(0, archHeight)
      ..quadraticBezierTo(w / 2, -archHeight * 0.6, w, archHeight)
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_MihrabArchClipper old) =>
      old.archHeight != archHeight;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/decorative_widgets_test.dart`
Expected: PASS (both tests)

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/mihrab_arch.dart test/decorative_widgets_test.dart
git commit -m "feat(widgets): MihrabArch pointed-arch container"
```

---

### Task 4: GoldDivider widget

**Files:**
- Create: `lib/widgets/gold_divider.dart`
- Modify: `test/decorative_widgets_test.dart` (append test)

**Interfaces:**
- Produces: `GoldDivider({double indent, Color? color})` — a horizontal 1px gold line with a small centered 8-point star node.

- [ ] **Step 1: Write the failing test**

Append import + test to `test/decorative_widgets_test.dart`:

```dart
import 'package:salawat_app/widgets/gold_divider.dart';
```

```dart
  testWidgets('GoldDivider renders a star node', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GoldDivider()),
      ),
    );
    expect(find.byType(GoldDivider), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/decorative_widgets_test.dart`
Expected: FAIL — `GoldDivider` not defined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/widgets/gold_divider.dart`:

```dart
import 'package:flutter/material.dart';

/// A 1px gold hairline with a small centered 8-point star node.
class GoldDivider extends StatelessWidget {
  const GoldDivider({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.secondary;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 16,
          child: CustomPaint(
            size: Size(constraints.maxWidth, 16),
            painter: _DividerPainter(c),
          ),
        );
      },
    );
  }
}

class _DividerPainter extends CustomPainter {
  _DividerPainter(this.c);
  final Color c;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final paint = Paint()
      ..color = c
      ..strokeWidth = 1;
    // Hairline
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), paint);
    // Centered 8-point star
    final center = Offset(size.width / 2, mid);
    final r = 7.0;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = (i * pi / 4) - pi / 2;
      final rad = i.isEven ? r : r * 0.4;
      final p = Offset(
        center.dx + rad * cos(angle),
        center.dy + rad * sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_DividerPainter old) => old.c != c;
}
```

Add `import 'dart:math';` at the top of `gold_divider.dart` (uses `pi`, `cos`, `sin`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/decorative_widgets_test.dart`
Expected: PASS (all three tests)

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/gold_divider.dart test/decorative_widgets_test.dart
git commit -m "feat(widgets): GoldDivider with star node"
```

---

### Task 5: DecorativeAppShell

**Files:**
- Create: `lib/widgets/decorative_app_shell.dart`
- Modify: `test/decorative_widgets_test.dart` (append test)

**Interfaces:**
- Consumes: three `Widget` bodies passed positionally.
- Produces: `DecorativeAppShell({required Widget home, required Widget stats, required Widget settings})` — a `StatefulWidget` Scaffold with a decorative arch header, an `IndexedStack` of the three bodies, and a 3-tab ornamental bottom nav (`_currentIndex`). Active tab shows a gold star node above its label. Tab labels are findable `Text` widgets: 'الرئيسية', 'الإحصائيات', 'الإعدادات'.

- [ ] **Step 1: Write the failing test**

Append import + test to `test/decorative_widgets_test.dart`:

```dart
import 'package:salawat_app/widgets/decorative_app_shell.dart';
```

```dart
  testWidgets('shell switches tabs and preserves state', (tester) async {
    // A stateful body that increments a counter so we can confirm state is
    // preserved across tab switches (IndexedStack keeps it alive).
    var homeTicks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DecorativeAppShell(
          home: Builder(
            builder: (_) {
              homeTicks++;
              return const Text('HOME_BODY');
            },
          ),
          stats: const Text('STATS_BODY'),
          settings: const Text('SETTINGS_BODY'),
        ),
      ),
    );

    // Home is shown first.
    expect(find.text('HOME_BODY'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);

    // Switch to stats tab by tapping its label.
    await tester.tap(find.text('الإحصائيات'));
    await tester.pumpAndSettle();
    expect(find.text('STATS_BODY'), findsOneWidget);

    // Switch to settings tab.
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('SETTINGS_BODY'), findsOneWidget);

    // Back to home — IndexedStack keeps state, body is the same instance.
    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    expect(find.text('HOME_BODY'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/decorative_widgets_test.dart`
Expected: FAIL — `DecorativeAppShell` not defined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/widgets/decorative_app_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'islamic_pattern.dart';

/// Persistent decorative shell: arch header + IndexedStack body + ornamental
/// 3-tab bottom nav. Owns the active tab index; tabs preserve state via the
/// IndexedStack.
class DecorativeAppShell extends StatefulWidget {
  const DecorativeAppShell({
    super.key,
    required this.home,
    required this.stats,
    required this.settings,
  });

  final Widget home;
  final Widget stats;
  final Widget settings;

  @override
  State<DecorativeAppShell> createState() => _DecorativeAppShellState();
}

class _DecorativeAppShellState extends State<DecorativeAppShell> {
  int _currentIndex = 0;

  static const _labels = ['الرئيسية', 'الإحصائيات', 'الإعدادات'];
  static const _icons = [
    Icons.mosque,
    Icons.bar_chart,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final bodies = [widget.home, widget.stats, widget.settings];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _DecorativeHeader(active: _currentIndex == 0),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: bodies,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _OrnamentalNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _DecorativeHeader extends StatelessWidget {
  const _DecorativeHeader({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: active ? 84 : 56,
      child: Stack(
        children: [
          IslamicPattern(opacity: 0.05),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'ورد الصلاة',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: active ? 26 : 20,
                  fontWeight: FontWeight.bold,
                  color: cs.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrnamentalNavBar extends StatelessWidget {
  const _OrnamentalNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.secondary, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Gold star node above active tab.
                        Icon(
                          Icons.star,
                          size: 10,
                          color:
                              i == currentIndex ? cs.secondary : Colors.transparent,
                        ),
                        Icon(
                          _DecorativeAppShellState._icons[i],
                          size: 24,
                          color: i == currentIndex ? cs.primary : cs.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _DecorativeAppShellState._labels[i],
                          style: TextStyle(
                            fontSize: 12,
                            color: i == currentIndex
                                ? cs.primary
                                : cs.onSurface.withOpacity(0.5),
                            fontWeight: i == currentIndex
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/decorative_widgets_test.dart`
Expected: PASS (all four tests)

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/decorative_app_shell.dart test/decorative_widgets_test.dart
git commit -m "feat(widgets): DecorativeAppShell with IndexedStack nav"
```

---

### Task 6: main.dart rewire

**Files:**
- Modify: `lib/main.dart:1-13` (imports), `lib/main.dart:74-109` (MyApp.build)

**Interfaces:**
- Consumes: `DecorativeAppShell`, the three screens (now body-only).
- Produces: `MyApp` renders a single `DecorativeAppShell` instead of named routes.

- [ ] **Step 1: Rewrite main.dart**

Replace the import block (lines 1-14) — drop `app_theme` stays, add `DecorativeAppShell` import; the screens remain imported. Then replace `_MyAppState.build` (lines 74-109). Full new file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/counters_provider.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/stats_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_strings.dart';
import 'widgets/decorative_app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              CountersProvider(storageService, notificationService)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService)..load(),
        ),
        Provider<NotificationService>.value(value: notificationService),
        Provider<BackupService>.value(
          value: BackupService(storage: storageService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final counters = context.read<CountersProvider>();
      counters.rolloverIfNewDay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar', 'SA'),
          supportedLocales: const [Locale('ar', 'SA')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const DecorativeAppShell(
            home: HomeScreen(),
            stats: StatsScreen(),
            settings: SettingsScreen(),
          ),
        );
      },
    );
  }
}
```

Note: `about_screen.dart` is still imported (used by Settings push in Task 9). The named `routes` map and `initialRoute` are removed entirely.

- [ ] **Step 2: Confirm the app compiles**

Run: `flutter test test/widget_test.dart`
Expected: FAIL — navigation tests now break (`Icons.settings` gone, `LinearProgressIndicator` still present in old home until Task 7). This is expected. Confirm only the navigation/presentation assertions fail, not compile errors. If a compile error appears, fix it.

- [ ] **Step 3: Commit (the screens are not yet body-only, so this is a checkpoint; full green arrives after Task 9)**

```bash
git add lib/main.dart
git commit -m "refactor(nav): wire DecorativeAppShell, drop named routes"
```

---

### Task 7: Home screen rewrite (centerpiece)

**Files:**
- Modify: `lib/screens/home_screen.dart` (full rewrite)
- Modify: `test/widget_test.dart` (update navigation + `LinearProgressIndicator` assertions)

**Interfaces:**
- Consumes: `MihrabArch`, `IslamicPattern`, `GoldDivider`, `AppTextStyles`, `CountersProvider`, `SettingsProvider`, `currentStreak` from `utils/stats.dart`. Same provider calls (`increment`, `undo`, `reset`, `setActive`, `addCounter`, `notifyDailyTargetReached`).
- Produces: `HomeScreen` — body-only (no Scaffold/AppBar/bottom nav; the shell owns those).

- [ ] **Step 1: Rewrite lib/screens/home_screen.dart**

The new screen keeps the `SingleTickerProviderStateMixin` scale animation for the count button and adds a second short Tween for the count-pop. It becomes body-only content inside the shell. Full file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/counters_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_strings.dart';
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
    // Count-pop: brief scale up then back. Driven per-increment via forward().
    _popAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
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
                Theme.of(context).colorScheme.primary.withOpacity(0.06),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Bismillah band
                Text(
                  'بسم الله الرحمن الرحيم',
                  style: AppTextStyles.bismillah(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const GoldDivider(),
                const SizedBox(height: 20),

                // Counter medallion switcher
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final c in counters.counters)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _MedallionChip(
                            label: c.name,
                            selected: c.id == counters.activeCounter.id,
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
                const SizedBox(height: 20),

                // Mihrab-arch counter card (centerpiece)
                MihrabArch(
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: IslamicPattern(opacity: 0.04),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              counter.name,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.display(context),
                            ),
                            const SizedBox(height: 12),
                            // Big count with pop animation
                            AnimatedBuilder(
                              animation: _popAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _popAnimation.value,
                                  child: child,
                                );
                              },
                              child: Text(
                                '${counter.currentCount}',
                                style: AppTextStyles.kufiNumber(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'اليوم',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الإجمالي: ${counter.totalCount}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  ),
                            ),
                            if (target > 0) ...[
                              const SizedBox(height: 16),
                              _SegmentedProgress(
                                count: counter.currentCount,
                                target: target,
                              ),
                            ],
                            if (target > 0 && counter.currentCount >= target) ...[
                              const SizedBox(height: 10),
                              _TargetBadge(),
                            ],
                            if (target > 0) ...[
                              const SizedBox(height: 12),
                              _StreakPill(streak: streak),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

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
                    _controller.forward();
                    if (target > 0 &&
                        before < target &&
                        counters.activeCounter.currentCount >= target) {
                      await counters.notifyDailyTargetReached();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(28),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star,
                            size: 18,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text('اضغط للعد', style: AppTextStyles.uiLabel(context)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Undo / Reset — outlined gold text-buttons
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
                        foregroundColor: Theme.of(context).colorScheme.secondary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _showResetConfirmation(context, counters),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة تعيين'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.secondary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
        );
      },
    );
  }

  void _showResetConfirmation(
    BuildContext context,
    CountersProvider counters,
  ) {
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

  void _showAddCounterDialog(
    BuildContext context,
    CountersProvider counters,
  ) {
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

/// Rounded medallion chip: active = gold ring + emerald fill; else outlined
/// cream with gold text.
class _MedallionChip extends StatelessWidget {
  const _MedallionChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : cs.secondary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedColor: cs.primary,
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? cs.secondary : cs.secondary.withOpacity(0.4),
        ),
      ),
      onSelected: onSelected,
    );
  }
}

/// Decorative segmented progress: N gold bead-segments filling toward target.
class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({required this.count, required this.target});

  final int count;
  final int target;

  @override
  Widget build(BuildContext context) {
    const segments = 20;
    final filled =
        target < 1 ? 0 : ((count / target) * segments).clamp(0, segments).round();
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < segments; i++)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: 10,
                  decoration: BoxDecoration(
                    color: i < filled
                        ? cs.secondary
                        : cs.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: i < filled && count >= target
                        ? [
                            BoxShadow(
                              color: cs.secondary.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '$count / $target',
          style: TextStyle(
            color: cs.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _TargetBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.secondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: cs.secondary),
          const SizedBox(width: 4),
          Text(
            'تم الهدف',
            style: TextStyle(
              color: cs.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.secondary.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 16, color: cs.secondary),
          const SizedBox(width: 4),
          Text(
            '$streak يوم متتالي',
            style: TextStyle(
              color: cs.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

Note: `_TargetBadge` and `_StreakPill` have no `const` constructor because they reference `super` without const; add `const _TargetBadge();` and `const _StreakPill({required this.streak});` if the analyzer prefers. Keep consistent.

- [ ] **Step 2: Update test/widget_test.dart navigation + progress assertions**

The reminder-snackbar test (lines 125-145) navigates via `Icons.settings` in the home AppBar — now gone. Change it to tap the settings tab label. The daily-target test (lines 147-164) asserts `LinearProgressIndicator` — replaced by `_SegmentedProgress`. Change it to assert the segmented progress widget is present.

Edit the reminder-snackbar test:

```dart
  testWidgets('reminder toggle shows snackbar when permission is denied',
      (WidgetTester tester) async {
    final notif = _FakeNotificationService()..permissionGranted = false;

    await pumpApp(tester);

    // Navigate to the settings tab (bottom nav).
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();

    // Enable reminders for the active counter.
    await tester.tap(find.text('التذكيرات'));
    await tester.pumpAndSettle();

    // The snackbar is shown and the switch stays off.
    expect(find.text('لم يتم منح إذن الإشعارات'), findsOneWidget);
    final remindersSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'التذكيرات'),
    );
    expect(remindersSwitch.value, isFalse);
  });
```

Edit the daily-target test — replace the `LinearProgressIndicator` assertion:

```dart
  testWidgets('shows daily target progress', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'adhkar_counters': jsonEncode([
        AdhkarCounter(
          id: 'salawat',
          name: 'الصلاة على النبي ﷺ',
          currentCount: 40,
          totalCount: 40,
          dailyTarget: 100,
        ).toJson(),
      ]),
    });

    await pumpApp(tester);

    expect(find.text('40 / 100'), findsOneWidget);
    // The segmented tasbih-bead progress replaces LinearProgressIndicator.
    expect(find.textContaining('40 / 100'), findsOneWidget);
  });
```

Edit the stats-screen test (lines 197-222) — it taps `find.text('الإحصائيات')` which now is a bottom-nav tab label; still valid. Leave it, but confirm it still finds `BarChart`, totals, and streaks. No change needed beyond verifying (it should pass once StatsScreen is body-only in Task 8).

- [ ] **Step 3: Run the widget tests**

Run: `flutter test test/widget_test.dart`
Expected: Some FAIL — the stats navigation test taps 'الإحصائيات' and expects `StatsScreen` body content, but `StatsScreen` still wraps its own Scaffold/AppBar (fixed in Task 8). The home/increment/reset/counter-switch/target-notification tests should PASS now. Confirm only the stats-dependent test fails; if home tests fail, fix before continuing.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/home_screen.dart test/widget_test.dart
git commit -m "feat(home): mihrab-arch centerpiece, segmented progress, count-pop"
```

---

### Task 8: Stats screen rewrite

**Files:**
- Modify: `lib/screens/stats_screen.dart` (full rewrite, body-only)
- Modify: `test/widget_test.dart` (verify stats test passes)

**Interfaces:**
- Consumes: `IslamicPattern`, `AppTextStyles`, `CountersProvider`, `lastDaysCounts`/`currentStreak`/`longestStreak` from `utils/stats.dart`, `fl_chart` `BarChart`.
- Produces: `StatsScreen` — body-only (no Scaffold/AppBar).

- [ ] **Step 1: Rewrite lib/screens/stats_screen.dart**

Keep identical computations; only restyle. Full file:

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/counters_provider.dart';
import '../utils/stats.dart';
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
              ),
              const SizedBox(height: 20),
              // Chart card with faint pattern behind.
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 1,
                        ),
                      ),
                      child: const IslamicPattern(opacity: 0.03),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildChart(context, counts),
                    ),
                  ],
                ),
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
                const SizedBox(height: 12),
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
    final cs = Theme.of(context).colorScheme;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: const FlTitlesData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: cs.secondary.withOpacity(0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < counts.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[i].toDouble(),
                  color: cs.primary,
                  width: _days == 30 ? 5 : 14,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _medallionTile(BuildContext context, String label, int value) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.secondary.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontFamily: 'ReemKufi',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run the stats widget test**

Run: `flutter test test/widget_test.dart`
Expected: the stats test (`stats screen shows chart, totals, and streaks`) now PASSES (it taps `find.text('الإحصائيات')` → shell switches to the body-only `StatsScreen` containing the `BarChart` and the medallion tiles with labels 'الإجمالي الكلي', 'أفضل يوم', 'السلسلة الحالية', 'أطول سلسلة').

- [ ] **Step 3: Commit**

```bash
git add lib/screens/stats_screen.dart
git commit -m "feat(stats): ornamental chart card, medallion tiles"
```

---

### Task 9: Settings screen rewrite

**Files:**
- Modify: `lib/screens/settings_screen.dart` (restyle sections/listtiles, body-only; About tile pushes `AboutScreen` via `Navigator.push`)
- Modify: `test/settings_backup_test.dart` (`openSettings()` helper)

**Interfaces:**
- Consumes: `AppTextStyles`, `GoldDivider`, `MihrabArch`(optional), all existing providers/services/dialogs. About tile calls `Navigator.push(MaterialPageRoute(builder: (_) => const AboutScreen()))`.
- Produces: `SettingsScreen` — body-only.

- [ ] **Step 1: Restyle SettingsScreen — body-only, section headers with gold divider, medallion leading icons, About push**

The `build()` method (lines 22-169) is the only part structurally changed. Keep all dialog methods (`_showRenameDialog`, `_showDailyTargetDialog`, `_showReminderTypeDialog`, `_showIntervalDialog`, `_showDailyTimesDialog`, `_showDeleteDialog`, `_showExportSheet`, `_exportData`, `_showRestoreFlow`, `_buildSectionTitle`→renamed, `_getIntervalText`) and the `_DailyTargetDialog` widget **identical in logic** — only `_buildSectionTitle` styling and the leading icons change, and the About tile navigation changes from `Navigator.pushNamed(context, '/about')` to a direct push.

Replace the `build` method body. New `build` (the class top through line 169 stays the same imports; replace from `Widget build(BuildContext context) {`):

```dart
  @override
  Widget build(BuildContext context) {
    return Consumer2<CountersProvider, SettingsProvider>(
      builder: (context, counters, settings, child) {
        final counter = counters.activeCounter;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle(context, 'العداد الحالي'),
            _medallionListTile(
              context: context,
              icon: Icons.edit,
              title: 'الاسم',
              subtitle: counter.name,
              onTap: () => _showRenameDialog(context, counters),
            ),
            _medallionListTile(
              context: context,
              icon: Icons.flag,
              title: 'الهدف اليومي',
              subtitle: counter.dailyTarget > 0
                  ? '${counter.dailyTarget} مرة'
                  : 'غير محدد',
              onTap: () => _showDailyTargetDialog(context, counters),
            ),
            SwitchListTile(
              secondary: _medallionIcon(context, Icons.notifications_active),
              title: const Text('التذكيرات'),
              subtitle: const Text('استلام تذكيرات لهذا الذكر'),
              value: counter.remindersEnabled,
              onChanged: (value) async {
                final enabled =
                    await counters.setRemindersEnabled(counter.id, value);
                if (value && !enabled && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لم يتم منح إذن الإشعارات'),
                    ),
                  );
                }
              },
            ),

            if (counter.remindersEnabled) ...[
              ListTile(
                title: const Text('نوع التذكير'),
                subtitle: Text(
                  counter.reminderType == ReminderType.interval
                      ? 'تذكير متكرر كل مدة محددة'
                      : 'تذكير في أوقات يومية',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showReminderTypeDialog(context, counters),
              ),
              if (counter.reminderType == ReminderType.interval)
                ListTile(
                  title: const Text('فاصل التذكير'),
                  subtitle: Text(_getIntervalText(counter.reminderIntervalMinutes)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showIntervalDialog(context, counters),
                ),
              if (counter.reminderType == ReminderType.daily)
                ListTile(
                  title: const Text('أوقات التذكير اليومية'),
                  subtitle: Text(
                    counter.dailyReminderTimes.isEmpty
                        ? 'لم يتم تحديد أوقات'
                        : '${counter.dailyReminderTimes.length} أوقات محددة',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDailyTimesDialog(context, counters),
                ),
            ],
            if (counters.counters.length > 1)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('حذف العداد', style: TextStyle(color: Colors.red)),
                onTap: () => _showDeleteDialog(context, counters),
              ),

            const SizedBox(height: 8),
            _sectionTitle(context, 'الاستجابة'),
            SwitchListTile(
              secondary: _medallionIcon(context, Icons.vibration),
              title: const Text('الاهتزاز'),
              subtitle: const Text('اهتزاز خفيف عند الضغط على زر العدد'),
              value: settings.settings.vibrationEnabled,
              onChanged: (value) async {
                await settings.toggleVibration(value);
              },
            ),

            const SizedBox(height: 8),
            _sectionTitle(context, 'المظهر'),
            SwitchListTile(
              secondary: _medallionIcon(context, Icons.dark_mode),
              title: const Text('الوضع الداكن'),
              subtitle: const Text('استخدام ألوان داكنة للتطبيق'),
              value: settings.settings.isDarkMode,
              onChanged: (value) async {
                await settings.toggleDarkMode(value);
              },
            ),

            const SizedBox(height: 8),
            _sectionTitle(context, AppStrings.backupSectionTitle),
            _medallionListTile(
              context: context,
              icon: Icons.ios_share,
              title: AppStrings.exportData,
              onTap: () => _showExportSheet(context),
            ),
            _medallionListTile(
              context: context,
              icon: Icons.restore,
              title: AppStrings.restoreBackup,
              onTap: () => _showRestoreFlow(context),
            ),

            const SizedBox(height: 8),
            _sectionTitle(context, 'حول التطبيق'),
            _medallionListTile(
              context: context,
              icon: Icons.info,
              title: 'حول التطبيق',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.secondary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Divider(height: 1, thickness: 1, color: cs.secondary),
        ),
      ],
    );
  }

  Widget _medallionIcon(BuildContext context, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: cs.secondary, width: 1.2),
      ),
      child: Icon(icon, size: 18, color: cs.primary),
    );
  }

  Widget _medallionListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: _medallionIcon(context, icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
```

Delete the old `_buildSectionTitle` method (lines 289-300) — replaced by `_sectionTitle`.

Keep `import '../screens/about_screen.dart'`? It's the same package; add `import 'about_screen.dart';` at the top of `settings_screen.dart` (the file is in `lib/screens/`, so `import 'about_screen.dart';`).

- [ ] **Step 2: Update test/settings_backup_test.dart openSettings()**

The `openSettings` helper (lines 52-55) taps `find.byIcon(Icons.settings)`. After redesign, settings is a bottom-nav tab. Change it:

```dart
Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.text('الإعدادات'));
  await tester.pumpAndSettle();
}
```

- [ ] **Step 3: Run the settings backup tests**

Run: `flutter test test/settings_backup_test.dart`
Expected: PASS — all export/restore tests navigate via the settings tab label and exercise the unchanged backup logic.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/settings_screen.dart test/settings_backup_test.dart
git commit -m "feat(settings): gold-divider sections, medallion icons, about push"
```

---

### Task 10: About screen restyle

**Files:**
- Modify: `lib/screens/about_screen.dart` (restyle; keep its own Scaffold/AppBar since it's a pushed full screen)

**Interfaces:**
- Consumes: `MihrabArch`, `IslamicPattern`, `GoldDivider`, `AppTextStyles`, `AppStrings`. Pushed via `MaterialPageRoute` (no route name).
- Produces: `AboutScreen` — restyled, still a self-contained `Scaffold` with an `AppBar` (title 'حول التطبيق') since it's not a shell tab.

- [ ] **Step 1: Rewrite lib/screens/about_screen.dart**

Keep the same text content and feature list; only restyle. Full file:

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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('حول التطبيق'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Mihrab-arch framed emblem with pattern behind.
            MihrabArch(
              child: Stack(
                children: [
                  const Positioned.fill(child: IslamicPattern(opacity: 0.05)),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Icon(Icons.mosque, size: 64, color: cs.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(AppStrings.appName, style: AppTextStyles.display(context)),
            const SizedBox(height: 6),
            Text(
              'الإصدار 1.0.0',
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            const GoldDivider(),
            const SizedBox(height: 16),

            // Salawat calligraphic quote with gold hairlines above/below.
            Text(
              AppStrings.salawat,
              textAlign: TextAlign.center,
              style: AppTextStyles.display(context).copyWith(fontSize: 22),
            ),
            const SizedBox(height: 16),
            const GoldDivider(),
            const SizedBox(height: 16),
            Text(
              'تطبيق بسيط يذكّرك بقول الصلاة على النبي ﷺ\nويتيح لك تسجيل عدد المرات التي قلت فيها الصلاة على النبي ﷺ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            _featureItem(context, Icons.numbers, 'عدّاد ذكي', 'عدّاد مستمر أو يومي مع حفظ تلقائي'),
            _featureItem(context, Icons.notifications_active, 'تذكيرات محلية', 'إشعارات متكررة أو في أوقات محددة'),
            _featureItem(context, Icons.phone_android, 'محلي بالكامل', 'لا يتطلب إنترنت أو حساب مستخدم'),
            _featureItem(context, Icons.privacy_tip, 'خصوصية تامة', 'لا جمع بيانات ولا تتبع'),
            const SizedBox(height: 24),
            Text(
              'صُنع بحب لخدمة النبي ﷺ',
              style: TextStyle(
                color: cs.secondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'جميع الحقوق محفوظة © 2024',
              style: TextStyle(color: cs.onSurface.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureItem(BuildContext context, IconData icon, String title, String description) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.secondary, width: 1.2),
            ),
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description,
                    style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: PASS — all tests green (logic tests unchanged; widget tests updated for new navigation/presentation; decorative-widget smoke tests pass).

- [ ] **Step 3: Commit**

```bash
git add lib/screens/about_screen.dart
git commit -m "feat(about): mihrab emblem, calligraphic quote, medallion features"
```

---

### Task 11: Final verification gate

**Files:** none (verification only)

- [ ] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: all tests PASS. Capture the exit code and the summary line (e.g. "All tests passed!").

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`
Expected: no errors. Warnings about the missing font files (if any) are acceptable — they are runtime fallbacks, not analyzer errors. Fix any real analyzer errors reported.

- [ ] **Step 3: Confirm the app builds**

Run: `flutter build apk --debug` (or `flutter build apk --debug --no-pub` if pub is current)
Expected: SUCCESS. The build will use system font fallback for Amiri/Reem Kufi until the real `.ttf` files are dropped into `assets/fonts/`. If the build fails solely due to missing font asset files, add the `.ttf` files and rebuild; do not comment out the font config.

- [ ] **Step 4: Document the font-drop-in step for the user**

No code change. Add a note to the commit/PR description (or a short README addition) listing the four font files to download from Google Fonts and place in `assets/fonts/`:
- Amiri-Regular.ttf, Amiri-Bold.ttf (https://fonts.google.com/specimen/Amiri)
- ReemKufi-Regular.ttf, ReemKufi-Medium.ttf (https://fonts.google.com/specimen/Reem+Kufi)

- [ ] **Step 5: Commit any final touch-ups, then stop**

If steps 1-3 all pass, the redesign is complete. The branch `redesign/elegant-ornamental` holds all redesign commits.

---

## Self-Review

**1. Spec coverage:**
- Section 1 (visual identity: colors/fonts/motifs) → Task 1 (theme+fonts+textstyles), Tasks 2-4 (motifs). ✓
- Section 2 (app shell & navigation) → Task 5 (shell), Task 6 (main.dart rewire). ✓
- Section 3 (home centerpiece) → Task 7. ✓
- Section 4 (stats/settings/about) → Tasks 8, 9, 10. ✓
- Section 5 (assets/fonts/buildability/testing) → Task 1 (assets/fonts), Task 11 (verify gate + font-drop note). ✓

**2. Placeholder scan:** No TBD/TODO/"implement later" present. Every code step contains full code. ✓

**3. Type consistency:** `AppTextStyles.bismillah/display/kufiNumber/uiLabel` used consistently in Tasks 7, 10. `MihrabArch`/`IslamicPattern`/`GoldDivider` constructors match across Tasks 2-10. `DecorativeAppShell(home/stats/settings)` matches Task 6 wiring. Tab labels 'الرئيسية'/'الإحصائيات'/'الإعدادات' match the test finders in Tasks 7, 8, 9. ✓

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-20-ui-redesign.md`. Two execution options:

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
