import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/models/app_settings.dart';
import 'package:salawat_app/providers/settings_provider.dart';
import 'package:salawat_app/services/storage_service.dart';

class _FakeStorageService extends StorageService {
  _FakeStorageService(this.stored);

  AppSettings stored;

  @override
  Future<AppSettings> getSettings() async => stored;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    stored = settings;
  }
}

void main() {
  test('toggleVibration updates and persists the setting', () async {
    final storage = _FakeStorageService(AppSettings(vibrationEnabled: true));
    final provider = SettingsProvider(storage);
    await provider.load();

    await provider.toggleVibration(false);

    expect(provider.settings.vibrationEnabled, isFalse);
    expect(storage.stored.vibrationEnabled, isFalse);
  });

  test('toggleDarkMode updates and persists the setting', () async {
    final storage = _FakeStorageService(AppSettings(isDarkMode: false));
    final provider = SettingsProvider(storage);
    await provider.load();

    await provider.toggleDarkMode(true);

    expect(provider.settings.isDarkMode, isTrue);
    expect(storage.stored.isDarkMode, isTrue);
  });

  test('toggleSound updates and persists the setting', () async {
    final storage = _FakeStorageService(AppSettings(soundEnabled: false));
    final provider = SettingsProvider(storage);
    await provider.load();

    await provider.toggleSound(true);

    expect(provider.settings.soundEnabled, isTrue);
    expect(storage.stored.soundEnabled, isTrue);
  });
}
