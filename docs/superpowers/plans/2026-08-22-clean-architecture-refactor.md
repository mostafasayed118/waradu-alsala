# Clean Architecture Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure `lib/` into core/domain/data/features/shared layers with repository interfaces, decomposing the two god-files — with zero behavior change.

**Architecture:** Feature-first layering (approved Option A). Providers depend on `CountersRepository`/`SettingsRepository`/`ReminderScheduler` abstractions; SharedPreferences-backed implementations live in `data/`. Screens decompose into single-purpose widgets and dialog files.

**Tech Stack:** Flutter 3.48 / Dart 3.12, provider, shared_preferences, flutter_local_notifications 22, home_widget 0.9, adhan.

**Spec:** `docs/superpowers/specs/2026-08-22-clean-architecture-refactor-design.md`

## Global Constraints

- Zero behavior changes; no visual, string, or flow changes.
- After EVERY task: `flutter analyze` reports 0 issues AND `flutter test` passes with **114 tests**.
- This is a refactor: existing tests are the safety net. Do NOT write new feature tests. Where a test's construction site changes (fakes/ctor args), that is the only permitted test edit.
- All intra-`lib` imports become absolute `package:salawat_app/...` (Task 1). No new relative intra-lib imports anywhere.
- Keep `@pragma('vm:entry-point')` on `widgetBackgroundCallback` (top-level in `data/widget/widget_sync_service.dart`).
- Work on branch `refactor/clean-architecture` (create from `master` in Task 1, step 1).

## File structure (final state)

See spec tree. Supplements not in spec tree: `lib/features/about/about_screen.dart` (About screen had no listed home; it is a standalone pushed screen).

---

### Task 1: Layer moves + package-absolute imports

**Files:** every file in the move table below; new `lib/shared/widgets/max_width_box.dart`; `lib/core/utils/breakpoints.dart` (trimmed).

**Interfaces:**
- Consumes: nothing new.
- Produces: the exact file layout the later tasks edit; `MaxWidthBox` exported from `package:salawat_app/shared/widgets/max_width_box.dart`.

**Move table (git mv, content unchanged unless noted):**

| Old (lib/) | New (lib/) |
|---|---|
| `utils/app_theme.dart` | `core/theme/app_theme.dart` |
| `utils/app_text_styles.dart` | `core/theme/app_text_styles.dart` |
| `utils/app_localizations.dart` | `core/l10n/app_localizations.dart` |
| `utils/app_strings.dart` | `core/l10n/app_strings.dart` |
| `utils/breakpoints.dart` | `core/utils/breakpoints.dart` (Breakpoints only) |
| — (from old breakpoints.dart) | `shared/widgets/max_width_box.dart` (extracted `MaxWidthBox`) |
| `models/adhkar_counter.dart` | `domain/entities/adhkar_counter.dart` |
| `models/app_settings.dart` | `domain/entities/app_settings.dart` |
| `models/dhikr_item.dart` | `domain/entities/dhikr_item.dart` |
| `utils/stats.dart` | `domain/services/stats_calculator.dart` |
| `utils/rollover.dart` | `domain/services/rollover.dart` (interim; folded into entity in Task 2) |
| `utils/prayer_schedule.dart` | `data/notifications/prayer_schedule.dart` |
| `services/storage_service.dart` | `data/storage_service.dart` (interim; split in Task 2) |
| `services/notification_service.dart` | `data/notifications/notification_service.dart` |
| `services/widget_sync_service.dart` | `data/widget/widget_sync_service.dart` |
| `services/backup_service.dart` | `data/backup_service.dart` |
| `providers/counters_provider.dart` | `features/counting/counters_provider.dart` |
| `providers/settings_provider.dart` | `features/settings/settings_provider.dart` |
| `screens/home_screen.dart` | `features/counting/screens/home_screen.dart` |
| `screens/library_screen.dart` | `features/library/library_screen.dart` |
| `data/adhkar_library.dart` | `features/library/adhkar_library.dart` |
| `screens/stats_screen.dart` | `features/stats/stats_screen.dart` |
| `screens/settings_screen.dart` | `features/settings/settings_screen.dart` |
| `screens/about_screen.dart` | `features/about/about_screen.dart` |
| `widgets/decorative_app_shell.dart` | `features/shell/decorative_app_shell.dart` |
| `widgets/islamic_pattern.dart` | `shared/widgets/islamic_pattern.dart` |
| `widgets/mihrab_arch.dart` | `shared/widgets/mihrab_arch.dart` |
| `widgets/gold_divider.dart` | `shared/widgets/gold_divider.dart` |
| `widgets/celebration_burst.dart` | `shared/widgets/celebration_burst.dart` |

