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

  group('buildJsonBackup', () {
    test('round-trips counters, history, settings, and active id', () async {
      final counter = AdhkarCounter(
        id: 'custom-1',
        name: 'ذكر، مع "علامات"',
        currentCount: 7,
        totalCount: 120,
        dailyTarget: 33,
        history: {'2026-08-19': 33, '2026-08-20': 7},
        remindersEnabled: true,
        reminderType: ReminderType.daily,
        dailyReminderTimes: [480, 1020],
      );
      final storage = await storageWith({
        'adhkar_counters':
            jsonEncode([counter.toJson(), AdhkarCounter(id: 'salawat', name: 'الصلاة على النبي ﷺ').toJson()]),
        'app_settings': jsonEncode({'vibrationEnabled': false, 'isDarkMode': true}),
        'active_counter_id': 'custom-1',
      });
      final service = BackupService(storage: storage);

      final data = service.parseJsonBackup(await service.buildJsonBackup());

      expect(data.counters, hasLength(2));
      final restored = data.counters.first;
      expect(restored.id, 'custom-1');
      expect(restored.name, 'ذكر، مع "علامات"');
      expect(restored.currentCount, 7);
      expect(restored.totalCount, 120);
      expect(restored.dailyTarget, 33);
      expect(restored.history, {'2026-08-19': 33, '2026-08-20': 7});
      expect(restored.remindersEnabled, isTrue);
      expect(restored.reminderType, ReminderType.daily);
      expect(restored.dailyReminderTimes, [480, 1020]);
      expect(data.settings.vibrationEnabled, isFalse);
      expect(data.settings.isDarkMode, isTrue);
      expect(data.activeCounterId, 'custom-1');
    });

    test('resolves active id to first counter when stored id is unknown',
        () async {
      final storage = await storageWith({
        'adhkar_counters': jsonEncode(
            [AdhkarCounter(id: 'salawat', name: 'الصلاة على النبي ﷺ').toJson()]),
        'active_counter_id': 'ghost',
      });
      final service = BackupService(storage: storage);

      final data = service.parseJsonBackup(await service.buildJsonBackup());

      expect(data.activeCounterId, 'salawat');
    });
  });
}