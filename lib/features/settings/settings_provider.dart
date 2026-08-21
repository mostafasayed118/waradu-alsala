import 'package:flutter/foundation.dart';
import 'package:salawat_app/domain/entities/app_settings.dart';
import 'package:salawat_app/domain/repositories/settings_repository.dart';

class SettingsProvider with ChangeNotifier {
  SettingsProvider({required this._settingsRepository});

  final SettingsRepository _settingsRepository;
  AppSettings _settings = AppSettings();

  AppSettings get settings => _settings;
  bool get isDarkMode => _settings.isDarkMode;

  Future<void> load() async {
    _settings = await _settingsRepository.getSettings();
    notifyListeners();
  }

  Future<void> toggleVibration(bool enabled) async {
    _settings = _settings.copyWith(vibrationEnabled: enabled);
    await _settingsRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleSound(bool enabled) async {
    _settings = _settings.copyWith(soundEnabled: enabled);
    await _settingsRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _settings = _settings.copyWith(languageCode: code);
    await _settingsRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setPrayerLocation(double latitude, double longitude) async {
    _settings =
        _settings.copyWith(latitude: latitude, longitude: longitude);
    await _settingsRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setCalculationMethod(String method) async {
    _settings = _settings.copyWith(calculationMethod: method);
    await _settingsRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    _settings = _settings.copyWith(isDarkMode: enabled);
    await _settingsRepository.saveSettings(_settings);
    notifyListeners();
  }
}