**Import rewrite rule (deterministic):** after the moves, replace every old import path with the new absolute one. Mapping of old import path → new:

- `package:salawat_app/utils/app_theme.dart` → `package:salawat_app/core/theme/app_theme.dart`
- `package:salawat_app/utils/app_text_styles.dart` → `package:salawat_app/core/theme/app_text_styles.dart`
- `package:salawat_app/utils/app_localizations.dart` → `package:salawat_app/core/l10n/app_localizations.dart`
- `package:salawat_app/utils/app_strings.dart` → `package:salawat_app/core/l10n/app_strings.dart`
- `package:salawat_app/utils/breakpoints.dart` → `package:salawat_app/core/utils/breakpoints.dart` **and**, in files that also use `MaxWidthBox`, add `package:salawat_app/shared/widgets/max_width_box.dart`
- `package:salawat_app/utils/stats.dart` → `package:salawat_app/domain/services/stats_calculator.dart`
- `package:salawat_app/utils/rollover.dart` → `package:salawat_app/domain/services/rollover.dart`
- `package:salawat_app/utils/prayer_schedule.dart` → `package:salawat_app/data/notifications/prayer_schedule.dart`
- `package:salawat_app/models/X.dart` → `package:salawat_app/domain/entities/X.dart`
- `package:salawat_app/services/storage_service.dart` → `package:salawat_app/data/storage_service.dart`
- `package:salawat_app/services/notification_service.dart` → `package:salawat_app/data/notifications/notification_service.dart`
- `package:salawat_app/services/widget_sync_service.dart` → `package:salawat_app/data/widget/widget_sync_service.dart`
- `package:salawat_app/services/backup_service.dart` → `package:salawat_app/data/backup_service.dart`
- `package:salawat_app/providers/counters_provider.dart` → `package:salawat_app/features/counting/counters_provider.dart`
- `package:salawat_app/providers/settings_provider.dart` → `package:salawat_app/features/settings/settings_provider.dart`
- `package:salawat_app/screens/home_screen.dart` → `package:salawat_app/features/counting/screens/home_screen.dart`
- `package:salawat_app/screens/library_screen.dart` → `package:salawat_app/features/library/library_screen.dart`
- `package:salawat_app/data/adhkar_library.dart` → `package:salawat_app/features/library/adhkar_library.dart`
- `package:salawat_app/screens/stats_screen.dart` → `package:salawat_app/features/stats/stats_screen.dart`
- `package:salawat_app/screens/settings_screen.dart` → `package:salawat_app/features/settings/settings_screen.dart`
- `package:salawat_app/screens/about_screen.dart` → `package:salawat_app/features/about/about_screen.dart`
- `package:salawat_app/widgets/decorative_app_shell.dart` → `package:salawat_app/features/shell/decorative_app_shell.dart`
- `package:salawat_app/widgets/islamic_pattern.dart` → `package:salawat_app/shared/widgets/islamic_pattern.dart`
- `package:salawat_app/widgets/mihrab_arch.dart` → `package:salawat_app/shared/widgets/mihrab_arch.dart`
- `package:salawat_app/widgets/gold_divider.dart` → `package:salawat_app/shared/widgets/gold_divider.dart`
- `package:salawat_app/widgets/celebration_burst.dart` → `package:salawat_app/shared/widgets/celebration_burst.dart`

Additionally, every **relative** intra-lib import (e.g. `import '../utils/app_theme.dart';` in moved files) is rewritten to the same absolute target using the table. `main.dart` imports update identically. `MaxWidthBox` new file content:

```dart
// lib/shared/widgets/max_width_box.dart
import 'package:flutter/material.dart';

import '../../core/utils/breakpoints.dart';

/// Caps and centers [child] at [maxWidth] on wide screens. No-op below.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({super.key, required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width <= maxWidth) return child;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
```

> Note: copy the CURRENT `MaxWidthBox` implementation from `core/utils/breakpoints.dart` verbatim if it differs from the sketch above (behavior must not change). The sketch shows only the expected public surface.

