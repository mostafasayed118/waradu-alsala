import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
