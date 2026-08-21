import 'dart:convert';

import 'package:salawat_app/domain/entities/adhkar_counter.dart';
import 'package:salawat_app/domain/entities/app_settings.dart';
import 'package:salawat_app/domain/repositories/counters_repository.dart';
import 'package:salawat_app/domain/repositories/settings_repository.dart';

enum BackupErrorCode { invalidFormat, versionMismatch, emptyBackup }

class BackupException implements Exception {
  final BackupErrorCode code;
  const BackupException(this.code);
}

class BackupData {
  final List<AdhkarCounter> counters;
  final AppSettings settings;
  final String activeCounterId;

  const BackupData({
    required this.counters,
    required this.settings,
    required this.activeCounterId,
  });
}

class BackupService {
  BackupService({required this._counters, required this._settings});

  final CountersRepository _counters;
  final SettingsRepository _settings;

  static const int _backupVersion = 1;

  BackupData parseJsonBackup(String raw) {
    final Object? decoded;
    try {
      decoded = json.decode(raw);
    } on FormatException {
      throw const BackupException(BackupErrorCode.invalidFormat);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const BackupException(BackupErrorCode.invalidFormat);
    }
    if (decoded['version'] != _backupVersion) {
      throw const BackupException(BackupErrorCode.versionMismatch);
    }
    final settingsJson = decoded['settings'];
    if (settingsJson is! Map<String, dynamic>) {
      throw const BackupException(BackupErrorCode.invalidFormat);
    }
    final AppSettings settings;
    try {
      settings = AppSettings.fromJson(settingsJson);
    } catch (_) {
      throw const BackupException(BackupErrorCode.invalidFormat);
    }

    final countersJson = decoded['counters'];
    if (countersJson is! List || countersJson.isEmpty) {
      throw const BackupException(BackupErrorCode.emptyBackup);
    }
    final counters = <AdhkarCounter>[];
    for (final entry in countersJson) {
      if (entry is! Map<String, dynamic>) {
        throw const BackupException(BackupErrorCode.invalidFormat);
      }
      final id = entry['id'];
      final name = entry['name'];
      if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
        throw const BackupException(BackupErrorCode.invalidFormat);
      }
      for (final key in const ['currentCount', 'totalCount', 'dailyTarget']) {
        final value = entry[key];
        if (value != null && value is! num) {
          throw const BackupException(BackupErrorCode.invalidFormat);
        }
      }
      final history = entry['history'];
      if (history != null && history is! Map) {
        throw const BackupException(BackupErrorCode.invalidFormat);
      }
      final AdhkarCounter counter;
      try {
        counter = AdhkarCounter.fromJson(entry);
      } catch (_) {
        throw const BackupException(BackupErrorCode.invalidFormat);
      }
      counters.add(counter);
    }

    final activeId = decoded['activeCounterId'];
    final activeCounterId = activeId is String && counters.any((c) => c.id == activeId)
        ? activeId
        : counters.first.id;

    return BackupData(
      counters: counters,
      settings: settings,
      activeCounterId: activeCounterId,
    );
  }

  Future<void> applyBackup(BackupData data) async {
    await _counters.saveCounters(data.counters);
    await _settings.saveSettings(data.settings);
    await _counters.saveActiveCounterId(data.activeCounterId);
  }

  Future<String> buildJsonBackup() async {
    final counters = await _counters.getCounters();
    final settings = await _settings.getSettings();
    final storedActiveId = await _counters.getActiveCounterId();
    final activeCounterId =
        storedActiveId != null && counters.any((c) => c.id == storedActiveId)
            ? storedActiveId
            : (counters.isEmpty ? '' : counters.first.id);
    final map = <String, dynamic>{
      'version': _backupVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'activeCounterId': activeCounterId,
      'settings': settings.toJson(),
      'counters': counters.map((c) => c.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static const String _csvCountersHeader =
      '"id","name","totalCount","dailyTarget","remindersEnabled","reminderType","reminderIntervalMinutes","dailyReminderTimes","lastUsedAt","lastResetAt"';
  static const String _csvHistoryHeader =
      '"counterId","counterName","date","count"';

  Future<String> buildCsv() async {
    final counters = await _counters.getCounters();
    final buffer = StringBuffer('\uFEFF');
    buffer.writeln(_csvCountersHeader);
    for (final c in counters) {
      buffer.writeln([
        _csvField(c.id),
        _csvField(c.name),
        _csvField('${c.totalCount}'),
        _csvField('${c.dailyTarget}'),
        _csvField('${c.remindersEnabled}'),
        _csvField(c.reminderType.name),
        _csvField('${c.reminderIntervalMinutes}'),
        _csvField(c.dailyReminderTimes.join(';')),
        _csvField(c.lastUsedAt.toIso8601String()),
        _csvField(c.lastResetAt?.toIso8601String() ?? ''),
      ].join(','));
    }
    buffer.writeln();
    buffer.writeln(_csvHistoryHeader);
    for (final c in counters) {
      c.history.forEach((date, count) {
        if (count <= 0) return;
        buffer.writeln([
          _csvField(c.id),
          _csvField(c.name),
          _csvField(date),
          _csvField('$count'),
        ].join(','));
      });
    }
    return buffer.toString();
  }

  static String _csvField(String value) =>
      '"${value.replaceAll('"', '""')}"';
}

