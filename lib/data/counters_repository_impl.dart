import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:salawat_app/domain/entities/adhkar_counter.dart';
import 'package:salawat_app/domain/repositories/counters_repository.dart';

class CountersRepositoryImpl implements CountersRepository {
  static const String _countersKey = 'adhkar_counters';
  static const String _legacyCounterKey = 'counter_data';
  static const String _activeCounterIdKey = 'active_counter_id';
  static const String _settingsKey = 'app_settings';

  late final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  Future<List<AdhkarCounter>> getCounters() async {
    final prefs = await _prefs;
    final jsonString = prefs.getString(_countersKey);
    if (jsonString != null) {
      return _decodeCounters(jsonString);
    }
    final migrated = await _migrateLegacy();
    await saveCounters(migrated);
    return migrated;
  }

  @override
  Future<void> saveCounters(List<AdhkarCounter> counters) async {
    final prefs = await _prefs;
    final jsonString = json.encode(counters.map((c) => c.toJson()).toList());
    await prefs.setString(_countersKey, jsonString);
  }

  List<AdhkarCounter> _decodeCounters(String jsonString) {
    final list = json.decode(jsonString) as List;
    return list
        .map((e) => AdhkarCounter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdhkarCounter>> _migrateLegacy() async {
    final prefs = await _prefs;
    final presets = _buildPresets();

    final legacyCounter = prefs.getString(_legacyCounterKey);
    final legacySettings = prefs.getString(_settingsKey);

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
    await prefs.remove(_legacyCounterKey);
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

  @override
  Future<String?> getActiveCounterId() async {
    final prefs = await _prefs;
    return prefs.getString(_activeCounterIdKey);
  }

  @override
  Future<void> saveActiveCounterId(String? id) async {
    final prefs = await _prefs;
    if (id == null) {
      await prefs.remove(_activeCounterIdKey);
    } else {
      await prefs.setString(_activeCounterIdKey, id);
    }
  }
}
