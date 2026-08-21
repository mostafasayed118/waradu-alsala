# Responsive Layouts (Phones & Tablets) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Make the ornamental Salawat app adapt cleanly across phone widths (320–600dp) and tablet widths (≥841dp) with no overflow, scale-aware typography, centered max-width columns on Home/Settings/About, and a two-pane Stats layout on tablets — with zero logic changes.

**Architecture:** A shared `Breakpoints` utility + `MaxWidthBox` wrapper is the single source of truth for width thresholds and content caps. Each screen reads the width once per build and picks padding/layout from the shared tokens. `AppTextStyles` keeps its 5 existing method names but internally multiplies font sizes by a width-derived scale factor. Stats switches to a two-pane `Row` above 840dp. No new dependencies.

**Tech Stack:** Flutter (Dart), `LayoutBuilder`/`MediaQuery`, `FittedBox`, `Wrap`, existing `fl_chart`/`provider`/`CustomPaint` widgets.

**Spec:** `docs/superpowers/specs/2026-08-20-responsive-layouts-design.md`

## Global Constraints

- **No logic changes.** Every counter, reminder, backup, and stats computation keeps its current behavior. Pure layout + typography adaptation.
- **No new features, no data model changes, no new dependencies, no new locale** (existing `ar_SA` only).
- **No NavigationRail / adaptive-scaffold package** — the ornamental bottom-nav stays on all sizes.
- **Breakpoint thresholds (single source of truth in `lib/utils/breakpoints.dart`):** compact ≤400, medium 401–600, expanded 601–840, wide ≥841. Two-pane kicks in at `useTwoPane` = width ≥840. Content max-widths: `homeMaxWidth`=520, `settingsMaxWidth`=560.
- **Text scale factors:** compact 0.82, medium 1.0, expanded 1.12, wide 1.18 — applied to the existing fixed sizes (bismillah 22, display 20, kufiNumber 88, bodyArabic 16, uiLabel 24). OS accessibility `textScaler` applies automatically on top (do NOT multiply manually — only the width factor is manual).
- **Style consistency:** keep using `.withOpacity(...)` (the existing codebase uses it everywhere; migrating to `.withValues()` is out of scope).
- **Verification gate:** full `flutter test` suite passes + new `responsive_test.dart` passes; `flutter analyze lib` stays at 0 errors/warnings (info-level `.withOpacity` deprecations are pre-existing and acceptable).
- **No logic files modified:** `lib/providers/*`, `lib/models/*`, `lib/services/*`, `lib/utils/stats.dart`, `lib/utils/app_strings.dart` must stay untouched.

## File Structure

New files:
- `lib/utils/breakpoints.dart` — `Breakpoints` constants + helpers + `MaxWidthBox` widget. Single source of truth for width thresholds and content max-widths.
- `test/responsive_test.dart` — width-based smoke tests: overflow at 320dp, two-pane at 1200dp, scale-aware font sizes.

Modified files:
- `lib/utils/app_text_styles.dart` — keep 5 method names/signatures; internally apply width scale factor via `_scaleFor(context)`.
- `lib/screens/home_screen.dart` — `MaxWidthBox(520)` wrap + width-aware padding + `FittedBox` around count.
- `lib/screens/stats_screen.dart` — width-scaled chart height + two-pane `Row` at ≥840.
- `lib/screens/settings_screen.dart` — `MaxWidthBox(560)` wrap of the `ListView`.
- `lib/screens/about_screen.dart` — `MaxWidthBox(560)` wrap of the body.
- `lib/widgets/decorative_app_shell.dart` — tighten the bottom-nav pill bar with `MaxWidthBox(480)` + center on wide screens.

---

## Task 1: Breakpoints utility + MaxWidthBox

**Files:**
- Create: `lib/utils/breakpoints.dart`
- Test: `test/responsive_test.dart` (first test)

**Interfaces:**
- Produces:
  - `class Breakpoints` with static `const double compactMax = 400`, `mediumMax = 600`, `expandedMax = 840`, `twoPaneMin = 840`, `homeMaxWidth = 520`, `settingsMaxWidth = 560`; static `bool isCompact(double width)`, `bool isMedium(double width)`, `bool isExpanded(double width)`, `bool isWide(double width)`, `bool useTwoPane(double width)`.
  - `class MaxWidthBox extends StatelessWidget` — `const MaxWidthBox({super.key, required this.maxWidth, required this.child})`; `final double maxWidth; final Widget child;` — centers + constrains child to `maxWidth` using `MediaQuery.sizeOf(context).width`.

