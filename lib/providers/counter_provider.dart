import 'package:flutter/foundation.dart';
import '../models/counter_data.dart';
import '../services/storage_service.dart';

class CounterProvider with ChangeNotifier {
  final StorageService _storage;
  CounterData _counterData = CounterData();
  int? _lastCount;

  CounterProvider(this._storage);

  CounterData get counterData => _counterData;
  int get currentCount => _counterData.currentCount;
  int get totalCount => _counterData.totalCount;
  bool get canUndo => _lastCount != null;

  Future<void> load({bool daily = false}) async {
    _counterData = await _storage.getCounterData();
    if (daily) {
      await rolloverIfNewDay();
    }
    notifyListeners();
  }

  Future<void> increment({bool daily = false}) async {
    if (daily) {
      await rolloverIfNewDay();
    }
    _lastCount = _counterData.currentCount;
    _counterData = _counterData.copyWith(
      currentCount: _counterData.currentCount + 1,
      totalCount: _counterData.totalCount + 1,
      lastUsedAt: DateTime.now(),
    );
    await _storage.saveCounterData(_counterData);
    notifyListeners();
  }

  /// Resets [currentCount] to zero (keeping the total) when the last activity
  /// happened on a previous day. Returns whether a rollover occurred.
  Future<bool> rolloverIfNewDay() async {
    if (!_isNewDay(_counterData.lastUsedAt)) return false;
    _counterData = _counterData.copyWith(
      currentCount: 0,
      lastUsedAt: DateTime.now(),
      lastResetAt: DateTime.now(),
    );
    await _storage.saveCounterData(_counterData);
    notifyListeners();
    return true;
  }

  bool _isNewDay(DateTime lastUsedAt) {
    final now = DateTime.now();
    return lastUsedAt.year != now.year ||
        lastUsedAt.month != now.month ||
        lastUsedAt.day != now.day;
  }

  Future<void> undo() async {
    if (_lastCount == null) return;

    _counterData = _counterData.copyWith(
      currentCount: _lastCount!,
      lastUsedAt: DateTime.now(),
    );
    _lastCount = null;
    await _storage.saveCounterData(_counterData);
    notifyListeners();
  }

  Future<void> reset({bool includeTotal = false}) async {
    _counterData = _counterData.copyWith(
      currentCount: 0,
      totalCount: includeTotal ? 0 : _counterData.totalCount,
      lastUsedAt: DateTime.now(),
      lastResetAt: DateTime.now(),
    );
    _lastCount = null;
    await _storage.saveCounterData(_counterData);
    notifyListeners();
  }
}
