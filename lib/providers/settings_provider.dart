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

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _storage.saveSettings(_settings);
    await _updateNotifications();
    notifyListeners();
  }

  Future<void> toggleNotifications(bool enabled) async {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    await _storage.saveSettings(_settings);
    await _updateNotifications();
    notifyListeners();
  }

  Future<void> toggleVibration(bool enabled) async {
    _settings = _settings.copyWith(vibrationEnabled: enabled);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleDailyCounter(bool enabled) async {
    _settings = _settings.copyWith(dailyCounter: enabled);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    _settings = _settings.copyWith(isDarkMode: enabled);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setReminderType(ReminderType type) async {
    _settings = _settings.copyWith(reminderType: type);
    await _storage.saveSettings(_settings);
    await _updateNotifications();
    notifyListeners();
  }

  Future<void> setReminderInterval(int minutes) async {
    _settings = _settings.copyWith(reminderIntervalMinutes: minutes);
    await _storage.saveSettings(_settings);
    await _updateNotifications();
    notifyListeners();
  }

  Future<void> setDailyReminderTimes(List<int> times) async {
    _settings = _settings.copyWith(dailyReminderTimes: times);
    await _storage.saveSettings(_settings);
    await _updateNotifications();
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