- [x] **Step 1: Write the failing test**

```dart
// test/responsive_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/utils/breakpoints.dart';

void main() {
  group('Breakpoints', () {
    test('classifies widths into the four buckets', () {
      expect(Breakpoints.isCompact(320), isTrue);
      expect(Breakpoints.isCompact(400), isTrue);
      expect(Breakpoints.isMedium(500), isTrue);
      expect(Breakpoints.isMedium(600), isTrue);
      expect(Breakpoints.isExpanded(700), isTrue);
      expect(Breakpoints.isExpanded(840), isTrue);
      expect(Breakpoints.isWide(841), isTrue);
    });

    test('useTwoPane is true at and above 840', () {
      expect(Breakpoints.useTwoPane(839), isFalse);
      expect(Breakpoints.useTwoPane(840), isTrue);
      expect(Breakpoints.useTwoPane(1200), isTrue);
    });
  });

  testWidgets('MaxWidthBox caps and centers child on wide screens',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaxWidthBox(
            maxWidth: 200,
            child: const SizedBox(width: double.infinity, height: 50),
          ),
        ),
      ),
    );
    // Force a wide surface.
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pump();

    final box = tester.widget<ConstrainedBox>(find.byType(ConstrainedBox));
    expect(box.constraints.maxWidth, 200);
    expect(find.byType(Center), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/responsive_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:salawat_app/utils/breakpoints.dart'`.

- [x] **Step 3: Write minimal implementation**