- [ ] **Step 1:** `git checkout -b refactor/clean-architecture`
- [ ] **Step 2:** Create folders: `core/theme core/l10n core/utils domain/entities domain/repositories domain/services data/notifications data/widget features/counting/screens features/library features/stats features/settings features/about features/shell shared/widgets`
- [ ] **Step 3:** `git mv` every file per the move table.
- [ ] **Step 4:** Extract `MaxWidthBox` into `shared/widgets/max_width_box.dart` (verbatim from current breakpoints.dart); trim `breakpoints.dart` to `Breakpoints`.
- [ ] **Step 5:** Rewrite imports per the rule (PowerShell: `Get-ChildItem lib,test -Recurse -Filter *.dart | ... -replace` per mapping row; then `flutter analyze` and fix any residual unresolved imports the same way until 0 issues).
- [ ] **Step 6:** `flutter analyze` → 0 issues.
- [ ] **Step 7:** `flutter test` → 114 passing.
- [ ] **Step 8:** Commit:
```bash
git add -A
git commit -m "ref: restructure lib into core/domain/data/features/shared layers"
```

---

### Task 2: Repository interfaces + provider rewiring + entity rollover

**Files:**
- Create: `lib/domain/repositories/counters_repository.dart`, `lib/domain/repositories/settings_repository.dart`, `lib/domain/repositories/reminder_scheduler.dart`, `lib/data/counters_repository_impl.dart`, `lib/data/settings_repository_impl.dart`
- Modify: `lib/domain/entities/adhkar_counter.dart`, `lib/features/counting/counters_provider.dart`, `lib/features/settings/settings_provider.dart`, `lib/data/notifications/notification_service.dart`, `lib/data/backup_service.dart`, `lib/data/widget/widget_sync_service.dart`, `lib/main.dart`, tests listed below
- Delete: `lib/data/storage_service.dart`, `lib/domain/services/rollover.dart`

**Interfaces:**
- Consumes: Task 1 layout.
- Produces (exact signatures used by later tasks and tests):

```dart
// lib/domain/repositories/counters_repository.dart
import '../entities/adhkar_counter.dart';

abstract class CountersRepository {
  Future<List<AdhkarCounter>> getCounters();
  Future<void> saveCounters(List<AdhkarCounter> counters);
  Future<String?> getActiveCounterId();
  Future<void> saveActiveCounterId(String? id);
}
```

```dart
// lib/domain/repositories/settings_repository.dart
import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<AppSettings> saveSettings(AppSettings settings);
}
```

```dart
// lib/domain/repositories/reminder_scheduler.dart
import '../entities/adhkar_counter.dart';
import '../entities/app_settings.dart';

abstract class ReminderScheduler {
  Future<bool> requestPermission();
  Future<void> rescheduleAll(
      List<AdhkarCounter> counters, {AppSettings? settings});
  Future<void> showDailyTargetReached(String counterName);
}
```

**Implementations** — move the corresponding halves of the current `data/storage_service.dart` verbatim into:

- `data/counters_repository_impl.dart` — `class CountersRepositoryImpl implements CountersRepository`. Holds `late final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();` and keys `_countersKey='adhkar_counters'`, `_legacyCounterKey='counter_data'`, `_activeCounterIdKey='active_counter_id'`, plus `_settingsKey='app_settings'` (read-only, needed by `_migrateLegacy`). Methods `getCounters` (incl. legacy migration + `_buildPresets`), `saveCounters`, `getActiveCounterId`, `saveActiveCounterId` are the current StorageService bodies with `_prefs` awaited per method. No `init()`.
- `data/settings_repository_impl.dart` — `class SettingsRepositoryImpl implements SettingsRepository`, key `_settingsKey='app_settings'`; `getSettings`/`saveSettings` from current StorageService; `saveSettings` returns the saved `settings`.

**Entity change** — add to `AdhkarCounter` (after `copyWith`), deleting `domain/services/rollover.dart`:

```dart
  /// Archives a previous day's count into history and resets the daily
  /// count when last used before [now]'s day; returns this otherwise.
  AdhkarCounter rolledOver(DateTime now) {
    final last = lastUsedAt;
    if (last.year == now.year &&
        last.month == now.month &&
        last.day == now.day) {
      return this;
    }
    final history = Map<String, int>.from(this.history);
    if (currentCount > 0) {
      history[dailyKey(last)] = currentCount;
    }
    return copyWith(
      currentCount: 0,
      history: history,
      lastUsedAt: now,
      lastResetAt: now,
    );
  }
```

