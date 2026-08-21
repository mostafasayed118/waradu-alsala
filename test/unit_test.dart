import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/domain/entities/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('creates with default values', () {
      final settings = AppSettings();
      expect(settings.vibrationEnabled, isTrue);
      expect(settings.isDarkMode, isFalse);
    });

    test('creates with custom values', () {
      final settings = AppSettings(vibrationEnabled: false, isDarkMode: true);
      expect(settings.vibrationEnabled, isFalse);
      expect(settings.isDarkMode, isTrue);
    });

    test('copies with new values', () {
      final settings = AppSettings();
      final newSettings = settings.copyWith(vibrationEnabled: false);
      expect(newSettings.vibrationEnabled, isFalse);
      expect(settings.vibrationEnabled, isTrue); // Original unchanged
    });

    test('converts to JSON and back', () {
      final settings = AppSettings(vibrationEnabled: false, isDarkMode: true);

      final json = settings.toJson();
      expect(json['vibrationEnabled'], isFalse);
      expect(json['isDarkMode'], isTrue);

      final restored = AppSettings.fromJson(json);
      expect(restored.vibrationEnabled, isFalse);
      expect(restored.isDarkMode, isTrue);
    });

    test('ignores unknown legacy keys', () {
      final restored = AppSettings.fromJson({
        'notificationsEnabled': false,
        'dailyTarget': 100,
        'dailyCounter': true,
        'vibrationEnabled': false,
        'isDarkMode': true,
      });

      expect(restored.vibrationEnabled, isFalse);
      expect(restored.isDarkMode, isTrue);
    });
  });
}