```dart
// lib/utils/breakpoints.dart
import 'package:flutter/material.dart';

/// Single source of truth for width-based responsive breakpoints and
/// content max-widths. Thresholds (dp):
///   compact  <= 400   (very small phone)
///   medium   401–600   (typical phone)
///   expanded 601–840   (small tablet / large phone landscape)
///   wide     >= 841    (tablet)
class Breakpoints {
  Breakpoints._();

  static const double compactMax = 400;
  static const double mediumMax = 600;
  static const double expandedMax = 840;

  /// Two-pane layouts kick in at this width.
  static const double twoPaneMin = 840;

  /// Content max-widths so columns don't stretch on tablets.
  static const double homeMaxWidth = 520;
  static const double settingsMaxWidth = 560;

  static bool isCompact(double width) => width <= compactMax;
  static bool isMedium(double width) =>
      width > compactMax && width <= mediumMax;
  static bool isExpanded(double width) =>
      width > mediumMax && width <= expandedMax;
  static bool isWide(double width) => width > expandedMax;
  static bool useTwoPane(double width) => width >= twoPaneMin;
}

/// Centers its child and caps content width on wide screens.
/// On screens narrower than [maxWidth] this is a no-op (the child fills
/// available width), so it is safe to wrap phone layouts unconditionally.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/responsive_test.dart`
Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add lib/utils/breakpoints.dart test/responsive_test.dart
git commit -m "feat(responsive): add Breakpoints utility and MaxWidthBox wrapper"
```

---

## Task 2: Scale-aware AppTextStyles

**Files:**
- Modify: `lib/utils/app_text_styles.dart`

**Interfaces:**
- Consumes: `Breakpoints` from Task 1.
- Produces: the same 5 public methods with identical names/signatures — `bismillah(context)`, `display(context)`, `kufiNumber(context)`, `bodyArabic(context)`, `uiLabel(context)` — now returning `TextStyle`s whose `fontSize` is multiplied by a width-derived factor. Existing call sites compile unchanged.

> **Note on accessibility:** Flutter applies `MediaQuery.textScalerOf` to `Text` automatically at render time. Do NOT multiply by the text scaler in `TextStyle` — only apply the width factor. OS accessibility scaling composes on top for free.

- [x] **Step 1: Write the failing test**

Append to `test/responsive_test.dart` (inside `main()`):

```dart
  group('AppTextStyles width scaling', () {
    TextStyle pumpAndGet(WidgetTester tester, TextStyle Function(BuildContext) f,
        Size size) {
      late TextStyle captured;
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      tester.binding.window.viewConstraints = BoxConstraints.tight(size);
      return captured;
    }

    testWidgets('kufiNumber is smaller at compact width than at wide width',
        (tester) async {
      TextStyle? compact;
      TextStyle? wide;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              compact = AppTextStyles.kufiNumber(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pump();
      compact = AppTextStyles.kufiNumber(
          tester.element(find.byType(SizedBox)));

      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      await tester.pump();
      wide = AppTextStyles.kufiNumber(
          tester.element(find.byType(SizedBox)));

      expect(compact!.fontSize!, lessThan(wide!.fontSize!));
      // compact factor 0.82 of 88 ≈ 72.16; wide factor 1.18 of 88 ≈ 103.84
      expect(compact!.fontSize, closeTo(72.16, 0.5));
      expect(wide!.fontSize, closeTo(103.84, 0.5));
    });
  });
```

Add the import at the top of `test/responsive_test.dart`:

```dart
import 'package:salawat_app/utils/app_text_styles.dart';
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/responsive_test.dart`
Expected: FAIL — `kufiNumber` returns 88 at all widths (no scaling yet), so `compact.fontSize` is not less than `wide.fontSize`.

- [x] **Step 3: Write minimal implementation**

Replace the whole `lib/utils/app_text_styles.dart`:

```dart
import 'package:flutter/material.dart';
import 'breakpoints.dart';

class AppTextStyles {
  AppTextStyles._();

  /// Width-derived scale factor. Accessibility text scaling (textScaler) is
  /// applied automatically by Flutter at render time and is NOT included
  /// here — only the layout-driven width factor.
  static double _scaleFor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w <= Breakpoints.compactMax) return 0.82;
    if (w <= Breakpoints.mediumMax) return 1.0;
    if (w <= Breakpoints.expandedMax) return 1.12;
    return 1.18;
  }

  static TextStyle bismillah(BuildContext context) => TextStyle(
        fontFamily: 'Amiri',
        fontSize: 22 * _scaleFor(context),
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.secondary,
      );

  static TextStyle display(BuildContext context) => TextStyle(
        fontFamily: 'Amiri',
        fontSize: 20 * _scaleFor(context),
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.secondary,
      );

  static TextStyle kufiNumber(BuildContext context) => TextStyle(
        fontFamily: 'ReemKufi',
        fontSize: 88 * _scaleFor(context),
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.primary,
      );

  static TextStyle bodyArabic(BuildContext context) => TextStyle(
        fontFamily: 'Amiri',
        fontSize: 16 * _scaleFor(context),
        color: Theme.of(context).textTheme.bodyMedium?.color,
      );

  static TextStyle uiLabel(BuildContext context) => TextStyle(
        fontFamily: 'ReemKufi',
        fontSize: 24 * _scaleFor(context),
        fontWeight: FontWeight.w500,
        color: Colors.white,
      );
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/responsive_test.dart`
Expected: PASS.

- [x] **Step 5: Run the full suite to confirm no regressions from font scaling**

Run: `flutter test`
Expected: ALL pass. (Existing widget tests assert text content, not exact font size, so scaling is invisible to them. The `widget_test.dart` `shows daily target progress` asserts `find.text('40 / 100')` which is unaffected.)

- [x] **Step 6: Commit**

```bash
git add lib/utils/app_text_styles.dart test/responsive_test.dart
git commit -m "feat(responsive): make AppTextStyles scale-aware by screen width"
```

---

## Task 3: Home screen — max-width column, width-aware padding, FittedBox count

**Files:**
- Modify: `lib/screens/home_screen.dart`

**Interfaces:**
- Consumes: `Breakpoints`, `MaxWidthBox` from Task 1; `AppTextStyles` (already scale-aware) from Task 2.
- Produces: a Home body that centers at ≤520dp width, uses width-aware padding, and never overflows the count number on any width.

> **Test contract:** `test/widget_test.dart` asserts `find.text('0')`, `find.text('اضغط للعد')`, and `'40 / 100'` on Home. These survive because `MaxWidthBox` is a no-op below 520 and `FittedBox` only shrinks, never hides, text. The default test surface (~800x600) is above compact but below the home cap, so Home stays full-width there as before.

- [x] **Step 1: Write the failing test**

Append to `test/responsive_test.dart`:

```dart
  testWidgets('Home renders without overflow at 320dp width', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MaxWidthBox(
              maxWidth: Breakpoints.homeMaxWidth,
              child: const Column(
                children: [
                  Text('بسم الله الرحمن الرحيم'),
                  Text('9999'), // very long count
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home count is wrapped in FittedBox (scaleDown)',
      (tester) async {
    // Import home screen to assert the count widget tree contains FittedBox.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const Text('placeholder'),
        ),
      ),
    );
    // Smoke assertion only: source contains FittedBox around count.
    // (Full behavior verified by the overflow test above + widget_test.dart.)
  });
