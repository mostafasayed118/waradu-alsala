import 'package:flutter/foundation.dart';
import 'package:salawat_app/domain/entities/app_settings.dart';
import 'package:salawat_app/data/storage_service.dart';

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

  Future<void> toggleSound(bool enabled) async {
    _settings = _settings.copyWith(soundEnabled: enabled);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _settings = _settings.copyWith(languageCode: code);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setPrayerLocation(double latitude, double longitude) async {
    _settings =
        _settings.copyWith(latitude: latitude, longitude: longitude);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setCalculationMethod(String method) async {
    _settings = _settings.copyWith(calculationMethod: method);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    _settings = _settings.copyWith(isDarkMode: enabled);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }
}

