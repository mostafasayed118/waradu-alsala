import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:salawat_app/features/counting/counters_provider.dart';
import 'package:salawat_app/features/settings/settings_provider.dart';
import 'package:salawat_app/data/storage_service.dart';
import 'package:salawat_app/data/notifications/notification_service.dart';
import 'package:salawat_app/data/backup_service.dart';
import 'package:salawat_app/data/widget/widget_sync_service.dart';
import 'package:salawat_app/features/counting/screens/home_screen.dart';
import 'package:salawat_app/features/library/library_screen.dart';
import 'package:salawat_app/features/settings/settings_screen.dart';
import 'package:salawat_app/features/stats/stats_screen.dart';
import 'package:salawat_app/core/theme/app_theme.dart';
import 'package:salawat_app/core/l10n/app_strings.dart';
import 'package:salawat_app/features/shell/decorative_app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final notificationService = NotificationService();
  // Timezone DB load is slow; don't block the first frame on it. The service
  // gates its own methods until init completes.
  unawaited(notificationService.init());

  // Widget tap-to-count runs in a background isolate.
  unawaited(HomeWidget.registerInteractivityCallback(widgetBackgroundCallback));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              CountersProvider(storageService, notificationService)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService)..load(),
        ),
        Provider<NotificationService>.value(value: notificationService),
        Provider<BackupService>.value(
          value: BackupService(storage: storageService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final WidgetSyncService _widgetSync = WidgetSyncService();
  VoidCallback? _countersListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final counters = context.read<CountersProvider>();
      _countersListener = () => _widgetSync.sync(counters.activeCounter);
      counters.addListener(_countersListener!);
      _widgetSync.sync(counters.activeCounter);
    });
  }

  @override
  void dispose() {
    final listener = _countersListener;
    if (listener != null) {
      // Provider may already be disposed during teardown; ignore errors.
      try {
        context.read<CountersProvider>().removeListener(listener);
      } catch (_) {}
    }
    _widgetSync.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final counters = context.read<CountersProvider>();
    if (state == AppLifecycleState.resumed) {
      counters.rolloverIfNewDay();
      // Refresh the rolling prayer-reminder window (solar times drift daily).
      final settings = context.read<SettingsProvider>();
      unawaited(context
          .read<NotificationService>()
          .rescheduleAll(counters.counters, settings: settings.settings));
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Persist debounced counter changes before backgrounding.
      unawaited(counters.flushPendingSave());
      unawaited(_widgetSync.flush());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final lang = settings.settings.languageCode;
        final locale = switch (lang) {
          'ar' => const Locale('ar', 'SA'),
          'en' => const Locale('en'),
          _ => null, // follow the platform
        };
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,

          // RTL support
          locale: locale,
          supportedLocales: const [
            Locale('ar', 'SA'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Theme
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // Decorative shell with 4-tab navigation
          home: const DecorativeAppShell(
            screens: [
              HomeScreen(),
              LibraryScreen(),
              StatsScreen(),
              SettingsScreen(),
            ],
          ),
        );
      },
    );
  }
}