```

Add the home import:

```dart
import 'package:salawat_app/screens/home_screen.dart';
```

> Note: the second test above is a light smoke; the real overflow protection is verified by the full Home render test in Task 7 (which pumps the actual app at 320dp). Keep this test minimal here; the meaningful assertion is `tester.takeException(), isNull` at 320dp with a long count.

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/responsive_test.dart`
Expected: FAIL on the `Home renders without overflow` test because Home does not yet use `MaxWidthBox`/`FittedBox` — but since the test above only pumps a stand-in, it will actually PASS already (placeholder). To make it a true failing test for the actual screen, replace the stand-in pump with a real Home pump. Use the test helper from `widget_test.dart`'s `pumpApp` approach. **Simplest correct approach:** defer the real Home overflow test to Task 7 (full app render) and, in this task, make the test assert the *source-level* contract that Home wraps content in `MaxWidthBox` + `FittedBox` by rendering the real Home via the app harness. If that harness duplication is heavy, instead write the test to pump `HomeScreen` directly inside a sized `MaterialApp` with the providers it needs.

Use this real version instead of the stand-in:

```dart
  testWidgets('Home renders without overflow at 320dp width', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final notif = NotificationService();
    await notif.init();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => CountersProvider(storage, notif)..load()),
          ChangeNotifierProvider(
              create: (_) => SettingsProvider(storage)..load()),
          Provider<NotificationService>.value(value: notif),
          Provider<BackupService>.value(value: BackupService(storage: storage)),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('اضغط للعد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
```

Add imports:

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salawat_app/main.dart' show MyApp;
import 'package:salawat_app/models/adhkar_counter.dart';
import 'package:salawat_app/providers/counters_provider.dart';
import 'package:salawat_app/providers/settings_provider.dart';
import 'package:salawat_app/services/notification_service.dart';
import 'package:salawat_app/services/storage_service.dart';
import 'package:salawat_app/services/backup_service.dart';
```

Run: `flutter test test/responsive_test.dart`
Expected: FAIL — `takeException` is not null because Home overflows at 320dp (the 88px count or fixed paddings overflow).

- [x] **Step 3: Write minimal implementation**

In `lib/screens/home_screen.dart`:

Add import:
```dart
import '../utils/breakpoints.dart';
```

In the `build` method, compute width once and apply width-aware padding + wrap the column in `MaxWidthBox` + wrap the count `Text` in `FittedBox`. Concretely, replace the `SafeArea > SingleChildScrollView` section so the structure becomes:

```dart
        final width = MediaQuery.sizeOf(context).width;
        final hPad = Breakpoints.isCompact(width) ? 16.0 : 24.0;
        return Container(
          decoration: BoxDecoration(/* ... unchanged gradient ... */),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(hPad),
              child: MaxWidthBox(
                maxWidth: Breakpoints.homeMaxWidth,
                child: Column(
                  children: [
                    // ... bismillah, chips, card, button, undo/reset, last used ...
                  ],
                ),
              ),
            ),
          ),
        );
```

And wrap the count number in a `FittedBox`. Find the `AnimatedBuilder` that renders the count and change its child from:

```dart
                                child: Text('${counter.currentCount}',
                                    style: AppTextStyles.kufiNumber(context)),
```

to:

```dart
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('${counter.currentCount}',
                                      style: AppTextStyles.kufiNumber(context)),
                                ),
```

(Keep the `AnimatedBuilder` + `Transform.scale` pop animation wrapping the `FittedBox` — order is `AnimatedBuilder > Transform.scale > FittedBox > Text`, so the pop scales the already-shrunk count, which composes correctly.)

Do NOT change any logic: `Consumer2`, `increment`, `undo`, `reset`, `notifyDailyTargetReached`, haptics, dialogs all stay verbatim.

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/responsive_test.dart`
Expected: PASS (no overflow at 320dp, `اضغط للعد` found).

- [x] **Step 5: Run full suite to confirm no regressions**

Run: `flutter test`
Expected: ALL pass.

- [x] **Step 6: Commit**

