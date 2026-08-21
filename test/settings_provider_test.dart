import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/domain/entities/app_settings.dart';
import 'package:salawat_app/domain/repositories/settings_repository.dart';
import 'package:salawat_app/features/settings/settings_provider.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.stored);

  AppSettings stored;

  @override
  Future<AppSettings> getSettings() async => stored;

  @override
  Future<AppSettings> saveSettings(AppSettings settings) async {
    stored = settings;
    return settings;
  }
}

void main() {
  test('toggleVibration updates and persists the setting', () async {
    final storage = _FakeSettingsRepository(AppSettings(vibrationEnabled: true));
    final provider = SettingsProvider(settingsRepository: storage);
    await provider.load();

    await provider.toggleVibration(false);

    expect(provider.settings.vibrationEnabled, isFalse);
    expect(storage.stored.vibrationEnabled, isFalse);
  });

  test('toggleDarkMode updates and persists the setting', () async {
    final storage = _FakeSettingsRepository(AppSettings(isDarkMode: false));
    final provider = SettingsProvider(settingsRepository: storage);
    await provider.load();

    await provider.toggleDarkMode(true);

    expect(provider.settings.isDarkMode, isTrue);
    expect(storage.stored.isDarkMode, isTrue);
  });

  test('toggleSound updates and persists the setting', () async {
    final storage = _FakeSettingsRepository(AppSettings(soundEnabled: false));
    final provider = SettingsProvider(settingsRepository: storage);
    await provider.load();

    await provider.toggleSound(true);

    expect(provider.settings.soundEnabled, isTrue);
    expect(storage.stored.soundEnabled, isTrue);
  });
}
