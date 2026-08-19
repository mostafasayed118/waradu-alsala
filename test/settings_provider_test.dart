import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/models/app_settings.dart';
import 'package:salawat_app/providers/settings_provider.dart';
import 'package:salawat_app/services/notification_service.dart';
import 'package:salawat_app/services/storage_service.dart';

const MethodChannel _channel =
    MethodChannel('dexterous.com/flutter/local_notifications');

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

Future<SettingsProvider> _buildProvider({
  required bool permissionGranted,
  bool notificationsEnabled = false,
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (MethodCall call) async {
    switch (call.method) {
      case 'initialize':
        return true;
      case 'requestNotificationsPermission':
        return permissionGranted;
      default:
        return null;
    }
  });

  final notificationService = NotificationService();
  await notificationService.init();

  final provider = SettingsProvider(
    _FakeStorageService(AppSettings(notificationsEnabled: notificationsEnabled)),
    notificationService,
  );
  await provider.load();
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('enables notifications when permission is granted', () async {
    final provider = await _buildProvider(permissionGranted: true);

    final result = await provider.toggleNotifications(true);

    expect(result, isTrue);
    expect(provider.settings.notificationsEnabled, isTrue);
  });

  test('keeps notifications disabled when permission is denied', () async {
    final provider = await _buildProvider(permissionGranted: false);

    final result = await provider.toggleNotifications(true);

    expect(result, isFalse);
    expect(provider.settings.notificationsEnabled, isFalse);
  });

  test('disables notifications without requesting permission', () async {
    final provider = await _buildProvider(
      permissionGranted: false,
      notificationsEnabled: true,
    );

    final result = await provider.toggleNotifications(false);

    expect(result, isTrue);
    expect(provider.settings.notificationsEnabled, isFalse);
  });

  test('setDailyTarget updates the stored setting', () async {
    final provider = await _buildProvider(permissionGranted: true);

    await provider.setDailyTarget(100);

    expect(provider.settings.dailyTarget, 100);
  });

  group('notifyDailyTargetReached', () {
    Future<(SettingsProvider, List<MethodCall>)> buildNotifier({
      required bool notificationsEnabled,
    }) async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (MethodCall call) async {
        calls.add(call);
        return call.method == 'initialize' ? true : null;
      });

      final notificationService = NotificationService();
      await notificationService.init();

      final provider = SettingsProvider(
        _FakeStorageService(
          AppSettings(notificationsEnabled: notificationsEnabled),
        ),
        notificationService,
      );
      await provider.load();
      return (provider, calls);
    }

    test('fires the notification when enabled', () async {
      final (provider, calls) = await buildNotifier(notificationsEnabled: true);

      await provider.notifyDailyTargetReached();

      expect(calls.any((c) => c.method == 'show'), isTrue);
    });

    test('skips the notification when disabled', () async {
      final (provider, calls) = await buildNotifier(notificationsEnabled: false);

      await provider.notifyDailyTargetReached();

      expect(calls.any((c) => c.method == 'show'), isFalse);
    });
  });
}
