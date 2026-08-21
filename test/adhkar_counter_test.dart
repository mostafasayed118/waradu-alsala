import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/domain/entities/adhkar_counter.dart';

void main() {
  group('AdhkarCounter', () {
    test('creates with default values', () {
      final counter = AdhkarCounter(id: 'x', name: 'y');
      expect(counter.currentCount, 0);
      expect(counter.totalCount, 0);
      expect(counter.dailyTarget, 0);
      expect(counter.history, isEmpty);
      expect(counter.remindersEnabled, isFalse);
      expect(counter.reminderType, ReminderType.interval);
      expect(counter.reminderIntervalMinutes, 60);
      expect(counter.dailyReminderTimes, isEmpty);
      expect(counter.lastUsedAt, isNotNull);
      expect(counter.lastResetAt, isNull);
    });

    test('converts to JSON and back', () {
      final now = DateTime(2025, 1, 10, 12, 30);
      final counter = AdhkarCounter(
        id: 'salawat',
        name: 'الصلاة على النبي ﷺ',
        currentCount: 5,
        totalCount: 100,
        dailyTarget: 10,
        history: {'2025-01-09': 10},
        lastUsedAt: now,
        lastResetAt: now,
        remindersEnabled: true,
        reminderType: ReminderType.daily,
        reminderIntervalMinutes: 30,
        dailyReminderTimes: [480, 720],
      );

      final restored = AdhkarCounter.fromJson(counter.toJson());

      expect(restored.id, 'salawat');
      expect(restored.name, 'الصلاة على النبي ﷺ');
      expect(restored.currentCount, 5);
      expect(restored.totalCount, 100);
      expect(restored.dailyTarget, 10);
      expect(restored.history, {'2025-01-09': 10});
      expect(restored.remindersEnabled, isTrue);
      expect(restored.reminderType, ReminderType.daily);
      expect(restored.reminderIntervalMinutes, 30);
      expect(restored.dailyReminderTimes, [480, 720]);
    });

    test('defaults missing fields from empty JSON', () {
      final restored = AdhkarCounter.fromJson(const {});
      expect(restored.currentCount, 0);
      expect(restored.totalCount, 0);
      expect(restored.history, isEmpty);
      expect(restored.reminderType, ReminderType.interval);
      expect(restored.remindersEnabled, isFalse);
    });
  });
}
