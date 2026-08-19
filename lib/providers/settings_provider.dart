import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  final StorageService _storage;
  AppSettings _settings = AppSettings();

  SettingsProvider(this._storage);

  AppSettings get settings => _settings;
  bool get isDarkMode => _settings.isDarkMode;

  Future<void> load() async {
    _settings = await _storage.getSettings();
    notifyListeners();
  }

  Future<void> toggleVibration(bool enabled) async {
    _settings = _settings.copyWith(vibrationEnabled: enabled);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    _settings = _settings.copyWith(isDarkMode: enabled);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }
}