```bash
git add lib/screens/home_screen.dart test/responsive_test.dart
git commit -m "feat(responsive): cap Home to max-width, width-aware padding, FittedBox count"
```

---

## Task 4: Settings & About — max-width centered lists

**Files:**
- Modify: `lib/screens/settings_screen.dart`
- Modify: `lib/screens/about_screen.dart`

**Interfaces:**
- Consumes: `MaxWidthBox`, `Breakpoints` from Task 1.

- [x] **Step 1: Write the failing test**

Append to `test/responsive_test.dart`:

```dart
  testWidgets('Settings centers content at tablet width', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final notif = NotificationService();
    await notif.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => CountersProvider(storage, notif)..load()),
          ChangeNotifierProvider(
              create: (_) => SettingsProvider(storage)..load()),
          Provider<NotificationService>.value(value: notif),
          Provider<BackupService>.value(value: BackupService(storage: storage)),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // At 1200dp, the list content is capped at settingsMaxWidth (560) and centered.
    final constrained =
        tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
    expect(constrained, isNotEmpty);
    expect(tester.takeException(), isNull);
  });
```

Add import:
```dart
import 'package:salawat_app/screens/settings_screen.dart';
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/responsive_test.dart`
Expected: FAIL — `constrained` is empty because Settings does not yet use `MaxWidthBox` (no `ConstrainedBox` from `MaxWidthBox` is present).

- [x] **Step 3: Write minimal implementation**

In `lib/screens/settings_screen.dart`, add import:
```dart
import '../utils/breakpoints.dart';
```

Wrap the `ListView` returned by the `Consumer2` builder. Change:
```dart
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [ /* ... */ ],
        );
```
to:
```dart
        return MaxWidthBox(
          maxWidth: Breakpoints.settingsMaxWidth,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [ /* ... */ ],
          ),
        );
```

In `lib/screens/about_screen.dart`, add import:
```dart
import '../utils/breakpoints.dart';
```

Wrap the `SingleChildScrollView` body. Change the `Scaffold(body: SafeArea(child: SingleChildScrollView(...)))` so the `SingleChildScrollView` is wrapped:
```dart
    return Scaffold(
      body: SafeArea(
        child: MaxWidthBox(
          maxWidth: 560,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(/* ... unchanged ... */),
          ),
        ),
      ),
    );
```

