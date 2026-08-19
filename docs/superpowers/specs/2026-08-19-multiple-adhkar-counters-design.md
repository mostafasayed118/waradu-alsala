# Multiple Named Adhkar Counters — Design Spec

> **Status:** approved design → this spec. Next: `writing-plans` skill.

**Goal:** Replace the single salawat counter with multiple named adhkar counters, each with its own count, daily target, history, streak, and (optionally) reminders.

**Approach:** One cohesive `AdhkarCounter` model persisted as a JSON list in SharedPreferences, with automatic migration of the existing single counter. Global settings shrink to device-level preferences.

---

## 1. Data model

### `AdhkarCounter` (new: `lib/models/adhkar_counter.dart`)

```dart
enum ReminderType { interval, daily }

class AdhkarCounter {
  final String id;
  final String name;
  final int currentCount;   // today's count
  final int totalCount;     // all-time count
  final int dailyTarget;    // 0 = no target
  final Map<String, int> history; // 'yyyy-MM-dd' -> count
  final DateTime lastUsedAt;
  final DateTime? lastResetAt;
  final bool remindersEnabled;
  final ReminderType reminderType;
  final int reminderIntervalMinutes;
  final List<int> dailyReminderTimes;

  // copyWith (nullable fields, including id/name/history/reminder list),
  // toJson, fromJson (backward-compatible defaults).
}
```

- `ReminderType` moves here (removed from `AppSettings`).
- `history` uses the existing `dailyKey()` format from `lib/utils/stats.dart`.

### `AppSettings` (shrunk: `lib/models/app_settings.dart`)

Keeps only:
- `vibrationEnabled` (default `true`)
- `isDarkMode` (default `false`)

Removed fields: `notificationsEnabled`, `dailyCounter`, `reminderType`, `reminderIntervalMinutes`, `dailyReminderTimes`, `dailyTarget`. `fromJson` ignores unknown keys (backward compatible).

### Removed

- `lib/models/counter_data.dart` — `CounterData` is replaced by `AdhkarCounter`. Legacy data is read inline during migration (below), not via `CounterData`.

---

## 2. Presets

Pre-loaded on first run (and used as migration targets), ids stable:

| id        | name               |
|-----------|--------------------|
| `salawat` | الصلاة على النبي ﷺ |
| `tasbih`  | سبحان الله         |
| `tahmid`  | الحمد لله          |
| `takbir`  | الله أكبر          |
| `istighfar` | أستغفر الله      |

All presets start with zero counts, empty history, `dailyTarget: 0`, `remindersEnabled: false`, `reminderType: interval`, `reminderIntervalMinutes: 60`, empty `dailyReminderTimes`.

Custom counters get a generated id (e.g. `custom-<millisSinceEpoch>`), zeroed defaults, and are appended to the list.

---

## 3. Storage (`lib/services/storage_service.dart`)

Keys:
- `adhkar_counters` → JSON list of `AdhkarCounter`.
- `app_settings` → `AppSettings` (shrunk).
- Legacy `counter_data` → read once during migration, then removed.

Methods:
- `Future<List<AdhkarCounter>> getCounters()`
- `Future<void> saveCounters(List<AdhkarCounter>)`
- `Future<AppSettings> getSettings()` / `saveSettings()` (unchanged shape)

### Migration (`getCounters()`)

1. If `adhkar_counters` exists → decode and return.
2. Otherwise build the five presets.
3. If legacy `counter_data` exists, read its raw JSON map and merge into the `salawat` preset: `currentCount`, `totalCount`, `history`, `lastUsedAt`, `lastResetAt`.
4. Read legacy `app_settings`; merge into `salawat` preset: `dailyTarget`, `remindersEnabled` (from old `notificationsEnabled`), `reminderType`, `reminderIntervalMinutes`, `dailyReminderTimes`.
5. Save the list to `adhkar_counters`, remove `counter_data`, and return.

---

## 4. Providers

### `CountersProvider` (replaces `CounterProvider`: `lib/providers/counters_provider.dart`)

Owns: `List<AdhkarCounter> _counters`, `String _activeId`, `int? _lastCount` (undo, active counter only).

Getters: `counters`, `activeCounter`, `canUndo`.