`adhkar_counter.dart` gains `import 'package:salawat_app/domain/services/stats_calculator.dart';` (for `dailyKey`). Callers: `counters_provider` uses `active.rolledOver(now)` / `_counters[i].rolledOver(now)` (drop the `rollOverCounter` import); `widget_sync_service.dart` background callback uses `counters[index].rolledOver(now)`.

**Provider rewiring:**

```dart
// features/counting/counters_provider.dart (head)
class CountersProvider with ChangeNotifier {
  CountersProvider({
    required CountersRepository countersRepository,
    required SettingsRepository settingsRepository,
    required ReminderScheduler reminderScheduler,
  })  : _countersRepository = countersRepository,
        _settingsRepository = settingsRepository,
        _reminderScheduler = reminderScheduler;

  final CountersRepository _countersRepository;
  final SettingsRepository _settingsRepository;
  final ReminderScheduler _reminderScheduler;
```

Body substitutions: `_storage.getCounters()` → `_countersRepository.getCounters()`; `_storage.saveCounters(x)` → `_countersRepository.saveCounters(x)` (in `_flushPersist`, unawaited dispose flush); `_storage.getActiveCounterId()`/`saveActiveCounterId` → `_countersRepository.…`; `_storage.getSettings()` in `_reschedule` → `_settingsRepository.getSettings()`; `_notificationService.rescheduleAll(...)` unchanged (now via interface).

`SettingsProvider(SettingsRepository settingsRepository)` — same pattern.

`NotificationService implements ReminderScheduler` (add `implements` + import; no body changes).

`BackupService({required CountersRepository counters, required SettingsRepository settings})` with fields `_counters`/`_settings`; call sites in its methods swap `_storage.getX/saveX` to the matching repository.

`main.dart` composition root:

```dart
final countersRepository = CountersRepositoryImpl();
final settingsRepository = SettingsRepositoryImpl();
final notificationService = NotificationService();
// ... existing unawaited init + widget registration ...
runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => CountersProvider(
          countersRepository: countersRepository,
          settingsRepository: settingsRepository,
          reminderScheduler: notificationService,
        )..load(),
      ),
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(settingsRepository: settingsRepository)..load(),
      ),
      Provider<NotificationService>.value(value: notificationService),
      Provider<BackupService>.value(
        value: BackupService(
          counters: countersRepository,
          settings: settingsRepository,
        ),
      ),
    ],
    child: const MyApp(),
  ),
);
```

**Test edits (only construction sites):**

- `test/counters_provider_test.dart`: replace `_FakeStorageService` with

```dart
class _FakeCountersRepository implements CountersRepository {
  _FakeCountersRepository(this.stored);
  List<AdhkarCounter> stored;
  String? activeId;
  @override
  Future<List<AdhkarCounter>> getCounters() async => stored;
  @override
  Future<void> saveCounters(List<AdhkarCounter> counters) async => stored = counters;
  @override
  Future<String?> getActiveCounterId() async => activeId;
  @override
  Future<void> saveActiveCounterId(String? id) async => activeId = id;
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings settings = AppSettings();
  @override
  Future<AppSettings> getSettings() async => settings;
  @override
  Future<AppSettings> saveSettings(AppSettings s) async => settings = s;
}
```

and `_FakeNotificationService implements ReminderScheduler` (keep existing members). Every `CountersProvider(storage, notif)` becomes `CountersProvider(countersRepository: counters, settingsRepository: settings, reminderScheduler: notif)`. The `storage.activeId` assertions read `countersFake.activeId`.

- `test/settings_provider_test.dart`: `_FakeStorageService` → `_FakeSettingsRepository implements SettingsRepository` (keeps `stored` field); `SettingsProvider(storage)` → `SettingsProvider(settingsRepository: fake)`.
- `test/backup_service_test.dart` + `test/settings_backup_test.dart`: wherever `BackupService(storage: …)` / `StorageService()` appears, use `BackupService(counters: CountersRepositoryImpl(), settings: SettingsRepositoryImpl())` over `SharedPreferences.setMockInitialValues(...)` (drop `await storage.init()`); fakes subclassing StorageService become small `implements` fakes of the matching interface.
- `test/widget_test.dart`, `test/responsive_test.dart`, `test/library_screen_test.dart`: pumpApp helpers swap the `StorageService` block for `final countersRepository = CountersRepositoryImpl(); final settingsRepository = SettingsRepositoryImpl();` and pass named ctor args as in main.dart.
- `test/rollover_test.dart`: call `counter.rolledOver(now)` instead of `rollOverCounter(counter, now)`; expectations unchanged (`identical` still holds for same-day).

