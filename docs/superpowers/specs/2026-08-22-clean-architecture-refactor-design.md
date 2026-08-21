# Clean Architecture Refactor — Design

Date: 2026-08-22
Status: Approved (Option A: feature-first with thin layers)
Constraint: refactor only — zero behavior changes; all 114 tests keep passing;
`flutter analyze` stays at zero issues after every step.

## Goals

1. Replace the flat `screens/providers/services/models/utils/widgets` layout
   with a feature-first layered structure that makes dependencies point
   inward (UI → providers → domain; data implementations behind interfaces).
2. Break the dependency of providers on concrete platform services so unit
   tests implement small interfaces instead of subclassing concrete classes.
3. Decompose the two god-files (`settings_screen.dart` 785 lines,
   `home_screen.dart` 675 lines) into focused widgets and dialogs.

## Non-goals

- No state-management migration (ChangeNotifier stays).
- No storage engine change (SharedPreferences stays).
- No use-case classes / DTO layer (Option B rejected as ceremony at this size).
- No behavior, visual, or string changes.

## Target structure

```
lib/
├── main.dart                            # composition root only
├── core/                                # cross-cutting, no app logic
│   ├── theme/app_theme.dart
│   ├── theme/app_text_styles.dart
│   ├── l10n/app_localizations.dart      # S class + ar/en maps
│   ├── l10n/app_strings.dart            # notification/static Arabic strings
│   └── utils/breakpoints.dart           # numeric breakpoints only
├── domain/                              # pure Dart, no Flutter imports
│   ├── entities/adhkar_counter.dart     # gains rolledOver(now) method
│   ├── entities/app_settings.dart
│   ├── entities/dhikr_item.dart
│   ├── repositories/counters_repository.dart    # abstract
│   ├── repositories/settings_repository.dart    # abstract
│   ├── repositories/reminder_scheduler.dart     # abstract
│   └── services/stats_calculator.dart   # currentStreak, longestStreak, lastDaysCounts
├── data/                                # interface implementations
│   ├── counters_repository_impl.dart    # SharedPreferences-backed
│   ├── settings_repository_impl.dart
│   ├── backup_service.dart              # depends on both repositories
│   ├── notifications/notification_service.dart  # implements ReminderScheduler
│   └── widget/widget_sync_service.dart  # home_widget glue (+ background callback)
├── features/
│   ├── shell/decorative_app_shell.dart  # incl. ShellTabController
│   ├── counting/
│   │   ├── counters_provider.dart
│   │   └── screens/home_screen.dart             # skeleton ~150 lines
│   │   └── screens/widgets/counter_card.dart
│   │   └── screens/widgets/counter_switcher.dart
│   │   └── screens/widgets/count_button.dart    # face + tap wiring
│   │   └── screens/widgets/immersive_count_view.dart
│   │   └── screens/widgets/undo_reset_row.dart
│   │   └── screens/widgets/last_used_text.dart
│   │   └── screens/dialogs/reset_confirmation_dialog.dart
│   │   └── screens/dialogs/add_counter_dialog.dart
│   ├── library/
│   │   ├── adhkar_library.dart          # curated content
│   │   └── library_screen.dart
│   ├── stats/
│   │   ├── stats_screen.dart            # layout + period switcher
│   │   └── stats_chart.dart             # BarChart wrapper
│   └── settings/
│       ├── settings_provider.dart
│       ├── settings_screen.dart         # section list ~200 lines
│       └── dialogs/rename_dialog.dart
│       └── dialogs/delete_counter_dialog.dart
│       └── dialogs/daily_target_dialog.dart
│       └── dialogs/reminder_type_dialog.dart
│       └── dialogs/reminder_interval_dialog.dart
│       └── dialogs/daily_times_dialog.dart
│       └── dialogs/prayer_offset_dialog.dart
│       └── dialogs/prayer_location_dialog.dart
└── shared/widgets/
    ├── islamic_pattern.dart             # + khatamStarPath
    ├── mihrab_arch.dart
    ├── gold_divider.dart
    ├── celebration_burst.dart
    └── max_width_box.dart               # extracted from old breakpoints.dart
```

Deleted files after migration: `lib/utils/*` (content relocated),
`lib/services/storage_service.dart`, `lib/models/*`, `lib/providers/*`,
`lib/screens/*`, `lib/widgets/*` (all moved or decomposed).

## Interface contracts (domain/repositories)

```dart
abstract class CountersRepository {
  Future<List<AdhkarCounter>> getCounters();
  Future<void> saveCounters(List<AdhkarCounter> counters);
  Future<String?> getActiveCounterId();
  Future<void> saveActiveCounterId(String? id);
}

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<AppSettings> saveSettings(AppSettings settings); // returns saved copy
}

abstract class ReminderScheduler {
  Future<bool> requestPermission();
  Future<void> rescheduleAll(List<AdhkarCounter> counters, {AppSettings? settings});
  Future<void> showDailyTargetReached(String counterName);
}
```

Notes:
- `StorageService` disappears; its two halves become
  `CountersRepositoryImpl` / `SettingsRepositoryImpl` over SharedPreferences.
  Legacy-migration logic (`counter_data` key) stays inside
  `CountersRepositoryImpl`.
- `NotificationService implements ReminderScheduler`; init/lazy-gate logic is
  unchanged. Provider signature:
  `CountersProvider(CountersRepository, SettingsRepository, ReminderScheduler)` —
  it reads settings through `SettingsRepository` for `_reschedule()`.
- Test fakes shrink to `implements CountersRepository { … }` style — no more
  inheritance from concrete classes.

## Entity change

`AdhkarCounter.rolledOver(DateTime now)` absorbs `utils/rollover.dart`
(same-day → identical instance; previous day archived into history and reset).
`utils/rollover.dart` is deleted; provider and widget background callback call
the entity method.

## Decomposition rules

- Each new widget file owns exactly one visual block and receives data via
  constructor or scoped `Consumer`/`Selector` — no cross-imports between
  sibling widgets.
- Dialog files export a single `showXxx(BuildContext …)` function plus a
  private dialog widget; they obtain providers via `context.read` internally.
- `settings_screen.dart` keeps only section scaffolding and delegates every
  tile's action to a dialog file.
- `home_screen.dart` keeps animation controllers + immersive toggle state and
  composes the extracted widgets.

## Migration steps (each ends green: analyze 0 issues, tests pass)

1. **Pure moves** — create folders, `git mv` files per table above, update
   imports everywhere, extract `MaxWidthBox` out of breakpoints.
2. **Interfaces** — add domain contracts; split StorageService into two
   repository impls; rewire providers/main; convert test fakes to
   interface implementations; move rollover onto the entity.
3. **Decompose settings** — extract 8 dialog files; slim screen to sections.
4. **Decompose home** — extract 6 widgets + 2 dialogs; slim screen.
5. **Final sweep** — delete empty dirs, dead imports, run full suite +
   `flutter build apk --debug`.

## Testing strategy

- All existing tests survive with import-path updates only; no assertions
  change except fake construction (interface implementations instead of
  subclasses of concrete services).
- New tests are NOT added in this refactor (behavior unchanged; coverage
  already exercises the moved code through the same public API surface).
- Verification per step: `flutter analyze` (0 issues) + `flutter test`
  (114 passing); final step additionally builds the debug APK.

## Risks

- Import churn is large but mechanical; mitigated by running analyze after
  each step.
- Widget background callback (`widgetBackgroundCallback`) must keep its
  `@pragma('vm:entry-point')` and top-level placement during moves.
- RTL/localization keys are untouched; only file locations change.
