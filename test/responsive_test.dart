import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salawat_app/models/adhkar_counter.dart';
import 'package:salawat_app/providers/counters_provider.dart';
import 'package:salawat_app/providers/settings_provider.dart';
import 'package:salawat_app/screens/home_screen.dart';
import 'package:salawat_app/screens/settings_screen.dart';
import 'package:salawat_app/screens/stats_screen.dart';
import 'package:salawat_app/services/backup_service.dart';
import 'package:salawat_app/services/notification_service.dart';
import 'package:salawat_app/services/storage_service.dart';
import 'package:salawat_app/utils/app_text_styles.dart';
import 'package:salawat_app/utils/breakpoints.dart';
import 'package:salawat_app/widgets/decorative_app_shell.dart';

const MethodChannel _respNotificationsChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');

void main() {
  group('Breakpoints', () {
    test('classifies widths into the four buckets', () {
      expect(Breakpoints.isCompact(320), isTrue);
      expect(Breakpoints.isCompact(400), isTrue);
      expect(Breakpoints.isMedium(500), isTrue);
      expect(Breakpoints.isMedium(600), isTrue);
      expect(Breakpoints.isExpanded(700), isTrue);
      expect(Breakpoints.isExpanded(840), isTrue);
      expect(Breakpoints.isWide(841), isTrue);
    });

    test('useTwoPane is true at and above 840', () {
      expect(Breakpoints.useTwoPane(839), isFalse);
      expect(Breakpoints.useTwoPane(840), isTrue);
      expect(Breakpoints.useTwoPane(1200), isTrue);
    });
  });

  testWidgets('MaxWidthBox caps and centers child on wide screens',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaxWidthBox(
            maxWidth: 200,
            child: const SizedBox(width: double.infinity, height: 50),
          ),
        ),
      ),
    );
    await tester.pump();

    final box = tester.widget<ConstrainedBox>(
        find.descendant(of: find.byType(MaxWidthBox), matching: find.byType(ConstrainedBox)));
    expect(box.constraints.maxWidth, 200);
    expect(find.byType(Center), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('AppTextStyles width scaling', () {
    /// Pumps a MaterialApp whose body captures the kufiNumber style for the
    /// current view size, returns its fontSize.
    Future<double> kufiFontSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      double? fontSize;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              fontSize = AppTextStyles.kufiNumber(context).fontSize;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
      return fontSize!;
    }

    testWidgets('kufiNumber scales up from compact to wide', (tester) async {
      final compact = await kufiFontSize(tester, const Size(360, 640));
      final wide = await kufiFontSize(tester, const Size(1200, 800));

      expect(compact, lessThan(wide));
      // compact factor 0.82 of 88 ≈ 72.16; wide factor 1.18 of 88 ≈ 103.84
      expect(compact, closeTo(72.16, 0.5));
      expect(wide, closeTo(103.84, 0.5));
    });
  });

  testWidgets('Home renders without overflow at 320dp width', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_respNotificationsChannel,
            (MethodCall call) async {
      return call.method == 'initialize' ? true : null;
    });
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final notif = NotificationService();
    await notif.init();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => CountersProvider(storage, notif)..load()),
          ChangeNotifierProvider(
              create: (_) => SettingsProvider(storage)..load()),
          Provider<NotificationService>.value(value: notif),
          Provider<BackupService>.value(value: BackupService(storage: storage)),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('اضغط للعد'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Home count should be inside a FittedBox to prevent overflow
    expect(find.byType(FittedBox), findsWidgets);
  });

  testWidgets('Settings centers content at tablet width', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_respNotificationsChannel,
            (MethodCall call) async {
      return call.method == 'initialize' ? true : null;
    });
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();
    final notif = NotificationService();
    await notif.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) => CountersProvider(storage, notif)..load()),
          ChangeNotifierProvider(
              create: (_) => SettingsProvider(storage)..load()),
          Provider<NotificationService>.value(value: notif),
          Provider<BackupService>.value(value: BackupService(storage: storage)),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    // At 1200dp, the list content is capped at settingsMaxWidth (560) and centered.
    final constrained =
        tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
    expect(constrained, isNotEmpty);
    // Check that at least one ConstrainedBox has maxWidth 560
    expect(
        constrained.any((c) => c.constraints.maxWidth == Breakpoints.settingsMaxWidth),
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Stats renders two-pane layout at tablet width', (tester) async {
    await _pumpStats(tester, size: const Size(1200, 800), dailyTarget: 5);

    // Two-pane: chart and tiles sit side by side under a keyed container.
    expect(find.byKey(StatsScreen.twoPaneKey), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    // Every label still renders in two-pane.
    expect(find.text('الإجمالي الكلي'), findsOneWidget);
    expect(find.text('أفضل يوم'), findsOneWidget);
    expect(find.text('السلسلة الحالية'), findsOneWidget);
    expect(find.text('أطول سلسلة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Stats renders single column at phone width', (tester) async {
    await _pumpStats(tester, size: const Size(400, 800), dailyTarget: 5);

    expect(find.byKey(StatsScreen.twoPaneKey), findsNothing);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('الإجمالي الكلي'), findsOneWidget);
    expect(find.text('أفضل يوم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Stats chart height scales with width', (tester) async {
    await _pumpStats(tester, size: const Size(320, 800), dailyTarget: 0);
    expect(StatsScreen.chartHeightFor(320), 180);
    expect(StatsScreen.chartHeightFor(500), 220);
    expect(StatsScreen.chartHeightFor(800), 260);
  });
}

/// Pumps StatsScreen at a fixed surface size with one seeded counter.
Future<void> _pumpStats(
  WidgetTester tester, {
  required Size size,
  required int dailyTarget,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_respNotificationsChannel,
          (MethodCall call) async {
    return call.method == 'initialize' ? true : null;
  });
  SharedPreferences.setMockInitialValues({
    'adhkar_counters': jsonEncode([
      AdhkarCounter(
        id: 'salawat',
        name: 'الصلاة على النبي ﷺ',
        currentCount: 3,
        totalCount: 100,
        dailyTarget: dailyTarget,
        history: const {'2025-01-01': 5},
      ).toJson(),
    ]),
  });
  final storage = StorageService();
  await storage.init();
  final notif = NotificationService();
  await notif.init();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => CountersProvider(storage, notif)..load()),
        ChangeNotifierProvider(
            create: (_) => SettingsProvider(storage)..load()),
        Provider<NotificationService>.value(value: notif),
        Provider<BackupService>.value(value: BackupService(storage: storage)),
      ],
      child: const MaterialApp(home: Scaffold(body: StatsScreen())),
    ),
  );
  await tester.pumpAndSettle();
}
