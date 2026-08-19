import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class SettingsProvider with ChangeNotifier {
  final StorageService _storage;
  final NotificationService _notificationService;
  AppSettings _settings = AppSettings();

  SettingsProvider(this._storage, this._notificationService);

  AppSettings get settings => _settings;
  bool get isDarkMode => _settings.isDarkMode;

  Future<void> load() async {
    _settings = await _storage.getSettings();
    notifyListeners();
  }

  Future<bool> toggleNotifications(bool enabled) async {
    if (enabled) {
      final granted = await _notificationService.requestPermission();
      if (!granted) {
        return false;
      }
    }
    await _apply(_settings.copyWith(notificationsEnabled: enabled), reschedule: true);
    return true;
  }

  Future<void> toggleVibration(bool enabled) =>
      _apply(_settings.copyWith(vibrationEnabled: enabled));

  Future<void> toggleDailyCounter(bool enabled) =>
      _apply(_settings.copyWith(dailyCounter: enabled));

  Future<void> toggleDarkMode(bool enabled) =>
      _apply(_settings.copyWith(isDarkMode: enabled));

  Future<void> setReminderType(ReminderType type) =>
      _apply(_settings.copyWith(reminderType: type), reschedule: true);

  Future<void> setReminderInterval(int minutes) =>
      _apply(_settings.copyWith(reminderIntervalMinutes: minutes), reschedule: true);

  Future<void> setDailyReminderTimes(List<int> times) =>
      _apply(_settings.copyWith(dailyReminderTimes: times), reschedule: true);

  Future<void> _apply(AppSettings next, {bool reschedule = false}) async {
    _settings = next;
    await _storage.saveSettings(_settings);
    if (reschedule) {
      await _updateNotifications();
    }
    notifyListeners();
  }

  Future<void> _updateNotifications() async {
    if (!_settings.notificationsEnabled) {
      await _notificationService.cancelAllNotifications();
      return;
    }

    if (_settings.reminderType == ReminderType.interval) {
      await _notificationService.scheduleIntervalNotification(
        _settings.reminderIntervalMinutes,
      );
    } else {
      await _notificationService.scheduleDailyNotifications(
        _settings.dailyReminderTimes,
      );
    }
  }
}
