import 'dart:convert';

import '../models/adhkar_counter.dart';
import '../models/app_settings.dart';
import 'storage_service.dart';

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
  BackupService({required StorageService storage}) : _storage = storage;

  final StorageService _storage;

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
    final settings = AppSettings.fromJson(settingsJson);

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
      counters.add(AdhkarCounter.fromJson(entry));
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
}