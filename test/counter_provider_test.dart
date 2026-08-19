import 'package:flutter_test/flutter_test.dart';
import 'package:salawat_app/models/counter_data.dart';
import 'package:salawat_app/providers/counter_provider.dart';
import 'package:salawat_app/services/storage_service.dart';

class _FakeStorageService extends StorageService {
  CounterData stored = CounterData();

  @override
  Future<CounterData> getCounterData() async => stored;

  @override
  Future<void> saveCounterData(CounterData data) async {
    stored = data;
  }
}

void main() {
  group('CounterProvider.reset', () {
    test('reset() zeroes current count but preserves total', () async {
      final storage = _FakeStorageService()
        ..stored = CounterData(currentCount: 42, totalCount: 100);
      final provider = CounterProvider(storage);
      await provider.load();

      await provider.reset();

      expect(provider.currentCount, 0);
      expect(provider.totalCount, 100);
    });

    test('reset(includeTotal: true) zeroes both counts', () async {
      final storage = _FakeStorageService()
        ..stored = CounterData(currentCount: 42, totalCount: 100);
      final provider = CounterProvider(storage);
      await provider.load();

      await provider.reset(includeTotal: true);

      expect(provider.currentCount, 0);
      expect(provider.totalCount, 0);
    });

    test('reset() clears the undo stack', () async {
      final storage = _FakeStorageService()
        ..stored = CounterData(currentCount: 0, totalCount: 0);
      final provider = CounterProvider(storage);
      await provider.load();
      await provider.increment();
      expect(provider.canUndo, isTrue);

      await provider.reset();

      expect(provider.canUndo, isFalse);
    });
  });
}
