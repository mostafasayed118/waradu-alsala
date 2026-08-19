import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/models/adhkar_counter.dart';
import 'package:salawat_app/services/notification_service.dart';

const MethodChannel _channel =
    MethodChannel('dexterous.com/flutter/local_notifications');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each NotificationService instance initializes independently', () async {
    var initializeCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
      if (call.method == 'initialize') {
        initializeCalls++;
      }
      return call.method == 'initialize' ? true : null;
    });

    final first = NotificationService();
    await first.init();
    expect(initializeCalls, 1);

    // A second instance must not inherit the first's `_initialized` state.
    final second = NotificationService();
    await second.init();
    expect(initializeCalls, 2);
  });

  test('rescheduleAll schedules only enabled counters', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
      calls.add(call.method);
      return call.method == 'initialize' ? true : null;
    });

    final service = NotificationService();
    await service.init();

    await service.rescheduleAll([
      AdhkarCounter(id: 'a', name: 'A', remindersEnabled: true),
      AdhkarCounter(id: 'b', name: 'B', remindersEnabled: false),
    ]);

    expect(calls.where((c) => c == 'zonedSchedule').length, 1);
    expect(calls, contains('cancelAll'));
  });
}