- `load()` — read counters (migration), default active id to `salawat` (or first), roll over every counter, notify.
- `setActive(String id)` — switch active counter; clears undo state.
- `increment()` — roll over the active counter, then +1 (today and total), save, notify.
- `undo()` — restore active counter's previous count.
- `reset({bool includeTotal})` — reset active counter.
- `addCounter(String name)` — create, append, set active.
- `renameCounter(String id, String name)`.
- `deleteCounter(String id)` — remove; if it was active, activate the first remaining.
- `setDailyTarget(String id, int value)`.
- `setRemindersEnabled(String id, bool enabled)` — when enabling, request notification permission; if denied return `false` and don't enable; else save and reschedule.
- `setReminderType/setReminderInterval/setDailyReminderTimes(String id, …)` — save and reschedule.
- `notifyDailyTargetReached()` — fire a "target reached" notification personalized with the active counter name. Fires when the target is met (independent of `remindersEnabled`; it relies on OS permission, which is requested when reminders are first enabled).
- `_rollover(AdhkarCounter)` — if `lastUsedAt` is a previous day, record `history[lastUsedAt] = currentCount` (skip zero), reset `currentCount` to 0, keep `totalCount`.
- `_reschedule()` — `notificationService.rescheduleAll(_counters)`.

Daily rollover is **always on** (no `dailyCounter` flag): every counter is "today + total + history".

### `SettingsProvider` (shrunk)

Keeps only `toggleVibration` and `toggleDarkMode` (storage + notify). Removes all reminder/target/notification methods; the notification permission request moves to `CountersProvider.setRemindersEnabled`.

---

## 5. Notifications (`lib/services/notification_service.dart`)

Refactor to per-counter:

- `init()`, `requestPermission()` unchanged.
- `Future<void> rescheduleAll(List<AdhkarCounter> counters)` — cancel all, then for each counter with `remindersEnabled` schedule its reminders using a distinct id range (`idBase = 100 + index * 100`). Reminder title = counter name, body = `حان وقت الذكر`.
- `Future<void> showDailyTargetReached(String counterName)` — title `أكملت وردك اليومي`, body `لقد وصلت إلى هدفك اليومي: <name>`.
- Remove `scheduleIntervalNotification`, `scheduleDailyNotifications`, `areNotificationsScheduled`.

`AppStrings` additions: `reminderBody = 'حان وقت الذكر'`. `targetReachedTitle` stays; body is interpolated per counter.

---

## 6. Screens

### Home (`home_screen.dart`)

- A horizontal `ListView` of counter chips above the counter card, with a trailing "+" to add a counter. Tapping a chip calls `setActive`.
- Counter card shows the active counter: name, `currentCount`, target progress + "تم الهدف" badge, streak badge (🔥 N يوم متتالي), and total.
- Increment/undo/reset act on the active counter. Target-crossing fires `notifyDailyTargetReached()`.

### Settings (`settings_screen.dart`)

- Global sections unchanged: الاهتزاز (vibration), الوضع الداكن (dark mode), حول التطبيق.
- New "العداد الحالي" section for the active counter: rename, daily target (dialog), reminders (SwitchListTile + type/interval/times, same dialogs as today), delete (any counter, with a confirmation dialog).
- The global "تفعيل الإشعارات" switch is removed (replaced by per-counter reminders).

### Stats (`stats_screen.dart`)

- Unchanged UI, but reads the **active** counter (via `CountersProvider`) instead of the single counter. Still needs the active counter's `dailyTarget` for streak tiles (now available from the counter itself, so no `SettingsProvider` dependency).

---

## 7. Shared stats helpers (`lib/utils/stats.dart`)

Unchanged — `dailyKey`, `lastDaysCounts`, `currentStreak`, `longestStreak` already operate on `history` + `currentCount` + `dailyTarget`, so they work per counter as-is.

---

## 8. Tests

- `adhkar_counter_test.dart` — serialization round-trip + defaults (replaces `CounterData` tests).
- `stats_test.dart` — unchanged.
- `counters_provider_test.dart` — increment/rollover, add/rename/delete/setActive, undo, target-reached (replaces `counter_provider_test.dart`).
- `storage_service` migration test — legacy JSON → `salawat` counter carries over data.
- `notification_service_test.dart` — update for `rescheduleAll`.
- `widget_test.dart` — home switcher, target progress/streak, stats for active counter; update seeds to the new storage shape.

---

## 9. Out of scope

- Cross-counter aggregate stats (all counters in one chart).
- Cloud sync/backup.
- Per-counter vibration settings.
