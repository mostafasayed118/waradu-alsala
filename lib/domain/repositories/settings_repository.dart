import 'package:salawat_app/domain/entities/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<AppSettings> saveSettings(AppSettings settings);
}