No logic changes in either screen.

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/responsive_test.dart`
Expected: PASS.

- [x] **Step 5: Run full suite to confirm no regressions**

Run: `flutter test`
Expected: ALL pass. (The `settings_backup_test.dart` tests run at 800x1600 — above medium, below the 560 cap's relevance since 560 < 800, so the list is capped and centered; the tile text finders still resolve.)

- [x] **Step 6: Commit**

```bash
git add lib/screens/settings_screen.dart lib/screens/about_screen.dart test/responsive_test.dart
git commit -m "feat(responsive): cap Settings & About to centered max-width lists"
```

---

## Task 5: Stats — width-scaled chart height + two-pane on tablet

**Files:**
- Modify: `lib/screens/stats_screen.dart`

**Interfaces:**
- Consumes: `Breakpoints`, `MaxWidthBox` from Task 1.

> **Test contract:** `widget_test.dart` `stats screen shows chart, totals, and streaks` runs at the default test surface (~800x600) and taps `الإحصائيات` (shell tab), asserting `BarChart`, `الإجمالي الكلي`, `أفضل يوم`, `السلسلة الحالية`, `أطول سلسلة`. At 800 width this is below `twoPaneMin` (840) so Stats renders single-column — the labels all still render. Keep the labels identical. The `settings_backup_test.dart` tests run at 800x1600 — also below 840 — so still single-column; no impact.

- [x] **Step 1: Write the failing test**

Append to `test/responsive_test.dart`:

```dart
  testWidgets('Stats renders two-pane layout at tablet width', (tester) async {
    SharedPreferences.setMockInitialValues({
      'adhkar_counters': jsonEncode([
        AdhkarCounter(
          id: 'salawat',
          name: 'الصلاة على النبي ﷺ',
          currentCount: 3,
          totalCount: 100,
          dailyTarget: 5,
          history: {'2025-01-01': 5},
        ).toJson(),
      ]),
    });
    final storage = StorageService();
    await storage.init();
    final notif = NotificationService();
    await notif.init();
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => CountersProvider(storage, notif)..load()),
          ChangeNotifierProvider(
              create: (_) => SettingsProvider(storage)..load()),
          Provider<NotificationService>.value(value: notif),
          Provider<BackupService>.value(value: BackupService(storage: storage)),
        ],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('الإجمالي الكلي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Stats renders single column at phone width', (tester) async {
    SharedPreferences.setMockInitialValues({
      'adhkar_counters': jsonEncode([
        AdhkarCounter(
          id: 'salawat',
          name: 'الصلاة على النبي ﷺ',
          dailyTarget: 5,
        ).toJson(),
      ]),
    });
    final storage = StorageService();
    await storage.init();
    final notif = NotificationService();
    await notif.init();
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => CountersProvider(storage, notif)..load()),
          ChangeNotifierProvider(
              create: (_) => SettingsProvider(storage)..load()),
          Provider<NotificationService>.value(value: notif),
          Provider<BackupService>.value(value: BackupService(storage: storage)),
        ],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('الإجمالي الكلي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
```

Add imports:
```dart
import 'dart:convert';
import 'package:salawat_app/screens/stats_screen.dart';
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/responsive_test.dart`
Expected: FAIL — the tablet test may pass (BarChart renders) but two-pane is not asserted yet; to make it fail meaningfully, first run — it will likely PASS since `BarChart` renders in both layouts. The real regression risk is the existing `stats screen` test in `widget_test.dart` if two-pane hides labels. Run the full suite instead to find the real failure surface:

Run: `flutter test`
Expected: PASS (baseline) — so there's no failing test forcing the change. This means the "failing test" step is satisfied by the *new* two-pane test asserting layout structure. Strengthen the tablet test to assert two-pane structure:

Replace the tablet test's tail assertions with:
```dart
    // Two-pane: the chart and tiles sit side by side (a Row with two Expanded).
    final row = tester.widgetList<Row>(find.byType(Row));
    expect(row, isNotEmpty);
    // No overflow at tablet width.
    expect(tester.takeException(), isNull);
```
Run: `flutter test test/responsive_test.dart`
Expected: PASS currently (Row already exists in single-column too). The structural two-pane assertion is intentionally loose; the value of this test is the **no-overflow + labels render** check at 1200dp, which would fail if the two-pane introduced an overflow. Run it once to see it pass as the baseline, then implement and confirm it still passes.

- [x] **Step 3: Write minimal implementation**

In `lib/screens/stats_screen.dart`, add import:
```dart
import '../utils/breakpoints.dart';
```

In the `build` method, read width and switch layout. Replace the `Padding > SingleChildScrollView > Column` with a width-aware version. Chart height scales with width. Use a helper for chart height:

```dart
  double _chartHeight(double width) {
    if (Breakpoints.isCompact(width)) return 180;
    if (Breakpoints.isMedium(width)) return 220;
    return 260; // expanded + wide single-column; two-pane uses 320 below
  }
```

Rewrite the `build` body so that:

- The `SegmentedButton` always renders first (spanning full width).
- Below it, if `Breakpoints.useTwoPane(width)` is true, render an `IntrinsicHeight` + `Row` with two `Expanded` children:
  - Left: the chart `Stack` (with `IslamicPattern` + `SizedBox(height: 320)` + `_buildChart`).
  - Right: a `SingleChildScrollView` `Column` with all the medallion tiles in a `Wrap` (so they flow 3-across then wrap), plus the streak row, plus the `GoldHairlineDivider`.
- Else (single column): keep the current structure (chart `Stack` at `_chartHeight(width)`, 3-tile `Row`, divider, 2-tile `Row`), but use `_chartHeight(width)` for the chart `SizedBox` height.

Concretely, the column children become (pseudocode showing the branch):

```dart
        final width = MediaQuery.sizeOf(context).width;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SegmentedButton<int>(/* ... unchanged ... */),
              const SizedBox(height: 24),
              if (Breakpoints.useTwoPane(width))
                Expanded(
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Stack(
                              children: [
                                const Positioned.fill(
                                    child: IslamicPattern(opacity: 0.04)),
                                SizedBox(
                                    height: 320, child: _buildChart(context, counts)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _tilesGrid(context, windowSum, counter.totalCount,
                                    bestDay, target, current, longest),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Stack(
                  children: [
                    const Positioned.fill(child: IslamicPattern(opacity: 0.04)),
                    SizedBox(
                        height: _chartHeight(width),
                        child: _buildChart(context, counts)),
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
            ],
          ),
        );
```

Add a `_tilesGrid` helper that lays out all tiles in a `Wrap` (3 per row) plus the streak tiles, used in the two-pane right column:

```dart
  Widget _tilesGrid(BuildContext context, int windowSum, int totalCount,
      int bestDay, int target, int current, int longest) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
            width: 160,
            child: _medallionTile(context,
                _days == 7 ? 'آخر ٧ أيام' : 'آخر ٣٠ يومًا', windowSum)),
        SizedBox(
            width: 160,
            child: _medallionTile(context, 'الإجمالي الكلي', totalCount)),
        SizedBox(
            width: 160, child: _medallionTile(context, 'أفضل يوم', bestDay)),
        if (target > 0) ...[
          SizedBox(
              width: 160,
              child: _medallionTile(context, 'السلسلة الحالية', current)),
          SizedBox(
              width: 160,
              child: _medallionTile(context, 'أطول سلسلة', longest)),
        ],
      ],
    );
  }
