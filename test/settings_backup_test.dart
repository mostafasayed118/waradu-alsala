import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salawat_app/main.dart';
import 'package:salawat_app/providers/counters_provider.dart';
import 'package:salawat_app/providers/settings_provider.dart';
import 'package:salawat_app/services/backup_service.dart';
import 'package:salawat_app/services/notification_service.dart';
import 'package:salawat_app/services/storage_service.dart';

const MethodChannel _notificationsChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');
const MethodChannel _shareChannel =
    MethodChannel('dev.fluttercommunity.plus/share');
const MethodChannel _pathProviderChannel =
    MethodChannel('plugins.flutter.io/path_provider');

Future<void> pumpApp(WidgetTester tester) async {
  final storageService = StorageService();
  await storageService.init();

  final notif = NotificationService();
  await notif.init();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CountersProvider(storageService, notif)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService)..load(),
        ),
        Provider<NotificationService>.value(value: notif),
        Provider<BackupService>.value(
          value: BackupService(storage: storageService),
        ),
      ],
      child: const MyApp(),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings));
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (MethodCall call) async {
      return Directory.systemTemp.path;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, (MethodCall call) async {
      return {'status': 'success'};
    });
  });

  testWidgets('export tile opens a sheet with JSON and CSV options',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await openSettings(tester);

    await tester.ensureVisible(find.text('تصدير البيانات'));
    await tester.tap(find.text('تصدير البيانات'));
    await tester.pumpAndSettle();

    expect(find.text('نسخة احتياطية كاملة (JSON)'), findsOneWidget);
    expect(find.text('ملف CSV (لبرامج الجداول)'), findsOneWidget);
  });

  testWidgets('sharing the JSON export calls the share channel with a .json file',
      (WidgetTester tester) async {
    final sharedPaths = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, (MethodCall call) async {
      if (call.method == 'shareFiles') {
        final args = call.arguments as Map<dynamic, dynamic>;
        sharedPaths.addAll((args['paths'] as List).cast<String>());
      }
      return {'status': 'success'};
    });

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await openSettings(tester);

    await tester.ensureVisible(find.text('تصدير البيانات'));
    await tester.tap(find.text('تصدير البيانات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('نسخة احتياطية كاملة (JSON)'));
    await tester.pumpAndSettle();

    expect(sharedPaths, hasLength(1));
    expect(sharedPaths.single, endsWith('.json'));
  });
}