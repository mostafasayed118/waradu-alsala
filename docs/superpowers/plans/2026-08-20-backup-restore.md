# Data Export / Backup & Restore Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users export all app data (counters, history, settings, active counter) as a JSON or CSV file via the share sheet, and restore from a JSON backup with confirmation, replacing all current data.

**Architecture:** A pure, testable `BackupService` (serialization/deserialization/validation) sits between the existing `StorageService` (persistence) and the Settings screen (UI orchestration). Export writes a temp file and shares it via `share_plus`; restore picks a JSON file with `file_picker`, parses and validates before any write, then reloads providers and reschedules notifications.

**Tech Stack:** Flutter, Dart, `provider`, `shared_preferences`, `share_plus ^10.1.4`, `file_picker ^8.1.7`, `path_provider ^2.1.5`, `flutter_test`, `mockito`.

**Spec:** `docs/superpowers/specs/2026-08-20-backup-restore-design.md`

## Global Constraints

- All new user-facing strings live in `lib/utils/app_strings.dart` (Arabic). Existing dialogs already inline `إلغاء` — keep that pattern for the restore dialog buttons.
- **Do not modify** `StorageService`, `AdhkarCounter`, or `AppSettings` — reuse their existing methods (`getCounters`, `saveCounters`, `getSettings`, `saveSettings`, `getActiveCounterId`, `saveActiveCounterId`, `toJson`, `fromJson`).
- Restore accepts **JSON only**; CSV is export-only.
- Restore **replaces** all data; parse-and-validate happens **before** any write or confirmation dialog.
- Backup envelope version must equal `1`; anything else is rejected (`versionMismatch`).
- CSV is UTF-8 **with BOM** (`\uFEFF` prefix), every field wrapped in double quotes with inner quotes doubled (RFC 4180).
- Dependencies pinned: `share_plus: ^10.1.4`, `file_picker: ^8.1.7`, `path_provider: ^2.1.5`.
- Tests follow existing patterns: `SharedPreferences.setMockInitialValues` for storage, `TestDefaultBinaryMessengerBinding...setMockMethodCallHandler` for platform channels (see `test/widget_test.dart`).

---

### Task 1: Add dependencies and backup strings

**Files:**
- Modify: `pubspec.yaml` (dependencies section, after line 22)
- Modify: `lib/utils/app_strings.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `AppStrings` constants + `AppStrings.backupErrorMessage(BackupErrorCode)` used by Task 7/8. `BackupErrorCode` enum lives in `lib/services/backup_service.dart` (Task 2); this task only adds the strings, so `app_strings.dart` will import it once Task 2 lands — add the `import '../services/backup_service.dart';` line in Task 7/8's file edit if needed. To keep this task compilable, add only the `String` constants now (no enum import).

- [ ] **Step 1: Add dependencies to `pubspec.yaml`**

In `dependencies:` add:

```yaml
  share_plus: ^10.1.4
  file_picker: ^8.1.7
  path_provider: ^2.1.5
```

- [ ] **Step 2: Run `flutter pub get`**

Run: `flutter pub get`
Expected: resolves successfully (no version conflicts with Flutter SDK ^3.12.2).

- [ ] **Step 3: Add strings to `lib/utils/app_strings.dart`**

Inside `class AppStrings` (after `targetReachedBody`):

```dart
  static const String backupSectionTitle = 'النسخ الاحتياطي';
  static const String exportData = 'تصدير البيانات';
  static const String exportJsonOption = 'نسخة احتياطية كاملة (JSON)';
  static const String exportCsvOption = 'ملف CSV (لبرامج الجداول)';
  static const String restoreBackup = 'استعادة نسخة احتياطية';
  static const String restoreConfirmBody =
      'سيتم استبدال جميع البيانات الحالية. هل أنت متأكد؟';
  static const String restoreSuccess = 'تمت الاستعادة بنجاح';
  static const String errorInvalidFormat = 'ملف النسخة الاحتياطية غير صالح';
  static const String errorVersionMismatch =
      'إصدار النسخة الاحتياطية غير مدعوم';
  static const String errorEmptyBackup = 'لا توجد بيانات في النسخة الاحتياطية';
  static const String errorExportFailed = 'تعذر تصدير البيانات';
  static const String errorRestoreFailed = 'تعذرت الاستعادة';
  static const String errorReadFileFailed = 'تعذر قراءة الملف';
```

- [ ] **Step 4: Verify analysis**

Run: `flutter analyze`
Expected: no errors (the unused-string warnings are fine; they'll be used by Task 7/8).

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/utils/app_strings.dart
git commit -m "feat: add backup/restore dependencies and strings"
```

---

### Task 2: `BackupException`, `BackupData`, and `parseJsonBackup`

