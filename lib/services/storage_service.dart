import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/adhkar_counter.dart';
import '../models/app_settings.dart';

class StorageService {
  static const String _countersKey = 'adhkar_counters';
  static const String _settingsKey = 'app_settings';
  static const String _legacyCounterKey = 'counter_data';
  static const String _activeCounterIdKey = 'active_counter_id';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Counters
  Future<List<AdhkarCounter>> getCounters() async {
    final jsonString = _prefs.getString(_countersKey);
    if (jsonString != null) {
      return _decodeCounters(jsonString);
    }
    final migrated = await _migrateLegacy();
    await saveCounters(migrated);
    return migrated;
  }

  Future<void> saveCounters(List<AdhkarCounter> counters) async {
    final jsonString = json.encode(counters.map((c) => c.toJson()).toList());
    await _prefs.setString(_countersKey, jsonString);
  }

  List<AdhkarCounter> _decodeCounters(String jsonString) {
    final list = json.decode(jsonString) as List;
    return list
        .map((e) => AdhkarCounter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdhkarCounter>> _migrateLegacy() async {
    final presets = _buildPresets();

    final legacyCounter = _prefs.getString(_legacyCounterKey);
    final legacySettings = _prefs.getString(_settingsKey);

    var salawat = presets.first;

    if (legacyCounter != null) {
      final map = json.decode(legacyCounter) as Map<String, dynamic>;
      salawat = salawat.copyWith(
        currentCount: map['currentCount'] ?? 0,
        totalCount: map['totalCount'] ?? 0,
        history: _decodeHistory(map['history']),
        lastUsedAt: map['lastUsedAt'] != null
            ? DateTime.parse(map['lastUsedAt'] as String)
            : null,
        lastResetAt: map['lastResetAt'] != null
            ? DateTime.parse(map['lastResetAt'] as String)
            : null,
      );
    }

    if (legacySettings != null) {
      final map = json.decode(legacySettings) as Map<String, dynamic>;
      salawat = salawat.copyWith(
        dailyTarget: map['dailyTarget'] ?? 0,
        remindersEnabled: map['notificationsEnabled'] ?? false,
        reminderType: ReminderType.values[map['reminderType'] ?? 0],
        reminderIntervalMinutes: map['reminderIntervalMinutes'] ?? 60,
        dailyReminderTimes:
            List<int>.from(map['dailyReminderTimes'] ?? const []),
      );
    }

    presets[0] = salawat;
    await _prefs.remove(_legacyCounterKey);
    return presets;
  }

  List<AdhkarCounter> _buildPresets() => [
        AdhkarCounter(id: 'salawat', name: 'الصلاة على النبي ﷺ'),
        AdhkarCounter(id: 'tasbih', name: 'سبحان الله'),
        AdhkarCounter(id: 'tahmid', name: 'الحمد لله'),
        AdhkarCounter(id: 'takbir', name: 'الله أكبر'),
        AdhkarCounter(id: 'istighfar', name: 'أستغفر الله'),
      ];

  Map<String, int> _decodeHistory(dynamic value) {
    if (value is! Map) return const {};
    return value.map<String, int>(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    );
  }

  // Settings
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

  // Active counter
  Future<String?> getActiveCounterId() async {
    return _prefs.getString(_activeCounterIdKey);
  }

  Future<void> saveActiveCounterId(String? id) async {
    if (id == null) {
      await _prefs.remove(_activeCounterIdKey);
    } else {
      await _prefs.setString(_activeCounterIdKey, id);
    }
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
