import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:salawat_app/main.dart';
import 'package:salawat_app/providers/counter_provider.dart';
import 'package:salawat_app/providers/settings_provider.dart';
import 'package:salawat_app/services/storage_service.dart';
import 'package:salawat_app/services/notification_service.dart';

void main() {
  testWidgets('Home screen should display counter', (WidgetTester tester) async {
    // Initialize services
    final storageService = StorageService();
    await storageService.init();
    
    final notificationService = NotificationService();
    await notificationService.init();
    
    // Build the app
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
    
    // Wait for the app to load
    await tester.pumpAndSettle();
    
    // Verify the counter is displayed
    expect(find.text('0'), findsOneWidget);
    
    // Verify the increment button is present
    expect(find.text('صَلَّيْتُ عَلَى النَّبِي ﷺ'), findsOneWidget);
  });

  testWidgets('Increment button should increase counter', (WidgetTester tester) async {
    // Initialize services
    final storageService = StorageService();
    await storageService.init();
    
    final notificationService = NotificationService();
    await notificationService.init();
    
    // Build the app
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
    
    // Wait for the app to load
    await tester.pumpAndSettle();
    
    // Tap the increment button
    await tester.tap(find.text('صَلَّيْتُ عَلَى النَّبِي ﷺ'));
    await tester.pumpAndSettle();
    
    // Verify the counter increased
    expect(find.text('1'), findsOneWidget);
    
    // Tap again
    await tester.tap(find.text('صَلَّيْتُ عَلَى النَّبِي ﷺ'));
    await tester.pumpAndSettle();
    
    // Verify the counter increased again
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Reset button should show confirmation dialog', (WidgetTester tester) async {
    // Initialize services
    final storageService = StorageService();
    await storageService.init();
    
    final notificationService = NotificationService();
    await notificationService.init();
    
    // Build the app
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
    
    // Wait for the app to load
    await tester.pumpAndSettle();
    
    // Tap the reset button
    await tester.tap(find.text('إعادة تعيين'));
    await tester.pumpAndSettle();
    
    // Verify the confirmation dialog is shown
    expect(find.text('إعادة تعيين العداد'), findsOneWidget);
    expect(find.text('هل أنت متأكد من إعادة تعيين العداد؟'), findsOneWidget);
  });
}