- [ ] **Step 1:** Create the three interface files (code above).
- [ ] **Step 2:** Create the two impl files (verbatim halves of storage_service).
- [ ] **Step 3:** Add `rolledOver` to the entity; delete `domain/services/rollover.dart`; update its two call sites.
- [ ] **Step 4:** Rewire providers, NotificationService, BackupService, main.dart.
- [ ] **Step 5:** Delete `data/storage_service.dart`.
- [ ] **Step 6:** Apply the listed test construction edits.
- [ ] **Step 7:** `flutter analyze` → 0 issues.
- [ ] **Step 8:** `flutter test` → 114 passing.
- [ ] **Step 9:** Commit:
```bash
git add -A
git commit -m "ref: providers depend on Counters/Settings repositories and ReminderScheduler"
```

---

### Task 3: Decompose settings screen

**Files:**
- Create: `lib/features/settings/dialogs/rename_dialog.dart`, `delete_counter_dialog.dart`, `daily_target_dialog.dart`, `reminder_type_dialog.dart`, `reminder_interval_dialog.dart`, `daily_times_dialog.dart`, `prayer_offset_dialog.dart`, `prayer_location_dialog.dart`
- Modify: `lib/features/settings/settings_screen.dart` (785 → ~230 lines)

**Interfaces:**
- Consumes: `S` (core/l10n), `CountersProvider`, `SettingsProvider`, `NotificationService`, `ReminderType`, `AppSettings`.
- Produces: top-level `showRenameDialog(BuildContext, CountersProvider)`, `showDeleteCounterDialog(BuildContext, CountersProvider)`, `showDailyTargetDialog(BuildContext, CountersProvider)`, `showReminderTypeDialog(BuildContext, CountersProvider)`, `showReminderIntervalDialog(BuildContext, CountersProvider)`, `showDailyTimesDialog(BuildContext, CountersProvider)`, `showPrayerOffsetDialog(BuildContext, CountersProvider)`, `showPrayerLocationDialog(BuildContext)`; plus `String reminderIntervalLabel(S s, int minutes)` exported from `reminder_interval_dialog.dart` (screen subtitle uses it); `DailyTargetDialog` public widget (was `_DailyTargetDialog`).

**Mechanics:** move each existing private method/class from `settings_screen.dart` into its file as a public top-level function (bodies verbatim), then delete from the screen. Each dialog file's imports: `package:flutter/material.dart`, `provider`, `S`, `CountersProvider` (and `SettingsProvider`+`NotificationService` for prayer-location), `ReminderType` where used. The screen keeps: build/sections, `_showExportSheet`, `_exportData`, `_showRestoreFlow`, `_buildSectionTitle`, `_medallionIcon`, `_prayerLocationSubtitle`, and calls the new `show*` functions; subtitle for interval uses `reminderIntervalLabel(s, counter.reminderIntervalMinutes)`.

- [ ] **Step 1:** Create the 8 dialog files by moving the matching `_show*`/dialog classes verbatim (rename to public names per Produces).
- [ ] **Step 2:** Slim `settings_screen.dart` to sections + backup flows; wire calls.
- [ ] **Step 3:** `flutter analyze` → 0 issues.
- [ ] **Step 4:** `flutter test` → 114 passing (settings_backup_test exercises these dialogs unchanged).
- [ ] **Step 5:** Commit:
```bash
git add -A
git commit -m "ref(settings): split screen into focused dialog files"
```

---

### Task 4: Decompose home screen + stats chart

**Files:**
- Create: `lib/features/counting/screens/widgets/counter_switcher.dart`, `counter_card.dart`, `count_button.dart`, `immersive_count_view.dart`, `undo_reset_row.dart`, `last_used_text.dart`; `lib/features/counting/screens/dialogs/reset_confirmation_dialog.dart`, `add_counter_dialog.dart`; `lib/features/stats/stats_chart.dart`
- Modify: `lib/features/counting/screens/home_screen.dart` (675 → ~180), `lib/features/stats/stats_screen.dart`

