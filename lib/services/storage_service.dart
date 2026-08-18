import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/counter_data.dart';
import '../models/app_settings.dart';

class StorageService {
  static const String _counterKey = 'counter_data';
  static const String _settingsKey = 'app_settings';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Counter methods
  Future<CounterData> getCounterData() async {
    final jsonString = _prefs.getString(_counterKey);
    if (jsonString == null) {
      return CounterData();
    }
    return CounterData.fromJson(json.decode(jsonString));
  }

  Future<void> saveCounterData(CounterData data) async {
    final jsonString = json.encode(data.toJson());
    await _prefs.setString(_counterKey, jsonString);
  }

  // Settings methods
  Future<AppSettings> getSettings() async {
    final jsonString = _prefs.getString(_settingsKey);
    if (jsonString == null) {
      return AppSettings();
    }
    return AppSettings.fromJson(json.decode(jsonString));
  }

  Future<void> saveSettings(AppSettings settings) async {
    final jsonString = json.encode(settings.toJson());
    await _prefs.setString(_settingsKey, jsonString);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
