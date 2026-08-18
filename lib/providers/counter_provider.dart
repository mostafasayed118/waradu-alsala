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

  Future<void> load() async {
    _counterData = await _storage.getCounterData();
    notifyListeners();
  }

  Future<void> increment() async {
    _lastCount = _counterData.currentCount;
    _counterData = _counterData.copyWith(
      currentCount: _counterData.currentCount + 1,
      totalCount: _counterData.totalCount + 1,
      lastUsedAt: DateTime.now(),
    );
    await _storage.saveCounterData(_counterData);
    notifyListeners();
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

  Future<void> reset() async {
    _counterData = CounterData(
      currentCount: 0,
      totalCount: _counterData.totalCount,
      lastUsedAt: DateTime.now(),
      lastResetAt: DateTime.now(),
    );
    _lastCount = null;
    await _storage.saveCounterData(_counterData);
    notifyListeners();
  }

  Future<void> resetTotal() async {
    _counterData = CounterData(
      currentCount: _counterData.currentCount,
      totalCount: 0,
      lastUsedAt: DateTime.now(),
      lastResetAt: DateTime.now(),
    );
    _lastCount = null;
    await _storage.saveCounterData(_counterData);
    notifyListeners();
  }
}
