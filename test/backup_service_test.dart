import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salawat_app/models/adhkar_counter.dart';
import 'package:salawat_app/services/backup_service.dart';
import 'package:salawat_app/services/storage_service.dart';

void main() {
  Future<StorageService> storageWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final storage = StorageService();
    await storage.init();
    return storage;
  }

  String validJson({Object? version = 1, Object? counters, Object? settings}) {
    return jsonEncode({
      'version': version,
      'exportedAt': '2026-08-20T10:00:00.000Z',
      'activeCounterId': 'salawat',
      'settings': settings ?? {'vibrationEnabled': true, 'isDarkMode': false},
      'counters': counters ??
          [
            AdhkarCounter(id: 'salawat', name: 'الصلاة على النبي ﷺ')
                .toJson(),
          ],
    });
  }

  Future<BackupService> serviceWith(Map<String, Object> values) async =>
      BackupService(storage: await storageWith(values));

  group('parseJsonBackup', () {
    test('rejects malformed JSON with invalidFormat', () async {
      final service = await serviceWith({});
      expect(
        () => service.parseJsonBackup('not json'),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.invalidFormat)),
      );
    });

    test('rejects a non-object root with invalidFormat', () async {
      final service = await serviceWith({});
      expect(
        () => service.parseJsonBackup('[1, 2]'),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.invalidFormat)),
      );
    });

    test('rejects missing or unsupported version with versionMismatch',
        () async {
      final service = await serviceWith({});
      expect(
        () => service.parseJsonBackup(validJson(version: 2)),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.versionMismatch)),
      );
      expect(
        () => service.parseJsonBackup(validJson(version: null)),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.versionMismatch)),
      );
    });

    test('rejects missing or empty counters with emptyBackup', () async {
      final service = await serviceWith({});
      expect(
        () => service.parseJsonBackup(validJson(counters: [])),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.emptyBackup)),
      );
      final noCounters =
          jsonEncode(jsonDecode(validJson())..remove('counters'));
      expect(
        () => service.parseJsonBackup(noCounters),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.emptyBackup)),
      );
    });

    test('rejects a counter missing id or name with invalidFormat', () async {
      final service = await serviceWith({});
      final noId = AdhkarCounter(id: '', name: 'x').toJson();
      expect(
        () => service.parseJsonBackup(validJson(counters: [noId])),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.invalidFormat)),
      );
      final noName = AdhkarCounter(id: 'a', name: '').toJson();
      expect(
        () => service.parseJsonBackup(validJson(counters: [noName])),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.invalidFormat)),
      );
    });

    test('rejects non-numeric counts with invalidFormat', () async {
      final service = await serviceWith({});
      final bad = AdhkarCounter(id: 'a', name: 'x').toJson()
        ..['currentCount'] = 'many';
      expect(
        () => service.parseJsonBackup(validJson(counters: [bad])),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.invalidFormat)),
      );
    });

    test('rejects missing settings with invalidFormat', () async {
      final service = await serviceWith({});
      final noSettings =
          jsonEncode(jsonDecode(validJson())..remove('settings'));
      expect(
        () => service.parseJsonBackup(noSettings),
        throwsA(isA<BackupException>()
            .having((e) => e.code, 'code', BackupErrorCode.invalidFormat)),
      );
    });

    test('parses a valid backup and resolves active counter', () async {
      final service = await serviceWith({});
      final data = service.parseJsonBackup(validJson());
      expect(data.counters, hasLength(1));
      expect(data.counters.first.id, 'salawat');
      expect(data.settings.vibrationEnabled, isTrue);
      expect(data.activeCounterId, 'salawat');
    });

    test('falls back to the first counter when active id is unknown',
        () async {
      final service = await serviceWith({});
      final data = service.parseJsonBackup(validJson());
      expect(data.activeCounterId, 'salawat');
    });
  });
}