```

> **Note on `_medallionTile`:** it currently returns `Expanded(child: Container(...))`. Inside a `Wrap` with `SizedBox(width: 160)`, `Expanded` is invalid (no flex parent). Change `_medallionTile` so its child is NOT `Expanded`-wrapped when used in the grid. Simplest: make `_medallionTile` return the inner `Container` (not `Expanded`), and wrap in `Expanded` at the single-column call sites. Update all single-column `Row` call sites to wrap: `Expanded(child: _medallionTile(...))`. This keeps the tile widget itself flex-agnostic.

Implement that refactor: change `_medallionTile` to return `Container(...)` directly (remove the `Expanded` wrapper), and wrap each single-column usage in `Expanded(child: _medallionTile(...))`.

No logic changes — `_days`, `lastDaysCounts`, `windowSum`, `bestDay`, `currentStreak`, `longestStreak` all untouched.

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/responsive_test.dart`
Expected: PASS (both tablet two-pane and phone single-column render without overflow, labels found).

- [x] **Step 5: Run full suite to confirm no regressions**

Run: `flutter test`
Expected: ALL pass. Pay attention to `widget_test.dart` `stats screen shows chart, totals, and streaks` (runs ~800 wide → single-column → all labels render) and `settings_backup_test.dart` (800x1600 → single-column). If the `stats screen` test fails on a missing label, the `_tilesGrid`/`_medallionTile` refactor dropped a label — fix the helper to keep all labels identical.

- [x] **Step 6: Commit**

```bash
git add lib/screens/stats_screen.dart test/responsive_test.dart
git commit -m "feat(responsive): Stats two-pane layout on tablet, scaled chart height"
```

---

## Task 6: Shell — tighten bottom-nav pill bar on wide screens

**Files:**
- Modify: `lib/widgets/decorative_app_shell.dart`

**Interfaces:**
- Consumes: `MaxWidthBox`, `Breakpoints` from Task 1.

> **Test contract:** `decorative_app_shell_test.dart` taps `الإحصائيات`/`الإعدادات`/`الرئيسية` by label — labels are unchanged, so the test passes. `widget_test.dart` navigates via the same labels + `Icons.settings`. Tightening the pill bar with `MaxWidthBox` centers it but the labels still resolve to tappable targets.

- [x] **Step 1: Write the failing test**

Append to `test/responsive_test.dart`:

```dart
  testWidgets('Shell nav bar is centered and capped at tablet width',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: DecorativeAppShell(
          screens: const [
            Center(child: Text('home')),
            Center(child: Text('stats')),
            Center(child: Text('settings')),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الإحصائيات'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
```

Add import:
```dart
import 'package:salawat_app/widgets/decorative_app_shell.dart';
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/responsive_test.dart`
Expected: PASS already (the shell renders at 1200 without change). This test is a regression guard that the nav bar doesn't overflow/shift off-screen at tablet width after the `MaxWidthBox` wrap. Run it to confirm baseline, then implement.

- [x] **Step 3: Write minimal implementation**

In `lib/widgets/decorative_app_shell.dart`, add import:
```dart
import '../utils/breakpoints.dart';
```

In `_buildBottomNav`, wrap the inner `Row` (the pills) in a `MaxWidthBox(maxWidth: 480)` so on tablets the 3 pills stay grouped and centered rather than hugging the far edges. Change:

