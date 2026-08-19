# Multiple Adhkar Counters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single salawat counter with multiple named adhkar counters (presets + custom), each with its own count, daily target, history, streak, and per-counter reminders.

**Architecture:** One `AdhkarCounter` model persisted as a JSON list in SharedPreferences (with migration of the legacy single counter). `CountersProvider` owns the counter list, active selection, daily rollover, and reminder scheduling; `SettingsProvider` shrinks to vibration + dark mode. `NotificationService` schedules per-counter reminders by id range.

**Tech Stack:** Dart 3.12 / Flutter, provider, shared_preferences, flutter_local_notifications, fl_chart, intl.

**Spec:** `docs/superpowers/specs/2026-08-19-multiple-adhkar-counters-design.md`

## Global Constraints

- Every counter is always "daily": `currentCount` rolls over at day change, `totalCount` is cumulative, `history` holds completed days.
- Reminder notification title = counter name, body = `حان وقت الذكر`.
- Target-reached notification fires when the target is met (not gated on `remindersEnabled`).
- Presets: salawat, tasbih, tahmid, takbir, istighfar. Custom counters append with generated ids.
- Keep the existing pure helpers in `lib/utils/stats.dart` unchanged.
- Verify with `flutter analyze` and `flutter test` (run on a machine with the Flutter SDK).

---

### Task 1: Data models

**Files:**
- Create: `lib/models/adhkar_counter.dart`
- Modify: `lib/models/app_settings.dart`
- Delete: `lib/models/counter_data.dart`

**Interfaces:**
- Produces: `enum ReminderType { interval, daily }` and `class AdhkarCounter` (fields: id, name, currentCount, totalCount, dailyTarget, history, lastUsedAt, lastResetAt, remindersEnabled, reminderType, reminderIntervalMinutes, dailyReminderTimes) with `copyWith`, `toJson`, `fromJson`.
- Produces: shrunk `AppSettings { vibrationEnabled, isDarkMode }` with `copyWith`/`toJson`/`fromJson` (unknown keys ignored).

- [ ] **Step 1:** Create `AdhkarCounter` with `ReminderType` and serialization; `fromJson` defaults every field (`reminderType: ReminderType.values[json['reminderType'] ?? 0]`, `history: _historyFromJson(...)`, etc.).
- [ ] **Step 2:** Shrink `AppSettings` to `vibrationEnabled` + `isDarkMode`.
- [ ] **Step 3:** Delete `counter_data.dart`.
- [ ] **Step 4:** Update imports across `lib/` and `test/` (this task leaves references broken until later tasks; complete Task 6 before running analysis).

### Task 2: Storage + migration

**Files:**
- Modify: `lib/services/storage_service.dart`

**Interfaces:**
- Produces: `Future<List<AdhkarCounter>> getCounters()`, `Future<void> saveCounters(List<AdhkarCounter>)`; keeps `getSettings()`/`saveSettings()`.
- Removes: `getCounterData()`, `saveCounterData()`.

- [ ] **Step 1:** Add key `adhkar_counters`, `getCounters`/`saveCounters` with JSON list encoding.
- [ ] **Step 2:** Implement migration in `getCounters()`: build 5 presets; if legacy `counter_data` exists, merge raw fields into `salawat`; merge legacy `app_settings` target/reminders into `salawat`; save to new key, remove `counter_data`.
- [ ] **Step 3:** Remove the counter methods.

### Task 3: CountersProvider

**Files:**
- Create: `lib/providers/counters_provider.dart`
- Delete: `lib/providers/counter_provider.dart`

**Interfaces:**
- Produces: `class CountersProvider with ChangeNotifier` with getters `counters`, `activeCounter`, `canUndo` and methods `load`, `setActive`, `increment`, `undo`, `reset({includeTotal})`, `addCounter`, `renameCounter`, `deleteCounter`, `setDailyTarget`, `setRemindersEnabled` (returns bool), `setReminderType`, `setReminderInterval`, `setDailyReminderTimes`, `notifyDailyTargetReached`, `rolloverIfNewDay`.

