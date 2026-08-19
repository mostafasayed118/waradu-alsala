import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/models/counter_data.dart';
import 'package:salawat_app/models/app_settings.dart';

void main() {
  group('CounterData', () {
    test('should create with default values', () {
      final counter = CounterData();
      expect(counter.currentCount, 0);
      expect(counter.totalCount, 0);
      expect(counter.lastUsedAt, isNotNull);
      expect(counter.lastResetAt, isNull);
    });

    test('should create with custom values', () {
      final now = DateTime.now();
      final counter = CounterData(
        currentCount: 10,
        totalCount: 100,
        lastUsedAt: now,
        lastResetAt: now,
      );
      expect(counter.currentCount, 10);
      expect(counter.totalCount, 100);
      expect(counter.lastUsedAt, now);
      expect(counter.lastResetAt, now);
    });

    test('should copy with new values', () {
      final counter = CounterData(currentCount: 5);
      final newCounter = counter.copyWith(currentCount: 10);
      expect(newCounter.currentCount, 10);
      expect(counter.currentCount, 5); // Original unchanged
    });

    test('should convert to JSON and back', () {
      final now = DateTime.now();
      final counter = CounterData(
        currentCount: 10,
        totalCount: 100,
        lastUsedAt: now,
        lastResetAt: now,
      );
      
      final json = counter.toJson();
      expect(json['currentCount'], 10);
      expect(json['totalCount'], 100);
      
      final restored = CounterData.fromJson(json);
      expect(restored.currentCount, 10);
      expect(restored.totalCount, 100);
    });
  });

  group('AppSettings', () {
    test('should create with default values', () {
      final settings = AppSettings();
      expect(settings.notificationsEnabled, true);
      expect(settings.vibrationEnabled, true);
      expect(settings.dailyCounter, false);
      expect(settings.reminderType, ReminderType.interval);
      expect(settings.reminderIntervalMinutes, 60);
      expect(settings.dailyReminderTimes, isEmpty);
      expect(settings.dailyTarget, 0);
      expect(settings.isDarkMode, false);
    });

    test('should create with custom values', () {
      final settings = AppSettings(
        notificationsEnabled: false,
        vibrationEnabled: false,
        dailyCounter: true,
        reminderType: ReminderType.daily,
        reminderIntervalMinutes: 30,
        dailyReminderTimes: [480, 720, 1080],
        dailyTarget: 100,
        isDarkMode: true,
      );
      expect(settings.notificationsEnabled, false);
      expect(settings.vibrationEnabled, false);
      expect(settings.dailyCounter, true);
      expect(settings.reminderType, ReminderType.daily);
      expect(settings.reminderIntervalMinutes, 30);
      expect(settings.dailyReminderTimes, [480, 720, 1080]);
      expect(settings.dailyTarget, 100);
      expect(settings.isDarkMode, true);
    });

    test('should copy with new values', () {
      final settings = AppSettings();
      final newSettings = settings.copyWith(notificationsEnabled: false);
      expect(newSettings.notificationsEnabled, false);
      expect(settings.notificationsEnabled, true); // Original unchanged
    });

    test('should convert to JSON and back', () {
      final settings = AppSettings(
        notificationsEnabled: false,
        vibrationEnabled: false,
        dailyCounter: true,
        reminderType: ReminderType.daily,
        reminderIntervalMinutes: 30,
        dailyReminderTimes: [480, 720],
        dailyTarget: 100,
        isDarkMode: true,
      );
      
      final json = settings.toJson();
      expect(json['notificationsEnabled'], false);
      expect(json['vibrationEnabled'], false);
      expect(json['dailyCounter'], true);
      expect(json['reminderType'], 1);
      expect(json['reminderIntervalMinutes'], 30);
      expect(json['dailyReminderTimes'], [480, 720]);
      expect(json['dailyTarget'], 100);
      expect(json['isDarkMode'], true);
      
      final restored = AppSettings.fromJson(json);
      expect(restored.notificationsEnabled, false);
      expect(restored.vibrationEnabled, false);
      expect(restored.dailyCounter, true);
      expect(restored.reminderType, ReminderType.daily);
      expect(restored.reminderIntervalMinutes, 30);
      expect(restored.dailyReminderTimes, [480, 720]);
      expect(restored.dailyTarget, 100);
      expect(restored.isDarkMode, true);
    });
  });
}
