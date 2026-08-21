import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salawat_app/main.dart';
import 'package:salawat_app/providers/counters_provider.dart';
import 'package:salawat_app/providers/settings_provider.dart';
import 'package:salawat_app/services/backup_service.dart';
import 'package:share_plus/share_plus.dart';
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

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();
}

base class _FakePlatformFile extends PlatformFile {
  _FakePlatformFile(this.content);

  final Uint8List content;

  @override
  String get name => 'zikr-backup.json';

  @override
  Uri get uri => Uri.dataFromBytes(content, mimeType: 'application/json');

  @override
  XFile get xFile => XFile.fromData(content, name: name);

  @override
  Future<int> length() async => content.length;

  @override
  Future<Uint8List> readAsBytes() async => content;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(content);
}

class _FakeFilePickerPlatform extends FilePickerPlatform {
  _FakeFilePickerPlatform(this.files);

  final List<PlatformFile> files;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = true,
    bool withData = false,
    AndroidOptions androidOptions = const AndroidOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    return files;
  }
}

String backupJson({String name = 'الصلاة على النبي ﷺ', int count = 99}) {
  return jsonEncode({
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'activeCounterId': 'salawat',
    'settings': {'vibrationEnabled': false, 'isDarkMode': true},
    'counters': [
      {
        'id': 'salawat',
        'name': name,
        'currentCount': count,
        'totalCount': count,
        'dailyTarget': 0,
        'history': <String, int>{},
        'lastUsedAt': DateTime.now().toIso8601String(),
        'lastResetAt': null,
        'remindersEnabled': false,
        'reminderType': 0,
        'reminderIntervalMinutes': 60,
        'dailyReminderTimes': <int>[],
      },
    ],
  });
}

List<PlatformFile> pickerResult(String content) =>
    [_FakePlatformFile(utf8.encode(content))];

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
      if (call.method == 'share') {
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

  testWidgets('restore asks for confirmation, then replaces data',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'adhkar_counters': jsonEncode([
        {
          'id': 'old',
          'name': 'قديم',
          'currentCount': 5,
          'totalCount': 5,
          'dailyTarget': 0,
          'history': <String, int>{},
          'lastUsedAt': DateTime.now().toIso8601String(),
          'lastResetAt': null,
          'remindersEnabled': false,
          'reminderType': 0,
          'reminderIntervalMinutes': 60,
          'dailyReminderTimes': <int>[],
        },
      ]),
    });
    FilePickerPlatform.instance = _FakeFilePickerPlatform(pickerResult(backupJson()));
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await openSettings(tester);

    await tester.ensureVisible(find.text('استعادة نسخة احتياطية'));
    await tester.tap(find.text('استعادة نسخة احتياطية'));
    await tester.pumpAndSettle();

    expect(
      find.text('سيتم استبدال جميع البيانات الحالية. هل أنت متأكد؟'),
      findsOneWidget,
    );

    await tester.tap(find.text('استعادة'));
    await tester.pumpAndSettle();

    expect(find.text('تمت الاستعادة بنجاح'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('adhkar_counters')!) as List;
    expect(saved, hasLength(1));
    expect(saved.single['id'], 'salawat');
    expect(saved.single['currentCount'], 99);
  });

  testWidgets('restore accepts a UTF-8-BOM-prefixed backup file',
      (WidgetTester tester) async {
    FilePickerPlatform.instance = _FakeFilePickerPlatform(pickerResult('\uFEFF${backupJson()}'));
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await openSettings(tester);

    await tester.ensureVisible(find.text('استعادة نسخة احتياطية'));
    await tester.tap(find.text('استعادة نسخة احتياطية'));
    await tester.pumpAndSettle();

    expect(
      find.text('سيتم استبدال جميع البيانات الحالية. هل أنت متأكد؟'),
      findsOneWidget,
    );

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
  });

  testWidgets('cancelling the confirm dialog leaves data untouched',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'adhkar_counters': jsonEncode([
        {
          'id': 'old',
          'name': 'قديم',
          'currentCount': 5,
          'totalCount': 5,
          'dailyTarget': 0,
          'history': <String, int>{},
          'lastUsedAt': DateTime.now().toIso8601String(),
          'lastResetAt': null,
          'remindersEnabled': false,
          'reminderType': 0,
          'reminderIntervalMinutes': 60,
          'dailyReminderTimes': <int>[],
        },
      ]),
    });
    FilePickerPlatform.instance = _FakeFilePickerPlatform(pickerResult(backupJson()));
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await openSettings(tester);

    await tester.ensureVisible(find.text('استعادة نسخة احتياطية'));
    await tester.tap(find.text('استعادة نسخة احتياطية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(find.text('تمت الاستعادة بنجاح'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('adhkar_counters')!) as List;
    expect(saved, hasLength(1));
    expect(saved.single['id'], 'old');
  });

  testWidgets('invalid backup file shows an error and no dialog',
      (WidgetTester tester) async {
    FilePickerPlatform.instance = _FakeFilePickerPlatform(pickerResult('not json'));
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await openSettings(tester);

    await tester.ensureVisible(find.text('استعادة نسخة احتياطية'));
    await tester.tap(find.text('استعادة نسخة احتياطية'));
    await tester.pumpAndSettle();

    expect(find.text('ملف النسخة الاحتياطية غير صالح'), findsOneWidget);
    expect(
      find.text('سيتم استبدال جميع البيانات الحالية. هل أنت متأكد؟'),
      findsNothing,
    );
  });
}





