import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/domain/entities/adhkar_counter.dart';
import 'package:salawat_app/domain/entities/app_settings.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/data/notifications/notification_service.dart';
import 'package:salawat_app/data/storage_service.dart';
import 'package:salawat_app/domain/services/stats_calculator.dart';

class _FakeStorageService extends StorageService {
  _FakeStorageService(this.stored);

  List<AdhkarCounter> stored;
  String? activeId;
  AppSettings settings = AppSettings();

  @override
  Future<List<AdhkarCounter>> getCounters() async => stored;

  @override
  Future<void> saveCounters(List<AdhkarCounter> counters) async {
    stored = counters;
  }

  @override
  Future<String?> getActiveCounterId() async => activeId;

  @override
  Future<void> saveActiveCounterId(String? id) async {
    activeId = id;
  }

  @override
  Future<AppSettings> getSettings() async => settings;

  @override
  Future<void> saveSettings(AppSettings value) async {
    settings = value;
  }
}

class _FakeNotificationService extends NotificationService {
  bool permissionGranted = true;
  int rescheduleCalls = 0;
  AppSettings? lastSettings;
  final List<String> targetReachedNames = [];

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> rescheduleAll(List<AdhkarCounter> counters,
      {AppSettings? settings}) async {
    rescheduleCalls++;
    lastSettings = settings;
  }

  @override
  Future<void> showDailyTargetReached(String counterName) async {
    targetReachedNames.add(counterName);
  }
}

AdhkarCounter _counter(
  String id, {
  String name = 'ذكر',
  int currentCount = 0,
  int totalCount = 0,
  int dailyTarget = 0,
  Map<String, int> history = const {},
  DateTime? lastUsedAt,
}) {
  return AdhkarCounter(
    id: id,
    name: name,
    currentCount: currentCount,
    totalCount: totalCount,
    dailyTarget: dailyTarget,
    history: history,
    lastUsedAt: lastUsedAt,
  );
}