**Interfaces:**
- Produces:
  - `CounterSwitcher` — const ctor, internal `Consumer<CountersProvider>`.
  - `CounterCard({required Animation<double> popAnimation})`.
  - `CountButtonFace` — const, the gradient face only.
  - `ImmersiveCountView({required Animation<double> popAnimation, required Animation<double> scaleAnimation, required VoidCallback onTapDown, required VoidCallback onTapUp, required VoidCallback onTapCancel, required Future<void> Function() onCountTap, required VoidCallback onExit})` — owns GestureDetector + Consumer + close IconButton (tooltip `S.of(context).exitFullscreen`).
  - `UndoResetRow` — const; internal `Selector` on `canUndo`.
  - `LastUsedText` — const; internal `Selector` on `lastUsedAt`.
  - `showResetConfirmation(BuildContext, CountersProvider)`, `showAddCounterDialog(BuildContext, CountersProvider)` (moved from home_screen top-level).
  - `StatsChart({required List<int> counts})` — the current `_buildChart` body (Card + BarChart).

**Mechanics:** move each widget class verbatim from `_HomeScreenState`'s build/helpers into its file (public name, same body, imports per usage: `S`, `AppTextStyles`, `Breakpoints`, `MaxWidthBox`, `IslamicPattern`, `MihrabArch`, providers). `home_screen.dart` keeps: animation controllers, `_immersive`/`_celebrating` state, `_onCountTap`, SystemChrome enter/exit, gradient Container, celebration Stack wrapper, and composes the extracted widgets. `stats_screen.dart`: replace `_chartPane`/`_buildChart` with a `_chartPane` that stacks `IslamicPattern` + `SizedBox(height: h, child: StatsChart(counts: counts))`.

- [ ] **Step 1:** Create the 6 counting widgets + 2 dialogs (verbatim moves, public names).
- [ ] **Step 2:** Slim `home_screen.dart` to state + composition.
- [ ] **Step 3:** Extract `StatsChart`; update `stats_screen.dart`.
- [ ] **Step 4:** `flutter analyze` → 0 issues.
- [ ] **Step 5:** `flutter test` → 114 passing (widget_test covers immersive, celebration, dialogs).
- [ ] **Step 6:** Commit:
```bash
git add -A
git commit -m "ref(counting,stats): decompose home screen and extract stats chart"
```

---

### Task 5: Final sweep + build verification

**Files:** deletions only (`lib/models/`, `lib/providers/`, `lib/screens/`, `lib/services/`, `lib/utils/`, `lib/widgets/`, `lib/data/adhkar_library.dart` should already be empty after Tasks 1–4).

- [ ] **Step 1:** Delete empty directories: `Remove-Item lib\models,lib\providers,lib\screens,lib\services,lib\utils,lib\widgets -Recurse` (only if empty); confirm with `git status`.
- [ ] **Step 2:** `Get-ChildItem lib -Recurse -Filter *.dart | Select-String -Pattern "import '\.\."` → must output nothing (no relative intra-lib imports).
- [ ] **Step 3:** `flutter analyze` → 0 issues.
- [ ] **Step 4:** `flutter test` → 114 passing.
- [ ] **Step 5:** `flutter build apk --debug` → successful APK (validates native widget + plugin wiring survived the moves).
- [ ] **Step 6:** Commit (if any changes) and merge:
```bash
git add -A
git commit -m "chore: remove empty legacy directories" 
git checkout master
git merge --no-ff refactor/clean-architecture -m "merge: clean architecture refactor (feature-first layers)"
```

---

## Self-review notes

- Spec coverage: structure tree (Task 1), interface contracts (Task 2), entity `rolledOver` (Task 2), settings decomposition incl. 8 dialogs (Task 3), home decomposition + stats chart (Task 4), deletions + build gate (Task 5). Spec gap found & handled: `about_screen.dart` placement added (`features/about/`), documented above.
- Type consistency: `CountersProvider` named ctor params, `SettingsRepository.saveSettings` returning `AppSettings`, `ReminderScheduler.rescheduleAll` named `settings` param — consistent across Tasks 2–4 and tests.
- No placeholders: all new code is shown verbatim; mechanical steps are exact move/rewrite tables.
