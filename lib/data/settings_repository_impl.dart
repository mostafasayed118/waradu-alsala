import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:salawat_app/domain/entities/app_settings.dart';
import 'package:salawat_app/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const String _settingsKey = 'app_settings';

  late final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  Future<AppSettings> getSettings() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_settingsKey);
    if (jsonString == null) {
      return AppSettings();
    }
    return AppSettings.fromJson(json.decode(jsonString));
  }

  @override
  Future<AppSettings> saveSettings(AppSettings settings) async {
    final prefs = await _prefs;
    final jsonString = json.encode(settings.toJson());
    await prefs.setString(_settingsKey, jsonString);
    return settings;
  }
}