void main() {
  test('load defaults the active counter to the first', () async {
    final storage = _FakeStorageService([
      _counter('a', name: 'A'),
      _counter('b', name: 'B'),
    ]);
    final provider = CountersProvider(storage, _FakeNotificationService());

    await provider.load();

    expect(provider.activeCounter.id, 'a');
    expect(provider.counters.length, 2);
  });

  test('setActive switches the active counter', () async {
    final storage = _FakeStorageService([
      _counter('a', name: 'A'),
      _counter('b', name: 'B'),
    ]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();

    await provider.setActive('b');

    expect(provider.activeCounter.id, 'b');
  });

  test('increment increases the active counter', () async {
    final storage = _FakeStorageService([
      _counter('a', name: 'A'),
      _counter('b', name: 'B'),
    ]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();

    await provider.increment();

    expect(provider.activeCounter.currentCount, 1);
    expect(provider.activeCounter.totalCount, 1);
  });

  test('rollover on load resets count and records history', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final storage = _FakeStorageService([
      _counter(
        'a',
        name: 'A',
        currentCount: 50,
        totalCount: 200,
        lastUsedAt: yesterday,
      ),
    ]);
    final provider = CountersProvider(storage, _FakeNotificationService());

    await provider.load();

    expect(provider.activeCounter.currentCount, 0);
    expect(provider.activeCounter.totalCount, 200);
    expect(provider.activeCounter.history[dailyKey(yesterday)], 50);
  });

  test('rollover on load keeps a same-day count', () async {
    final storage = _FakeStorageService([
      _counter('a', name: 'A', currentCount: 50, totalCount: 200),
    ]);
    final provider = CountersProvider(storage, _FakeNotificationService());

    await provider.load();

    expect(provider.activeCounter.currentCount, 50);
    expect(provider.activeCounter.totalCount, 200);
  });

  test('undo restores the previous count', () async {
    final storage = _FakeStorageService([_counter('a', name: 'A')]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();

    await provider.increment();
    expect(provider.activeCounter.currentCount, 1);
    expect(provider.canUndo, isTrue);

    await provider.undo();

    expect(provider.activeCounter.currentCount, 0);
    expect(provider.canUndo, isFalse);
  });

  test('undo decrements the lifetime total back', () async {
    final storage = _FakeStorageService([
      _counter('a', name: 'A', currentCount: 5, totalCount: 100),
    ]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();

    await provider.increment();
    expect(provider.activeCounter.currentCount, 6);
    expect(provider.activeCounter.totalCount, 101);

    await provider.undo();

    expect(provider.activeCounter.currentCount, 5);
    expect(provider.activeCounter.totalCount, 100);
  });

  test('reset zeroes current but keeps total', () async {
    final storage = _FakeStorageService([
      _counter('a', name: 'A', currentCount: 42, totalCount: 100),
    ]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();

    await provider.reset();

    expect(provider.activeCounter.currentCount, 0);
    expect(provider.activeCounter.totalCount, 100);
  });

  test('reset(includeTotal: true) zeroes both counts', () async {
    final storage = _FakeStorageService([
      _counter('a', name: 'A', currentCount: 42, totalCount: 100),
    ]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();

    await provider.reset(includeTotal: true);

    expect(provider.activeCounter.currentCount, 0);
    expect(provider.activeCounter.totalCount, 0);
  });

  test('addCounter appends and activates', () async {
    final storage = _FakeStorageService([_counter('a', name: 'A')]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();

    await provider.addCounter('جديد');

    expect(provider.counters.length, 2);
    expect(provider.activeCounter.name, 'جديد');
  });

  test('ensureCounterNamed creates a missing counter', () async {
    final storage = _FakeStorageService([_counter('a', name: 'A')]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();

    final id = await provider.ensureCounterNamed('سبحان الله وبحمده');

    expect(provider.counters.length, 2);
    expect(provider.activeCounter.id, id);
    expect(provider.activeCounter.name, 'سبحان الله وبحمده');
  });

  test('ensureCounterNamed re-activates an existing counter', () async {
    final storage = _FakeStorageService([
      _counter('a', name: 'A'),
      _counter('b', name: 'B'),
    ]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();
    await provider.setActive('b');

    final id = await provider.ensureCounterNamed('A');

    expect(provider.counters.length, 2);
    expect(provider.activeCounter.id, id);
    expect(provider.activeCounter.id, 'a');
  });

  test('renameCounter updates the name', () async {
    final storage = _FakeStorageService([_counter('a', name: 'A')]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();

    await provider.renameCounter('a', 'Renamed');

    expect(provider.activeCounter.name, 'Renamed');
  });

  test('deleteCounter removes and re-activates the first remaining', () async {
    final storage = _FakeStorageService([
      _counter('a', name: 'A'),
      _counter('b', name: 'B'),
    ]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();
    await provider.setActive('a');

    await provider.deleteCounter('a');

    expect(provider.counters.length, 1);
    expect(provider.activeCounter.id, 'b');
  });

  test('setRemindersEnabled enables when permission is granted', () async {
    final storage = _FakeStorageService([_counter('a', name: 'A')]);
    final notif = _FakeNotificationService()..permissionGranted = true;
    final provider = CountersProvider(storage, notif);
    await provider.load();

    final result = await provider.setRemindersEnabled('a', true);

    expect(result, isTrue);
    expect(provider.activeCounter.remindersEnabled, isTrue);
    expect(notif.rescheduleCalls, 1);
  });

  test('setRemindersEnabled keeps disabled when permission is denied', () async {
    final storage = _FakeStorageService([_counter('a', name: 'A')]);
    final notif = _FakeNotificationService()..permissionGranted = false;
    final provider = CountersProvider(storage, notif);
    await provider.load();

    final result = await provider.setRemindersEnabled('a', true);

    expect(result, isFalse);
    expect(provider.activeCounter.remindersEnabled, isFalse);
    expect(notif.rescheduleCalls, 0);
  });

  test('setReminderType prayer persists and passes settings to reschedule',
      () async {
    final storage = _FakeStorageService([
      _counter('a', name: 'A'),
    ]);
    final notif = _FakeNotificationService();
    final provider = CountersProvider(storage, notif);
    await provider.load();
    await provider.setDailyTarget('a', 5);

    await provider.setReminderType('a', ReminderType.prayer);

    expect(provider.activeCounter.reminderType, ReminderType.prayer);
    expect(notif.rescheduleCalls, 1);
    expect(notif.lastSettings, isNotNull);
  });

  test('setPrayerOffset persists the offset', () async {
    final storage = _FakeStorageService([_counter('a', name: 'A')]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();

    await provider.setPrayerOffset('a', 20);

    expect(provider.activeCounter.prayerOffsetMinutes, 20);
  });

  test('notifyDailyTargetReached shows the active counter name', () async {
    final storage = _FakeStorageService([_counter('a', name: 'سبحان الله')]);
    final notif = _FakeNotificationService();
    final provider = CountersProvider(storage, notif);
    await provider.load();

    await provider.notifyDailyTargetReached();

    expect(notif.targetReachedNames, ['سبحان الله']);
  });

  test('setActive persists the active counter id', () async {
    final storage = _FakeStorageService([
      _counter('a', name: 'A'),
      _counter('b', name: 'B'),
    ]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();

    await provider.setActive('b');

    expect(storage.activeId, 'b');
  });

  test('load restores the persisted active counter id', () async {
    final storage = _FakeStorageService([
      _counter('a', name: 'A'),
      _counter('b', name: 'B'),
    ]);
    storage.activeId = 'b';
    final provider = CountersProvider(storage, _FakeNotificationService());

    await provider.load();

    expect(provider.activeCounter.id, 'b');
  });

  test('load falls back to the first counter when the persisted id is stale',
      () async {
    final storage = _FakeStorageService([
      _counter('a', name: 'A'),
      _counter('b', name: 'B'),
    ]);
    storage.activeId = 'gone';
    final provider = CountersProvider(storage, _FakeNotificationService());

    await provider.load();

    expect(provider.activeCounter.id, 'a');
  });

  test('rolloverIfNewDay archives a previous-day count', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final storage = _FakeStorageService([
      _counter(
        'a',
        name: 'A',
        currentCount: 30,
        totalCount: 200,
        lastUsedAt: yesterday,
      ),
    ]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();

    await provider.rolloverIfNewDay();

    expect(provider.activeCounter.currentCount, 0);
    expect(provider.activeCounter.history[dailyKey(yesterday)], 30);
  });

  test('rolloverIfNewDay clears the undo buffer', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final storage = _FakeStorageService([
      _counter(
        'a',
        name: 'A',
        currentCount: 30,
        totalCount: 200,
        lastUsedAt: yesterday,
      ),
    ]);
    final provider = CountersProvider(storage, _FakeNotificationService());
    await provider.load();

    await provider.increment();
    expect(provider.canUndo, isTrue);

    await provider.rolloverIfNewDay();

    expect(provider.canUndo, isFalse);
  });
}