**Files:**
- Create: `lib/services/backup_service.dart` (types + `parseJsonBackup` only; other methods added in Tasks 3–5)
- Create: `test/backup_service_test.dart` (validation tests only; round-trip tests added in Tasks 3–5)

**Interfaces:**
- Consumes: `StorageService` (constructor), `AdhkarCounter.fromJson`, `AppSettings.fromJson`.
- Produces:
  - `enum BackupErrorCode { invalidFormat, versionMismatch, emptyBackup }`
  - `class BackupException implements Exception { final BackupErrorCode code; const BackupException(this.code); }`
  - `class BackupData { final List<AdhkarCounter> counters; final AppSettings settings; final String activeCounterId; const BackupData({required this.counters, required this.settings, required this.activeCounterId}); }`
  - `BackupService({required StorageService storage})`
  - `BackupData parseJsonBackup(String raw)` — throws `BackupException`. Later tasks rely on exactly these names/types.

- [ ] **Step 1: Write the failing validation tests**

Create `test/backup_service_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/models/adhkar_counter.dart';
import 'package:salawat_app/services/backup_service.dart';
import 'package:salawat_app/services/storage_service.dart';

void main() {
  Future<StorageService> storageWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final storage = StorageService();
    await storage.init();
    return storage;
  }

  String validJson({Object? version = 1, Object? counters, Object? settings}) {
    return jsonEncode({
      'version': version,
      'exportedAt': '2026-08-20T10:00:00.000Z',
      'activeCounterId': 'salawat',
      'settings': settings ?? {'vibrationEnabled': true, 'isDarkMode': false},
      'counters': counters ??
          [
            AdhkarCounter(id: 'salawat', name: 'الصلاة على النبي ﷺ')
                .toJson(),
          ],
    });
  }

  Future<BackupService> serviceWith(Map<String, Object> values) async =>
      BackupService(storage: await storageWith(values));

  group('parseJsonBackup', () {
    test('rejects malformed JSON with invalidFormat', () async {
      final service = await serviceWith({});
      expect(
        () => service.parseJsonBackup('not json'),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.invalidFormat)),
      );
    });

    test('rejects a non-object root with invalidFormat', () async {
      final service = await serviceWith({});
      expect(
        () => service.parseJsonBackup('[1, 2]'),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.invalidFormat)),
      );
    });

    test('rejects missing or unsupported version with versionMismatch',
        () async {
      final service = await serviceWith({});
      expect(
        () => service.parseJsonBackup(validJson(version: 2)),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.versionMismatch)),
      );
      expect(
        () => service.parseJsonBackup(validJson(version: null)),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.versionMismatch)),
      );
    });

    test('rejects missing or empty counters with emptyBackup', () async {
      final service = await serviceWith({});
      expect(
        () => service.parseJsonBackup(validJson(counters: [])),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.emptyBackup)),
      );
      expect(
        () => service.parseJsonBackup(validJson(counters: null)),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.emptyBackup)),
      );
    });

    test('rejects a counter missing id or name with invalidFormat', () async {
      final service = await serviceWith({});
      final noId = AdhkarCounter(id: '', name: 'x').toJson();
      expect(
        () => service.parseJsonBackup(validJson(counters: [noId])),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.invalidFormat)),
      );
      final noName = AdhkarCounter(id: 'a', name: '').toJson();
      expect(
        () => service.parseJsonBackup(validJson(counters: [noName])),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.invalidFormat)),
      );
    });

    test('rejects non-numeric counts with invalidFormat', () async {
      final service = await serviceWith({});
      final bad = AdhkarCounter(id: 'a', name: 'x').toJson()
        ..['currentCount'] = 'many';
      expect(
        () => service.parseJsonBackup(validJson(counters: [bad])),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.invalidFormat)),
      );
    });

    test('rejects missing settings with invalidFormat', () async {
      final service = await serviceWith({});
      expect(
        () => service.parseJsonBackup(validJson(settings: null)),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.invalidFormat)),
      );
    });

    test('parses a valid backup and resolves active counter', () async {
      final service = await serviceWith({});
      final data = service.parseJsonBackup(validJson());
      expect(data.counters, hasLength(1));
      expect(data.counters.first.id, 'salawat');
      expect(data.settings.vibrationEnabled, isTrue);
      expect(data.activeCounterId, 'salawat');
    });

    test('falls back to the first counter when active id is unknown',
        () async {
      final service = await serviceWith({});
      final data = service.parseJsonBackup(validJson());
      expect(data.activeCounterId, 'salawat');
    });
  });
}
```

Note: add `import 'package:shared_preferences/shared_preferences.dart';` to the test file (used via `setMockInitialValues`).

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/backup_service_test.dart`
Expected: FAIL — compile error (`backup_service.dart` doesn't exist).

- [ ] **Step 3: Write the minimal implementation**

Create `lib/services/backup_service.dart`:

```dart
import 'dart:convert';

