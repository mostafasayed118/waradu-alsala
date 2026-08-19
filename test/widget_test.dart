import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salawat_app/main.dart';
import 'package:salawat_app/models/app_settings.dart';
import 'package:salawat_app/providers/counter_provider.dart';
import 'package:salawat_app/providers/settings_provider.dart';
import 'package:salawat_app/services/notification_service.dart';
import 'package:salawat_app/services/storage_service.dart';

const MethodChannel _notificationsChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');

Future<void> pumpApp(WidgetTester tester) async {
  final storageService = StorageService();
  await storageService.init();

  final notificationService = NotificationService();
  await notificationService.init();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CounterProvider(storageService)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService, notificationService)..load(),
        ),
      ],
      child: const MyApp(),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, (MethodCall call) async {
      return call.method == 'initialize' ? true : null;
    });
  });

  testWidgets('Home screen should display counter', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('0'), findsOneWidget);
    expect(find.text('صَلَّيْتُ عَلَى النَّبِي ﷺ'), findsOneWidget);
  });

  testWidgets('Increment button should increase counter', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('صَلَّيْتُ عَلَى النَّبِي ﷺ'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('صَلَّيْتُ عَلَى النَّبِي ﷺ'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Reset button should show confirmation dialog', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('إعادة تعيين'));
    await tester.pumpAndSettle();

    expect(find.text('إعادة تعيين العداد'), findsOneWidget);
    expect(find.text('هل أنت متأكد من إعادة تعيين العداد؟'), findsOneWidget);
  });

  testWidgets('notifications toggle shows snackbar when permission is denied',
      (WidgetTester tester) async {
    // Start with notifications disabled so the switch is off.
    SharedPreferences.setMockInitialValues({
      'app_settings': jsonEncode(AppSettings(notificationsEnabled: false).toJson()),
    });

    // Deny the notification permission.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, (MethodCall call) async {
      if (call.method == 'requestNotificationsPermission') {
        return false;
      }
      return call.method == 'initialize' ? true : null;
    });

    await pumpApp(tester);

    // Navigate to the settings screen.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Enable notifications.
    await tester.tap(find.text('تفعيل الإشعارات'));
    await tester.pumpAndSettle();

    // The snackbar is shown and the switch stays off.
    expect(find.text('لم يتم منح إذن الإشعارات'), findsOneWidget);
    final notificationsSwitch =
        tester.widget<SwitchListTile>(find.byType(SwitchListTile).first);
    expect(notificationsSwitch.value, isFalse);
  });
}
