import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salawat_app/domain/entities/adhkar_counter.dart';
import 'package:salawat_app/data/counters_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migrates the legacy single counter into the salawat preset', () async {
    SharedPreferences.setMockInitialValues({
      'counter_data': jsonEncode({
        'currentCount': 42,
        'totalCount': 500,
        'history': {'2025-01-01': 42},
      }),
      'app_settings': jsonEncode({
        'notificationsEnabled': true,
        'dailyTarget': 100,
        'reminderType': 1, // daily
        'reminderIntervalMinutes': 30,
        'dailyReminderTimes': [480, 720],
      }),
    });

    final repository = CountersRepositoryImpl();

    final counters = await repository.getCounters();

    expect(counters.length, 5);
    final salawat = counters.first;
    expect(salawat.id, 'salawat');
    expect(salawat.currentCount, 42);
    expect(salawat.totalCount, 500);
    expect(salawat.history, {'2025-01-01': 42});
    expect(salawat.dailyTarget, 100);
    expect(salawat.remindersEnabled, isTrue);
    expect(salawat.reminderType, ReminderType.daily);
    expect(salawat.reminderIntervalMinutes, 30);
    expect(salawat.dailyReminderTimes, [480, 720]);
  });

  test('returns the five presets when no legacy data exists', () async {
    SharedPreferences.setMockInitialValues({});

    final repository = CountersRepositoryImpl();

    final counters = await repository.getCounters();

    expect(counters.length, 5);
    expect(counters.first.id, 'salawat');
    expect(counters.first.currentCount, 0);
    expect(counters.first.history, isEmpty);
  });

  test('active counter id round-trips through storage', () async {
    SharedPreferences.setMockInitialValues({});

    final repository = CountersRepositoryImpl();

    expect(await repository.getActiveCounterId(), isNull);

    await repository.saveActiveCounterId('tasbih');
    expect(await repository.getActiveCounterId(), 'tasbih');

    await repository.saveActiveCounterId('salawat');
    expect(await repository.getActiveCounterId(), 'salawat');

    await repository.saveActiveCounterId(null);
    expect(await repository.getActiveCounterId(), isNull);
  });
}