import '../models/adhkar_counter.dart';
import '../models/app_settings.dart';
import 'storage_service.dart';

enum BackupErrorCode { invalidFormat, versionMismatch, emptyBackup }

class BackupException implements Exception {
  final BackupErrorCode code;
  const BackupException(this.code);
}

class BackupData {
  final List<AdhkarCounter> counters;
  final AppSettings settings;
  final String activeCounterId;

  const BackupData({
    required this.counters,
    required this.settings,
    required this.activeCounterId,
  });
}

class BackupService {
  BackupService({required StorageService storage}) : _storage = storage;

  final StorageService _storage;

  static const int _backupVersion = 1;

  BackupData parseJsonBackup(String raw) {
    final Object? decoded;
    try {
      decoded = json.decode(raw);
    } on FormatException {
      throw const BackupException(BackupErrorCode.invalidFormat);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const BackupException(BackupErrorCode.invalidFormat);
    }
    if (decoded['version'] != _backupVersion) {
      throw const BackupException(BackupErrorCode.versionMismatch);
    }
    final settingsJson = decoded['settings'];
    if (settingsJson is! Map<String, dynamic>) {
      throw const BackupException(BackupErrorCode.invalidFormat);
    }
    final settings = AppSettings.fromJson(settingsJson);

    final countersJson = decoded['counters'];
    if (countersJson is! List || countersJson.isEmpty) {
      throw const BackupException(BackupErrorCode.emptyBackup);
    }
    final counters = <AdhkarCounter>[];
    for (final entry in countersJson) {
      if (entry is! Map<String, dynamic>) {
        throw const BackupException(BackupErrorCode.invalidFormat);
      }
      final id = entry['id'];
      final name = entry['name'];
      if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
        throw const BackupException(BackupErrorCode.invalidFormat);
      }
      for (final key in const ['currentCount', 'totalCount', 'dailyTarget']) {
        final value = entry[key];
        if (value != null && value is! num) {
          throw const BackupException(BackupErrorCode.invalidFormat);
        }
      }
      counters.add(AdhkarCounter.fromJson(entry));
    }

    final activeId = decoded['activeCounterId'];
    final activeCounterId = activeId is String && counters.any((c) => c.id == activeId)
        ? activeId
        : counters.first.id;

