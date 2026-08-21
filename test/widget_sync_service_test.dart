import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/models/adhkar_counter.dart';
import 'package:salawat_app/services/widget_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  final methods = <String>[];
  dynamic lastSaveArgs;
  var updateCalls = 0;

  setUp(() {
    methods.clear();
    lastSaveArgs = null;
    updateCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      methods.add(call.method);
      if (call.method == 'saveWidgetData') lastSaveArgs = call.arguments;
      if (call.method == 'updateWidget') updateCalls++;
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('sync coalesces rapid updates into one widget push', () async {
    final service = WidgetSyncService();
    service.sync(AdhkarCounter(id: 'a', name: 'A'));
    service.sync(AdhkarCounter(id: 'a', name: 'A', currentCount: 4));

    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(methods, containsAll(['saveWidgetData', 'updateWidget']));
    expect(updateCalls, 1);
    service.dispose();
  });

  test('flush pushes pending state immediately', () async {
    final service = WidgetSyncService();
    service.sync(AdhkarCounter(id: 'a', name: 'A', currentCount: 9));

    await service.flush();

    expect(updateCalls, 1);
    expect(lastSaveArgs['id'], anyOf('counter_name', 'counter_count'));
    service.dispose();
  });

  test('background callback ignores foreign uris without touching storage',
      () async {
    // Must complete without throwing even though no plugin is registered.
    await widgetBackgroundCallback(Uri.parse('salawatwidget://open'));
    expect(methods, isEmpty);
  });
}