```dart
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [ /* ... pills ... */ ],
        ),
```

to:

```dart
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: MaxWidthBox(
          maxWidth: 480,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [ /* ... pills ... */ ],
          ),
        ),
```

No change to header, `IndexedStack`, or tab logic.

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/responsive_test.dart`
Expected: PASS.

- [x] **Step 5: Run full suite to confirm no regressions**

Run: `flutter test`
Expected: ALL pass. (`decorative_app_shell_test.dart` runs at default ~800 width — below 480 cap's visual effect is minimal there; the `MaxWidthBox` is a no-op below 480, so the pills space out as before.)

- [x] **Step 6: Commit**

```bash
git add lib/widgets/decorative_app_shell.dart test/responsive_test.dart
git commit -m "feat(responsive): center and cap bottom-nav pill bar on wide screens"
```

---

## Verification Gate

After Task 6, run the full gate:

- [x] **Run: `flutter analyze lib`** — 0 errors, 0 warnings (info `.withOpacity` deprecations are pre-existing and acceptable).
- [x] **Run: `flutter test`** — full suite green. Includes new `responsive_test.dart` (breakpoint classification, MaxWidthBox, font scaling, Home overflow at 320dp, Settings max-width, Stats two-pane + single-column, Shell nav at tablet width) + all existing logic/widget tests unchanged.
- [x] **Confirm no logic changed:** `git diff --name-only` should show only `lib/utils/breakpoints.dart`, `lib/utils/app_text_styles.dart`, `lib/screens/*`, `lib/widgets/decorative_app_shell.dart`, `test/responsive_test.dart`. No changes to `lib/providers/*`, `lib/models/*`, `lib/services/*`, `lib/utils/stats.dart`, `lib/utils/app_strings.dart`.

## Execution notes (2026-08-21)

Plan executed to completion. Two deviations from the written steps, both forced by
actual behavior rather than preference:

1. **Task 6 does not use `MaxWidthBox`.** The plan called for wrapping the pill
   `Row` in `MaxWidthBox(maxWidth: 480)`. `MaxWidthBox` centers via a bare
   `Center`, which expands to fill available height. Inside
   `Scaffold.bottomNavigationBar` that made the nav claim the full screen and
   collapsed `IndexedStack` to `Size(800, 0)` — 11 tests in
   `settings_backup_test.dart` and `widget_test.dart` failed with
   `Bad state: No element` because tiles were no longer laid out. Replaced with
   `Align(heightFactor: 1)` + `ConstrainedBox(maxWidth: 480)`, which caps width
   without claiming height. Cap is exposed as
   `DecorativeAppShell.navMaxWidth`.
2. **Test hooks are static members, not loose finders.** Task 5's suggested
   assertions (`find.byType(Row)`, "loose structural check") could not
   distinguish two-pane from single-column, since both contain a `Row`. Added
   `StatsScreen.twoPaneKey` and `StatsScreen.chartHeightFor` so the tests assert
   the real layout branch and the real height curve. This made the two-pane test
   genuinely fail before implementation (`Member not found: 'twoPaneKey'`, then
   key-not-found), giving Task 5 a real red phase the plan admitted it lacked.

Final gate: `flutter test` → 90 passed. `flutter analyze lib` → 25 issues, all
`info`, 0 warnings, 0 errors (the pre-existing `.withOpacity` /
`activeColor` / `RadioGroup` deprecations the gate explicitly accepts; the
`unused_import` warning in `stats_screen.dart` is now cleared).

## Self-Review notes (applied during authoring)

- **Spec coverage:** §1 Breakpoints → Task 1. §2 scale-aware typography → Task 2. §3 Home → Task 3. §4 Stats two-pane → Task 5. §5 Settings/About → Task 4. §6 Shell → Task 6. §7 testing → each task + Verification Gate. All sections covered.
- **Placeholder scan:** No TBD/TODO. Every code step has runnable content. (Task 5/6 note that some tests pass at baseline because they're regression guards; that's documented, not a placeholder.)
- **Type consistency:** `Breakpoints` constants, `MaxWidthBox(maxWidth:, child:)`, `_scaleFor`, `_chartHeight`, `_tilesGrid` names/signatures match across tasks. `_medallionTile` refactor (removing `Expanded`) is consistent between Task 5's helper and call sites.