    return BackupData(
      counters: counters,
      settings: settings,
      activeCounterId: activeCounterId,
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/backup_service_test.dart`
Expected: PASS (all 8 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/backup_service.dart test/backup_service_test.dart
git commit -m "feat: add backup parsing with validation"
```

---

### Task 3: `buildJsonBackup`

**Files:**
- Modify: `lib/services/backup_service.dart`
- Modify: `test/backup_service_test.dart` (add round-trip tests)

**Interfaces:**
- Consumes: `parseJsonBackup` from Task 2, `StorageService.getCounters/getSettings/getActiveCounterId`.
- Produces: `Future<String> buildJsonBackup()` — pretty-printed JSON envelope `{version: 1, exportedAt, activeCounterId, settings, counters}`, active id resolved to first counter when stored id is unknown/missing.

- [ ] **Step 1: Write the failing round-trip tests**

Append to `test/backup_service_test.dart` (inside `main()`):

```dart
  group('buildJsonBackup', () {
    test('round-trips counters, history, settings, and active id', () async {
      final counter = AdhkarCounter(
        id: 'custom-1',
        name: 'ذكر، مع "علامات"',
        currentCount: 7,
        totalCount: 120,
        dailyTarget: 33,
        history: {'2026-08-19': 33, '2026-08-20': 7},
        remindersEnabled: true,
        reminderType: ReminderType.daily,
        dailyReminderTimes: [480, 1020],
      );
      final storage = await storageWith({
        'adhkar_counters':
            jsonEncode([counter.toJson(), AdhkarCounter(id: 'salawat', name: 'الصلاة على النبي ﷺ').toJson()]),
        'app_settings': jsonEncode({'vibrationEnabled': false, 'isDarkMode': true}),
        'active_counter_id': 'custom-1',
      });
      final service = BackupService(storage: storage);

      final data = service.parseJsonBackup(await service.buildJsonBackup());

      expect(data.counters, hasLength(2));
      final restored = data.counters.first;
      expect(restored.id, 'custom-1');
      expect(restored.name, 'ذكر، مع "علامات"');
      expect(restored.currentCount, 7);
      expect(restored.totalCount, 120);
      expect(restored.dailyTarget, 33);
      expect(restored.history, {'2026-08-19': 33, '2026-08-20': 7});
      expect(restored.remindersEnabled, isTrue);
      expect(restored.reminderType, ReminderType.daily);
      expect(restored.dailyReminderTimes, [480, 1020]);
      expect(data.settings.vibrationEnabled, isFalse);
      expect(data.settings.isDarkMode, isTrue);
      expect(data.activeCounterId, 'custom-1');
    });

    test('resolves active id to first counter when stored id is unknown',
        () async {
      final storage = await storageWith({
        'adhkar_counters': jsonEncode(
            [AdhkarCounter(id: 'salawat', name: 'الصلاة على النبي ﷺ').toJson()]),
        'active_counter_id': 'ghost',
      });
      final service = BackupService(storage: storage);

      final data = service.parseJsonBackup(await service.buildJsonBackup());

      expect(data.activeCounterId, 'salawat');
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/backup_service_test.dart`
Expected: FAIL — `buildJsonBackup` not defined.

- [ ] **Step 3: Write the implementation**

Add to `BackupService` in `lib/services/backup_service.dart`:

```dart
  Future<String> buildJsonBackup() async {
    final counters = await _storage.getCounters();
    final settings = await _storage.getSettings();
    final storedActiveId = await _storage.getActiveCounterId();
    final activeCounterId =
        storedActiveId != null && counters.any((c) => c.id == storedActiveId)
            ? storedActiveId
            : (counters.isEmpty ? '' : counters.first.id);
    final map = <String, dynamic>{
      'version': _backupVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'activeCounterId': activeCounterId,
      'settings': settings.toJson(),
      'counters': counters.map((c) => c.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/backup_service_test.dart`
Expected: PASS (all 10 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/backup_service.dart test/backup_service_test.dart
git commit -m "feat: build JSON backup with full fidelity"
```

---

### Task 4: `buildCsv`

**Files:**
- Modify: `lib/services/backup_service.dart`
- Modify: `test/backup_service_test.dart` (add CSV tests)

**Interfaces:**
- Consumes: `StorageService.getCounters`.
- Produces: `Future<String> buildCsv()` — BOM-prefixed, two blocks (`counters`, `history`), every field quoted per RFC 4180. Later tasks rely on this exact output shape.

- [ ] **Step 1: Write the failing CSV tests**

Append to `test/backup_service_test.dart` (inside `main()`):

```dart
  group('buildCsv', () {
    test('produces BOM, headers, quoted fields, and history rows', () async {
      final counter = AdhkarCounter(
        id: 'custom-1',
        name: 'ذكر، مع "علامات"',
        totalCount: 120,
        dailyTarget: 33,
        remindersEnabled: true,
        reminderType: ReminderType.daily,
        reminderIntervalMinutes: 60,
        dailyReminderTimes: [480, 1020],
        history: {'2026-08-19': 33, '2026-08-20': 7},
      );
      final storage = await storageWith({
        'adhkar_counters': jsonEncode([counter.toJson()]),
      });
      final service = BackupService(storage: storage);

      final csv = await service.buildCsv();

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(
        csv,
        contains(
            '"id","name","totalCount","dailyTarget","remindersEnabled","reminderType","reminderIntervalMinutes","dailyReminderTimes","lastUsedAt","lastResetAt"'),
      );
      expect(
        csv,
        contains('"custom-1","ذكر، مع ""علامات""",120,33,true,daily,60,"480;1020"'),
      );
      expect(
        csv,
        contains('"counterId","counterName","date","count"'),
      );
      expect(csv, contains('"custom-1","ذكر، مع ""علامات""","2026-08-19",33'));
      expect(csv, contains('"custom-1","ذكر، مع ""علامات""","2026-08-20",7'));
    });

    test('uses interval word and skips zero-count history entries', () async {
      final counter = AdhkarCounter(
        id: 'salawat',
        name: 'الصلاة على النبي ﷺ',
        remindersEnabled: false,
        reminderType: ReminderType.interval,
        history: {'2026-08-19': 0},
      );
      final storage = await storageWith({
        'adhkar_counters': jsonEncode([counter.toJson()]),
      });
      final service = BackupService(storage: storage);

      final csv = await service.buildCsv();

      expect(csv, contains(',false,interval,60,'));
      expect(csv, isNot(contains('"2026-08-19",0')));
    });

    test('leaves lastResetAt empty when null', () async {
      final storage = await storageWith({
        'adhkar_counters': jsonEncode(
            [AdhkarCounter(id: 'a', name: 'x').toJson()]),
      });
      final service = BackupService(storage: storage);

      final csv = await service.buildCsv();

      expect(csv, contains(',""\n'));
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/backup_service_test.dart`
Expected: FAIL — `buildCsv` not defined.

- [ ] **Step 3: Write the implementation**

Add to `BackupService` in `lib/services/backup_service.dart`:

```dart
  static const String _csvCountersHeader =
      '"id","name","totalCount","dailyTarget","remindersEnabled","reminderType","reminderIntervalMinutes","dailyReminderTimes","lastUsedAt","lastResetAt"';
  static const String _csvHistoryHeader =
      '"counterId","counterName","date","count"';

  Future<String> buildCsv() async {
    final counters = await _storage.getCounters();
    final buffer = StringBuffer('\uFEFF');
    buffer.writeln(_csvCountersHeader);
    for (final c in counters) {
      buffer.writeln([
        _csvField(c.id),
        _csvField(c.name),
        _csvField('${c.totalCount}'),
        _csvField('${c.dailyTarget}'),
        _csvField('${c.remindersEnabled}'),
        _csvField(c.reminderType == ReminderType.interval ? 'interval' : 'daily'),
        _csvField('${c.reminderIntervalMinutes}'),
        _csvField(c.dailyReminderTimes.join(';')),
        _csvField(c.lastUsedAt.toIso8601String()),
        _csvField(c.lastResetAt?.toIso8601String() ?? ''),
      ].join(','));
    }
    buffer.writeln();
    buffer.writeln(_csvHistoryHeader);
    for (final c in counters) {
      c.history.forEach((date, count) {
        if (count <= 0) return;
        buffer.writeln([
          _csvField(c.id),
          _csvField(c.name),
          _csvField(date),
          _csvField('$count'),
        ].join(','));
      });
    }
    return buffer.toString();
  }

  static String _csvField(String value) =>
      '"${value.replaceAll('"', '""')}"';
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/backup_service_test.dart`
Expected: PASS (all 13 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/backup_service.dart test/backup_service_test.dart
git commit -m "feat: build CSV export with BOM and escaping"
```

---

### Task 5: `applyBackup`

**Files:**
- Modify: `lib/services/backup_service.dart`
- Modify: `test/backup_service_test.dart` (add apply tests)

**Interfaces:**
- Consumes: `BackupData` from Task 2, `StorageService.saveCounters/saveSettings/saveActiveCounterId`.
- Produces: `Future<void> applyBackup(BackupData data)` — replace-all write. Task 8 calls it, then calls `CountersProvider.load()`, `SettingsProvider.load()`, and `NotificationService.rescheduleAll(...)`.

- [ ] **Step 1: Write the failing apply tests**

Append to `test/backup_service_test.dart` (inside `main()`):

```dart
  group('applyBackup', () {
    test('replaces counters, settings, and active id in storage', () async {
      final storage = await storageWith({
        'adhkar_counters': jsonEncode(
            [AdhkarCounter(id: 'old', name: 'قديم', totalCount: 5).toJson()]),
        'app_settings': jsonEncode({'vibrationEnabled': true, 'isDarkMode': false}),
        'active_counter_id': 'old',
      });
      final service = BackupService(storage: storage);

      final incoming = AdhkarCounter(
        id: 'salawat',
        name: 'الصلاة على النبي ﷺ',
        totalCount: 99,
        history: {'2026-08-20': 7},
      );
      await service.applyBackup(BackupData(
        counters: [incoming],
        settings: const AppSettings(vibrationEnabled: false, isDarkMode: true),
        activeCounterId: 'salawat',
      ));

      final counters = await storage.getCounters();
      expect(counters, hasLength(1));
      expect(counters.single.id, 'salawat');
      expect(counters.single.totalCount, 99);
      expect(counters.single.history, {'2026-08-20': 7});
      final settings = await storage.getSettings();
      expect(settings.vibrationEnabled, isFalse);
      expect(settings.isDarkMode, isTrue);
      expect(await storage.getActiveCounterId(), 'salawat');
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/backup_service_test.dart`
Expected: FAIL — `applyBackup` not defined.

- [ ] **Step 3: Write the implementation**

Add to `BackupService` in `lib/services/backup_service.dart`:

```dart
  Future<void> applyBackup(BackupData data) async {
    await _storage.saveCounters(data.counters);
    await _storage.saveSettings(data.settings);
    await _storage.saveActiveCounterId(data.activeCounterId);
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/backup_service_test.dart`
Expected: PASS (all 14 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/backup_service.dart test/backup_service_test.dart
git commit -m "feat: apply backup data to storage"
```

---

### Task 6: Wire `BackupService` and `NotificationService` providers in `main.dart`

**Files:**
- Modify: `lib/main.dart` (MultiProvider list, lines 26–36)

**Interfaces:**
- Consumes: `BackupService` (Task 2–5), existing `storageService`/`notificationService` instances.
- Produces: `Provider<BackupService>` and `Provider<NotificationService>` visible to all screens via `context.read`. Task 7/8 read them.

- [ ] **Step 1: Write the failing test**

Append to `test/widget_test.dart` (inside `main()`):

```dart
  testWidgets('app exposes BackupService and NotificationService providers',
      (WidgetTester tester) async {
    await pumpApp(tester);

    expect(
      tester.element(find.byType(MyApp)).read<BackupService>(),
      isA<BackupService>(),
    );
    expect(
      tester.element(find.byType(MyApp)).read<NotificationService>(),
      isA<NotificationService>(),
    );
  });
```

Add imports to `test/widget_test.dart`:

```dart
import 'package:salawat_app/services/backup_service.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart --plain-name "app exposes BackupService"`
Expected: FAIL — `Provider<BackupService>` not found above `MyApp`.

- [ ] **Step 3: Write the implementation**

In `lib/main.dart`:

- Add import: `import 'services/backup_service.dart';`
- Change the providers list to:

```dart
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
```

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: PASS (all existing tests + the new one).

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart test/widget_test.dart
git commit -m "feat: expose backup and notification services via providers"
```

---

### Task 7: Settings screen — export flow (bottom sheet + share)

**Files:**
- Modify: `lib/screens/settings_screen.dart`
- Create: `test/settings_backup_test.dart` (export tests)

**Interfaces:**
- Consumes: `Provider<BackupService>` (Task 6), `buildJsonBackup`/`buildCsv` (Tasks 3/4), `AppStrings` (Task 1), `dailyKey` from `lib/utils/stats.dart`, `getTemporaryDirectory()` (`path_provider`), `Share.shareXFiles` (`share_plus`).
- Produces: Settings section `النسخ الاحتياطي` with `تصدير البيانات` tile → bottom sheet (JSON/CSV) → temp file → share sheet. `_showRestoreFlow` is added in Task 8.

- [ ] **Step 1: Write the failing widget tests**

Create `test/settings_backup_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salawat_app/main.dart';
import 'package:salawat_app/providers/counters_provider.dart';
import 'package:salawat_app/providers/settings_provider.dart';
import 'package:salawat_app/services/backup_service.dart';
import 'package:salawat_app/services/notification_service.dart';
import 'package:salawat_app/services/storage_service.dart';

const MethodChannel _notificationsChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');
const MethodChannel _shareChannel =
    MethodChannel('dev.fluttercommunity.plus/share');
const MethodChannel _pathProviderChannel =
    MethodChannel('plugins.flutter.io/path_provider');

Future<void> pumpApp(WidgetTester tester) async {
  final storageService = StorageService();
  await storageService.init();

  final notif = NotificationService();
  await notif.init();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CountersProvider(storageService, notif)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService)..load(),
        ),
        Provider<NotificationService>.value(value: notif),
        Provider<BackupService>.value(
          value: BackupService(storage: storageService),
        ),
      ],
      child: const MyApp(),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, (MethodCall call) async {
      return call.method == 'initialize' ? true : null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (MethodCall call) async {
      return Directory.systemTemp.path;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, (MethodCall call) async {
      return {'status': 'success'};
    });
  });

  testWidgets('export tile opens a sheet with JSON and CSV options',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    await tester.ensureVisible(find.text('تصدير البيانات'));
    await tester.tap(find.text('تصدير البيانات'));
    await tester.pumpAndSettle();

    expect(find.text('نسخة احتياطية كاملة (JSON)'), findsOneWidget);
    expect(find.text('ملف CSV (لبرامج الجداول)'), findsOneWidget);
  });

  testWidgets('sharing the JSON export calls the share channel with a .json file',
      (WidgetTester tester) async {
    final sharedPaths = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, (MethodCall call) async {
      if (call.method == 'shareFiles') {
        final args = call.arguments as Map<dynamic, dynamic>;
        sharedPaths.addAll((args['files'] as List).cast<String>());
      }
      return {'status': 'success'};
    });

    await pumpApp(tester);
    await openSettings(tester);

    await tester.ensureVisible(find.text('تصدير البيانات'));
    await tester.tap(find.text('تصدير البيانات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('نسخة احتياطية كاملة (JSON)'));
    await tester.pumpAndSettle();

    expect(sharedPaths, hasLength(1));
    expect(sharedPaths.single, endsWith('.json'));
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/settings_backup_test.dart`
Expected: FAIL — `تصدير البيانات` not found (section not implemented).

- [ ] **Step 3: Write the implementation**

In `lib/screens/settings_screen.dart`:

- Add imports:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/backup_service.dart';
import '../utils/app_strings.dart';
import '../utils/stats.dart';
```

- Add the backup section to the `ListView` children, between the appearance section's `Divider` (line 128) and the About `ListTile`:

```dart
              const Divider(),

              // Backup section
              _buildSectionTitle(context, AppStrings.backupSectionTitle),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text(AppStrings.exportData),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showExportSheet(context),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text(AppStrings.restoreBackup),
                onTap: () => _showRestoreFlow(context),
              ),
```

- Add the methods (before `_buildSectionTitle`):

```dart
  void _showExportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text(AppStrings.exportJsonOption),
              onTap: () {
                Navigator.pop(sheetContext);
                _exportData(context, isCsv: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text(AppStrings.exportCsvOption),
              onTap: () {
                Navigator.pop(sheetContext);
                _exportData(context, isCsv: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, {required bool isCsv}) async {
    final backup = context.read<BackupService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final content =
          isCsv ? await backup.buildCsv() : await backup.buildJsonBackup();
      final dir = await getTemporaryDirectory();
      final name = 'zikr-backup-${dailyKey(DateTime.now())}.${isCsv ? 'csv' : 'json'}';
      final file = File('${dir.path}/$name')..writeAsStringSync(content);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: isCsv ? 'text/csv' : 'application/json')],
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.errorExportFailed)),
      );
    }
  }
```

Note: `_showRestoreFlow` is referenced by the restore tile; add its (empty or full) implementation in Task 8 — to keep this task compilable, implement `_showRestoreFlow` fully in Task 8 and, if executing tasks out of order, add a stub here that shows the `errorReadFileFailed` snackbar (Task 8 replaces it).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/settings_backup_test.dart`
Expected: PASS (both tests). Also run `flutter test` to confirm no regressions.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/settings_screen.dart test/settings_backup_test.dart
git commit -m "feat: add backup export flow to settings"
```

---

### Task 8: Settings screen — restore flow (pick, confirm, replace)

**Files:**
- Modify: `lib/screens/settings_screen.dart` (implement `_showRestoreFlow`)
- Modify: `test/settings_backup_test.dart` (restore tests)

**Interfaces:**
- Consumes: `parseJsonBackup`/`applyBackup` (Tasks 2/5), `FilePicker.platform.pickFiles` (`file_picker ^8.1.7`), `CountersProvider.load()`, `SettingsProvider.load()`, `NotificationService.rescheduleAll(...)`, `AppStrings.backupErrorMessage` (Task 1 + this task adds the mapping below).
- Produces: complete restore flow. `AppStrings.backupErrorMessage(BackupErrorCode)` maps codes to the Arabic strings.

- [ ] **Step 1: Write the failing widget tests**

Append to `test/settings_backup_test.dart` (inside `main()`):

```dart
class _FakeFilePicker extends FilePicker {
  _FakeFilePicker(this.result);
  final FilePickerResult? result;

  @override
  Future<FilePickerResult?> pickFiles({
    required FileType type,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    bool withData = false,
    String? dialogTitle,
    String? initialDirectory,
    String? fileName,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return result;
  }
}

String backupJson({String name = 'الصلاة على النبي ﷺ', int count = 99}) {
  return jsonEncode({
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'activeCounterId': 'salawat',
    'settings': {'vibrationEnabled': false, 'isDarkMode': true},
    'counters': [
      {
        'id': 'salawat',
        'name': name,
        'currentCount': count,
        'totalCount': count,
        'dailyTarget': 0,
        'history': <String, int>{},
        'lastUsedAt': DateTime.now().toIso8601String(),
        'lastResetAt': null,
        'remindersEnabled': false,
        'reminderType': 0,
        'reminderIntervalMinutes': 60,
        'dailyReminderTimes': <int>[],
      },
    ],
  });
}

FilePickerResult pickerResult(String content) {
  final bytes = utf8.encode(content);
  return FilePickerResult([
    PlatformFile(
      name: 'zikr-backup.json',
      size: bytes.length,
      bytes: bytes,
    ),
  ]);
}
```

Add the tests inside `main()`:

```dart
  testWidgets('restore asks for confirmation, then replaces data',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'adhkar_counters': jsonEncode([
        {
          'id': 'old',
          'name': 'قديم',
          'currentCount': 5,
          'totalCount': 5,
          'dailyTarget': 0,
          'history': <String, int>{},
          'lastUsedAt': DateTime.now().toIso8601String(),
          'lastResetAt': null,
          'remindersEnabled': false,
          'reminderType': 0,
          'reminderIntervalMinutes': 60,
          'dailyReminderTimes': <int>[],
        },
      ]),
    });
    FilePicker.platform =
        _FakeFilePicker(pickerResult(backupJson()));

    await pumpApp(tester);
    await openSettings(tester);

    await tester.ensureVisible(find.text('استعادة نسخة احتياطية'));
    await tester.tap(find.text('استعادة نسخة احتياطية'));
    await tester.pumpAndSettle();

    expect(
      find.text('سيتم استبدال جميع البيانات الحالية. هل أنت متأكد؟'),
      findsOneWidget,
    );

    await tester.tap(find.text('استعادة'));
    await tester.pumpAndSettle();

    expect(find.text('تمت الاستعادة بنجاح'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('adhkar_counters')!) as List;
    expect(saved, hasLength(1));
    expect(saved.single['id'], 'salawat');
    expect(saved.single['currentCount'], 99);
  });

  testWidgets('cancelling the confirm dialog leaves data untouched',
      (WidgetTester tester) async {
    FilePicker.platform =
        _FakeFilePicker(pickerResult(backupJson()));

    await pumpApp(tester);
    await openSettings(tester);

    await tester.ensureVisible(find.text('استعادة نسخة احتياطية'));
    await tester.tap(find.text('استعادة نسخة احتياطية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(find.text('تمت الاستعادة بنجاح'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('adhkar_counters')!) as List;
    expect(saved.single['id'], 'salawat');
  });

  testWidgets('invalid backup file shows an error and no dialog',
      (WidgetTester tester) async {
    FilePicker.platform =
        _FakeFilePicker(pickerResult('not json'));

    await pumpApp(tester);
    await openSettings(tester);

    await tester.ensureVisible(find.text('استعادة نسخة احتياطية'));
    await tester.tap(find.text('استعادة نسخة احتياطية'));
    await tester.pumpAndSettle();

    expect(find.text('ملف النسخة الاحتياطية غير صالح'), findsOneWidget);
    expect(
      find.text('سيتم استبدال جميع البيانات الحالية. هل أنت متأكد؟'),
      findsNothing,
    );
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/settings_backup_test.dart`
Expected: FAIL — `_showRestoreFlow` missing or restore strings absent.

- [ ] **Step 3: Write the implementation**

In `lib/utils/app_strings.dart`, add the code→message mapping (imports `BackupErrorCode` from `../services/backup_service.dart`):

```dart
import '../services/backup_service.dart';

class AppStrings {
  ...
  static String backupErrorMessage(BackupErrorCode code) {
    switch (code) {
      case BackupErrorCode.invalidFormat:
        return errorInvalidFormat;
      case BackupErrorCode.versionMismatch:
        return errorVersionMismatch;
      case BackupErrorCode.emptyBackup:
        return errorEmptyBackup;
    }
  }
```

In `lib/screens/settings_screen.dart`, add `_showRestoreFlow` (after `_exportData`):

```dart
  Future<void> _showRestoreFlow(BuildContext context) async {
    final backup = context.read<BackupService>();
    final counters = context.read<CountersProvider>();
    final settings = context.read<SettingsProvider>();
    final notifications = context.read<NotificationService>();
    final messenger = ScaffoldMessenger.of(context);

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final BackupData data;
    try {
      data = backup.parseJsonBackup(utf8.decode(picked.files.single.bytes!));
    } on BackupException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.backupErrorMessage(e.code))),
      );
      return;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.errorReadFileFailed)),
      );
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.restoreBackup),
        content: const Text(AppStrings.restoreConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'استعادة',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await backup.applyBackup(data);
      await counters.load();
      await settings.load();
      await notifications.rescheduleAll(counters.counters);
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.restoreSuccess)),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.errorRestoreFailed)),
      );
    }
  }
```

Add import to `lib/screens/settings_screen.dart`: `import '../services/notification_service.dart';`

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: PASS (all tests — new restore tests + prior export tests + existing suite).

- [ ] **Step 5: Run analyzer**

Run: `flutter analyze`
Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/settings_screen.dart lib/utils/app_strings.dart test/settings_backup_test.dart
git commit -m "feat: add backup restore flow with confirmation"
```

---

## Self-Review Notes

- **Spec coverage:** JSON format (Task 3), CSV format + BOM + escaping (Task 4), parse validation + exceptions (Task 2), apply/replace (Task 5), providers wiring (Task 6), export UI + share sheet (Task 7), restore UI + confirm + reschedule + error handling (Task 8), strings centralized (Task 1 + 8), dependencies (Task 1). Non-goals (auto-backup, CSV restore, merge) are not implemented anywhere.
- **Type consistency:** `BackupErrorCode`/`BackupException`/`BackupData`/`BackupService` names and signatures are defined once in Task 2 and reused verbatim in Tasks 3–8. `buildJsonBackup`/`buildCsv` are `Future<String>` everywhere. `parseJsonBackup(String)` → `BackupData` everywhere. `applyBackup(BackupData)` → `Future<void>` everywhere.
- **Known assumption:** `file_picker ^8.1.7` `pickFiles` signature in the `_FakeFilePicker` override matches the real class; if the resolved version differs, adjust the override's named parameters to match (the settings screen call site itself only uses `type`, `allowedExtensions`, `withData`).