# Codebase Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce duplication and dead code across the salawat_app Flutter codebase without changing user-facing behavior (except completing the already-visible "reset total" option).

**Architecture:** Flutter app using `provider` for state, `shared_preferences` for storage, `flutter_local_notifications` for reminders. Changes are localized: a new `AppStrings` constants class, deduplication inside `NotificationService`/`AppTheme`/providers, and cleanup in `home_screen.dart` plus test helpers.

**Tech Stack:** Dart 3.12, Flutter, provider, shared_preferences, flutter_local_notifications, intl.

**Spec:** inline requirements from the review — the 7 refactors listed in the prior conversation.

## Global Constraints

- No change to user-visible Arabic strings (only centralization).
- `flutter analyze` and `flutter test` must stay clean.
- Follow existing `class Xxx { static ... }` convention in `lib/utils/`.
- `reset()` keeps its current signature semantics; a new optional named param is added (backward compatible).

---

### Task 1: Extract shared Arabic strings

**Files:**
- Create: `lib/utils/app_strings.dart`
- Modify: (none yet)

**Interfaces:**
- Produces: `class AppStrings` with static const fields used by later tasks.

- [ ] **Step 1: Add the constants class**

```dart
class AppStrings {
  AppStrings._();

  static const String appName = 'ورد الصلاة';
  static const String salawat = 'اللهم صلِّ على سيدنا محمد وعلى آل سيدنا محمد';
  static const String salawatHome = 'اللهم صلِّ على سيدنا محمد\nوعلى آل سيدنا محمد';
  static const String notificationTitle = 'صلِّ على النبي ﷺ';
  static const String notificationBody = salawat;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/utils/app_strings.dart
git commit -m "refactor: add AppStrings constants"
```

---

### Task 2: Deduplicate NotificationService

**Files:**
- Modify: `lib/services/notification_service.dart`

**Interfaces:**
- Consumes: `AppStrings.notificationTitle`, `AppStrings.notificationBody`.
- Produces: private `NotificationDetails _details()`.

- [ ] **Step 1: Extract details helper + use strings**

Add a private getter/method and replace the duplicated `androidDetails`/`iosDetails`/`details` blocks and the duplicated title/body literals in both `scheduleIntervalNotification` and `scheduleDailyNotifications` with `AppStrings` + the helper.

```dart
NotificationDetails _details() => const NotificationDetails(
      android: AndroidNotificationDetails(
        'salawat_reminder',
        'تذكير بالصلاة على النبي',
        channelDescription: 'تذكير يومي بالصلاة على النبي ﷺ',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/notification_service.dart
git commit -m "refactor: dedupe notification details and strings"
```

---

### Task 3: Parameterize AppTheme

**Files:**
- Modify: `lib/utils/app_theme.dart`

**Interfaces:**
- Produces: unchanged `lightTheme()` / `darkTheme()` static methods.

- [ ] **Step 1: Extract a shared `_build` helper**

Keep the public API identical; both methods delegate to one private builder parameterized by brightness + colors + body text color.

- [ ] **Step 2: Commit**

```bash
git add lib/utils/app_theme.dart
git commit -m "refactor: dedupe light/dark theme construction"
```

---

### Task 4: Consolidate SettingsProvider

**Files:**
- Modify: `lib/providers/settings_provider.dart`

**Interfaces:**
- Produces: private `Future<void> _apply(AppSettings next, {bool reschedule = false})`.
- Removes: unused `updateSettings`.

- [ ] **Step 1: Add a single `_apply` helper and delegate**

```dart
Future<void> _apply(AppSettings next, {bool reschedule = false}) async {
  _settings = next;
  await _storage.saveSettings(_settings);
  if (reschedule) await _updateNotifications();
  notifyListeners();
}
```

Each public toggle/setter becomes a one-liner, e.g.:

```dart
Future<void> toggleNotifications(bool enabled) =>
    _apply(_settings.copyWith(notificationsEnabled: enabled), reschedule: true);
```

`toggleNotifications`, `setReminderType`, `setReminderInterval`, `setDailyReminderTimes` pass `reschedule: true`; the others omit it.

- [ ] **Step 2: Commit**

```bash
git add lib/providers/settings_provider.dart
git commit -m "refactor: consolidate SettingsProvider update methods"
```

---

### Task 5: Consolidate CounterProvider reset (TDD)

**Files:**
- Modify: `lib/providers/counter_provider.dart`
- Test: `test/unit_test.dart` (or a new `test/counter_provider_test.dart`)

**Interfaces:**
- Produces: `Future<void> reset({bool includeTotal = false})`.
- Removes: `resetTotal()`.

- [ ] **Step 1: Write the failing test** (behavior: `reset(includeTotal: true)` zeroes both counts)

- [ ] **Step 2: Run to confirm it fails** (`resetTotal` no longer a thing / new param missing)

- [ ] **Step 3: Implement**

```dart
Future<void> reset({bool includeTotal = false}) async {
  _counterData = _counterData.copyWith(
    currentCount: 0,
    totalCount: includeTotal ? 0 : _counterData.totalCount,
    lastUsedAt: DateTime.now(),
    lastResetAt: DateTime.now(),
  );
  _lastCount = null;
  await _storage.saveCounterData(_counterData);
  notifyListeners();
}
```

- [ ] **Step 4: Run to confirm pass**

- [ ] **Step 5: Commit**

```bash
git add lib/providers/counter_provider.dart test/counter_provider_test.dart
git commit -m "refactor: unify reset/resetTotal behind includeTotal flag"
```

---

### Task 6: Home screen cleanup (dead state, reset-total wiring, intl date)

**Files:**
- Modify: `lib/screens/home_screen.dart`

**Interfaces:**
- Consumes: `AppStrings.appName`, `AppStrings.salawatHome`; `counter.reset(includeTotal: ...)`; `DateFormat` from `intl`.

- [ ] **Step 1: Remove `_showResetDialog` field and its assignment**

- [ ] **Step 2: Make the reset dialog track its checkbox via `StatefulBuilder`** and call `counter.reset(includeTotal: checked)` on confirm.

- [ ] **Step 3: Replace `_formatDateTime` with `DateFormat('dd/MM/yyyy HH:mm').format(...)`** and delete the private method.

- [ ] **Step 4: Use `AppStrings.appName` / `AppStrings.salawatHome`** in the UI.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home_screen.dart
git commit -m "refactor: wire reset-total checkbox, drop dead state, use intl + strings"
```

---

### Task 7: Deduplicate widget_test boilerplate

**Files:**
- Modify: `test/widget_test.dart`

**Interfaces:**
- Produces: `Future<void> pumpApp(WidgetTester tester)`.

- [ ] **Step 1: Extract a `pumpApp` helper** that inits services, builds the `MultiProvider`/`MyApp` tree, and calls `pumpAndSettle`.

- [ ] **Step 2: Replace the four duplicated blocks with `await pumpApp(tester);`**

- [ ] **Step 3: Commit**

```bash
git add test/widget_test.dart
git commit -m "test: extract pumpApp helper to remove duplication"
```

---

### Final verification

- [ ] Run `flutter analyze` (0 issues)
- [ ] Run `flutter test` (all pass)
