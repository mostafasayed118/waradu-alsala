import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salawat_app/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:salawat_app/models/adhkar_counter.dart';
import 'package:salawat_app/models/app_settings.dart';
import 'package:salawat_app/services/backup_service.dart';
import 'package:salawat_app/widgets/celebration_burst.dart';
import 'package:salawat_app/providers/counters_provider.dart';
import 'package:salawat_app/providers/settings_provider.dart';
import 'package:salawat_app/services/notification_service.dart';
import 'package:salawat_app/services/storage_service.dart';

const MethodChannel _notificationsChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');

class _FakeNotificationService extends NotificationService {
  bool permissionGranted = true;

  @override
  Future<bool> requestPermission() async => permissionGranted;
}

Future<void> pumpApp(
  WidgetTester tester, {
  NotificationService? notificationService,
}) async {
  final storageService = StorageService();
  await storageService.init();

  final notif = notificationService ?? NotificationService();
  AndroidFlutterLocalNotificationsPlugin.registerWith();
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, (MethodCall call) async {
      return call.method == 'initialize' ? true : null;
    });
  });

  testWidgets('Home screen displays the active counter', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('0'), findsOneWidget);
    expect(find.text('اضغط للعد'), findsOneWidget);
    expect(find.text('الصلاة على النبي ﷺ'), findsWidgets);
  });

  testWidgets('Increment button increases the counter', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.ensureVisible(find.text('اضغط للعد'));
    await tester.tap(find.text('اضغط للعد'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    await tester.ensureVisible(find.text('اضغط للعد'));
    await tester.tap(find.text('اضغط للعد'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Reset button shows a confirmation dialog', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.ensureVisible(find.text('إعادة تعيين'));
    await tester.tap(find.text('إعادة تعيين'));
    await tester.pumpAndSettle();

    expect(find.text('إعادة تعيين العداد'), findsOneWidget);
    expect(find.text('هل أنت متأكد من إعادة تعيين العداد؟'), findsOneWidget);
  });

  testWidgets('switches between counters', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'adhkar_counters': jsonEncode([
        AdhkarCounter(id: 'salawat', name: 'الصلاة على النبي ﷺ').toJson(),
        AdhkarCounter(
          id: 'tasbih',
          name: 'سبحان الله',
          currentCount: 99,
          totalCount: 99,
        ).toJson(),
      ]),
    });

    await pumpApp(tester);

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('سبحان الله'));
    await tester.pumpAndSettle();

    expect(find.text('99'), findsOneWidget);
  });

  testWidgets('reminder toggle shows snackbar when permission is denied',
      (WidgetTester tester) async {
    final notif = _FakeNotificationService()..permissionGranted = false;

    await pumpApp(tester, notificationService: notif);

    // Navigate to the settings screen.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Enable reminders for the active counter.
    await tester.tap(find.text('التذكيرات'));
    await tester.pumpAndSettle();

    // The snackbar is shown and the switch stays off.
    expect(find.text('لم يتم منح إذن الإشعارات'), findsOneWidget);
    final remindersSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'التذكيرات'),
    );
    expect(remindersSwitch.value, isFalse);
  });

  testWidgets('shows daily target progress', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'adhkar_counters': jsonEncode([
        AdhkarCounter(
          id: 'salawat',
          name: 'الصلاة على النبي ﷺ',
          currentCount: 40,
          totalCount: 40,
          dailyTarget: 100,
        ).toJson(),
      ]),
    });

    await pumpApp(tester);

    expect(find.text('40 / 100'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('reaching the daily target fires a notification',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'adhkar_counters': jsonEncode([
        AdhkarCounter(
          id: 'salawat',
          name: 'الصلاة على النبي ﷺ',
          dailyTarget: 1,
        ).toJson(),
      ]),
    });

    var showedNotification = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationsChannel, (MethodCall call) async {
      if (call.method == 'show') {
        showedNotification = true;
      }
      return call.method == 'initialize' ? true : null;
    });

    await pumpApp(tester);

    await tester.ensureVisible(find.text('اضغط للعد'));
    await tester.tap(find.text('اضغط للعد'));
    await tester.pumpAndSettle();

    expect(showedNotification, isTrue);
    expect(find.text('تم الهدف'), findsOneWidget);
  });

  testWidgets('stats screen shows chart, totals, and streaks',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'adhkar_counters': jsonEncode([
        AdhkarCounter(
          id: 'salawat',
          name: 'الصلاة على النبي ﷺ',
          currentCount: 3,
          totalCount: 100,
          dailyTarget: 5,
          history: {'2025-01-01': 5},
        ).toJson(),
      ]),
    });

    await pumpApp(tester);

    await tester.tap(find.text('الإحصائيات'));
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('الإجمالي الكلي'), findsOneWidget);
    expect(find.text('أفضل يوم'), findsOneWidget);
    expect(find.text('السلسلة الحالية'), findsOneWidget);
    expect(find.text('أطول سلسلة'), findsOneWidget);
  });

  testWidgets('stats period switcher supports 90 days',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('الإحصائيات'));
    await tester.pumpAndSettle();

    expect(find.text('آخر ٧ أيام'), findsOneWidget);

    await tester.tap(find.text('٩٠ يومًا'));
    await tester.pumpAndSettle();

    expect(find.text('آخر ٩٠ يومًا'), findsOneWidget);
  });

  testWidgets('full-screen mode hides chrome and counts taps anywhere',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.ensureVisible(find.text('ملء الشاشة'));
    await tester.tap(find.text('ملء الشاشة'));
    await tester.pumpAndSettle();

    // Normal chrome is hidden; immersive hint is shown.
    expect(find.text('بسم الله الرحمن الرحيم'), findsNothing);
    expect(find.text('اضغط في أي مكان للعد'), findsOneWidget);

    // Tapping the surface increments.
    await tester.tap(find.text('اضغط في أي مكان للعد'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    // Exiting restores normal chrome.
    await tester.tap(find.byTooltip('إنهاء ملء الشاشة'));
    await tester.pumpAndSettle();
    expect(find.text('بسم الله الرحمن الرحيم'), findsOneWidget);
  });

  testWidgets('English language preference translates the UI',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'app_settings': jsonEncode(AppSettings(languageCode: 'en').toJson()),
    });
    await pumpApp(tester);

    expect(find.text('Tap to count'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('الرئيسية'), findsNothing);

    // Stats tab is translated too.
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Lifetime total'), findsOneWidget);
  });

  testWidgets('reaching the target shows a celebration burst',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'adhkar_counters': jsonEncode([
        AdhkarCounter(
          id: 'salawat',
          name: 'الصلاة على النبي ﷺ',
          dailyTarget: 1,
        ).toJson(),
      ]),
    });

    await pumpApp(tester);

    await tester.ensureVisible(find.text('اضغط للعد'));
    await tester.tap(find.text('اضغط للعد'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CelebrationBurst), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CelebrationBurst), findsNothing);
  });

  testWidgets('app exposes BackupService and NotificationService providers',
      (WidgetTester tester) async {
    await pumpApp(tester);

    expect(
      tester.element(find.byType(MyApp)).read<BackupService>(),
      isA<BackupService>(),
    );
    expect(
      tester.element(find.byType(MyApp)).read<NotificationService>(),
      isA<NotificationService>(),
    );
  });
}




