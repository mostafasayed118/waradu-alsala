import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salawat_app/providers/counters_provider.dart';
import 'package:salawat_app/screens/home_screen.dart';
import 'package:salawat_app/screens/library_screen.dart';
import 'package:salawat_app/services/notification_service.dart';
import 'package:salawat_app/services/storage_service.dart';
import 'package:salawat_app/widgets/decorative_app_shell.dart';

class _FakeNotificationService extends NotificationService {}

Future<void> _pumpShell(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});

  final storage = StorageService();
  await storage.init();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              CountersProvider(storage, _FakeNotificationService())..load(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('ar', 'SA'),
        supportedLocales: const [Locale('ar', 'SA'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const DecorativeAppShell(
          screens: [HomeScreen(), LibraryScreen()],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tapping a dhikr creates its counter and jumps to home',
      (tester) async {
    await _pumpShell(tester);

    // Switch to the library tab first (IndexedStack keeps it offstage).
    await tester.tap(find.text('الأذكار'));
    await tester.pumpAndSettle();

    // Library tab shows the curated sections.
    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('أذكار المساء'), findsOneWidget);
    expect(find.text('أذكار عامة'), findsOneWidget);

    // Tap a dhikr card.
    await tester.ensureVisible(find.text('سبحان الله وبحمده').first);
    await tester.tap(find.text('سبحان الله وبحمده').first);
    await tester.pumpAndSettle();

    // Shell switched to the home tab and the new counter is active.
    final counters =
        tester.element(find.byType(HomeScreen)).read<CountersProvider>();
    expect(counters.activeCounter.name, 'سبحان الله وبحمده');
    expect(counters.counters.length, 6); // 5 presets + 1 from library
  });

  testWidgets('tapping the same dhikr twice does not duplicate',
      (tester) async {
    await _pumpShell(tester);

    // Switch to the library tab.
    await tester.tap(find.text('الأذكار'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('سبحان الله وبحمده').first);
    await tester.tap(find.text('سبحان الله وبحمده').first);
    await tester.pumpAndSettle();

    // Back to library via nav pill, then count it again.
    await tester.tap(find.text('الأذكار'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('سبحان الله وبحمده').first);
    await tester.tap(find.text('سبحان الله وبحمده').first);
    await tester.pumpAndSettle();

    final counters =
        tester.element(find.byType(HomeScreen)).read<CountersProvider>();
    expect(counters.counters.length, 6);
  });
}