- [ ] **Step 1:** Implement list + active id + per-active undo state.
- [ ] **Step 2:** Implement `_rollover(counter)` (record history, reset current, keep total) and apply on `load()` (all counters) and `increment()` (active).
- [ ] **Step 3:** Implement CRUD + target + reminder setters; `setRemindersEnabled(true)` requests permission and returns `false` on denial.
- [ ] **Step 4:** Implement `notifyDailyTargetReached` and `_reschedule()`.

### Task 4: NotificationService

**Files:**
- Modify: `lib/services/notification_service.dart`

**Interfaces:**
- Produces: `Future<void> rescheduleAll(List<AdhkarCounter> counters)`, `Future<void> showDailyTargetReached(String counterName)`.
- Removes: `scheduleIntervalNotification`, `scheduleDailyNotifications`, `areNotificationsScheduled`.

- [ ] **Step 1:** Implement `rescheduleAll` (cancel all; schedule each enabled counter with `idBase = 100 + index * 100`, interval vs daily).
- [ ] **Step 2:** Update `showDailyTargetReached` to take a name and interpolate it in the body.

### Task 5: SettingsProvider shrink

**Files:**
- Modify: `lib/providers/settings_provider.dart`

- [ ] **Step 1:** Remove `toggleNotifications`, `setReminderType`, `setReminderInterval`, `setDailyReminderTimes`, `setDailyTarget`, `notifyDailyTargetReached`, `_updateNotifications`, and the `NotificationService` dependency. Keep `toggleVibration`, `toggleDarkMode`.

### Task 6: App wiring

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1:** Replace `CounterProvider` with `CountersProvider`; construct with `storageService` + `notificationService`; keep `SettingsProvider` (now storage-only). Load counters before `runApp`.

### Task 7: Home screen

**Files:**
- Modify: `lib/screens/home_screen.dart`

- [ ] **Step 1:** Add a horizontal counter-chip switcher (+ add button) above the counter card.
- [ ] **Step 2:** Bind count, target progress, "تم الهدف", streak, and total to `activeCounter`.
- [ ] **Step 3:** Increment/undo/reset/target-crossing act on the active counter.

### Task 8: Settings screen

**Files:**
- Modify: `lib/screens/settings_screen.dart`

- [ ] **Step 1:** Remove the global notifications section.
- [ ] **Step 2:** Add an "العداد الحالي" section: rename, daily target, reminders (switch + type/interval/times dialogs), delete.
- [ ] **Step 3:** Keep vibration + dark mode + about sections.

### Task 9: Stats screen

**Files:**
- Modify: `lib/screens/stats_screen.dart`

- [ ] **Step 1:** Read the active counter from `CountersProvider`; use its `history`/`currentCount`/`dailyTarget` for chart, totals, and streaks. Drop the `SettingsProvider` dependency.

### Task 10: Tests

**Files:**
- Create: `test/adhkar_counter_test.dart`, `test/counters_provider_test.dart`
- Delete: `test/counter_provider_test.dart`
- Modify: `test/unit_test.dart` (remove CounterData tests), `test/notification_service_test.dart`, `test/widget_test.dart`

- [ ] **Step 1:** Model serialization + defaults tests.
- [ ] **Step 2:** Provider tests: increment/rollover, add/rename/delete/setActive, undo, target-reached.
- [ ] **Step 3:** Storage migration test.
- [ ] **Step 4:** Notification `rescheduleAll` test (channel mock).
- [ ] **Step 5:** Widget tests: switcher, progress/streak, stats; update seeds to `adhkar_counters`/`app_settings`.

---

### Final verification

- [ ] `flutter pub get`
- [ ] `flutter analyze` (0 issues)
- [ ] `flutter test` (all pass)
