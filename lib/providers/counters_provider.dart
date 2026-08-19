import 'package:flutter/foundation.dart';
import '../models/adhkar_counter.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/stats.dart';

class CountersProvider with ChangeNotifier {
  final StorageService _storage;
  final NotificationService _notificationService;

  List<AdhkarCounter> _counters = [];
  String _activeId = '';
  int? _lastCount;

  static final AdhkarCounter _empty = AdhkarCounter(id: '', name: '');

  CountersProvider(this._storage, this._notificationService);

  List<AdhkarCounter> get counters => List.unmodifiable(_counters);

  AdhkarCounter get activeCounter {
    final matches = _counters.where((c) => c.id == _activeId);
    if (matches.isNotEmpty) return matches.first;
    if (_counters.isNotEmpty) return _counters.first;
    return _empty;
  }

  bool get canUndo => _lastCount != null;

  Future<void> load() async {
    _counters = List.of(await _storage.getCounters());
    if (_activeId.isEmpty || !_counters.any((c) => c.id == _activeId)) {
      _activeId = _counters.isEmpty ? '' : _counters.first.id;
    }
    await _rolloverAll();
    notifyListeners();
  }

  void setActive(String id) {
    if (_activeId == id) return;
    _activeId = id;
    _lastCount = null;
    notifyListeners();
  }

  Future<void> increment() async {
    final active = activeCounter;
    final rolled = _rolloverIfNeeded(active);
    _lastCount = rolled.currentCount;
    _replace(
      active.id,
      rolled.copyWith(
        currentCount: rolled.currentCount + 1,
        totalCount: rolled.totalCount + 1,
        lastUsedAt: DateTime.now(),
      ),
    );
    await _persist();
    notifyListeners();
  }

  Future<void> undo() async {
    if (_lastCount == null) return;
    final active = activeCounter;
    _replace(
      active.id,
      active.copyWith(currentCount: _lastCount!, lastUsedAt: DateTime.now()),
    );
    _lastCount = null;
    await _persist();
    notifyListeners();
  }

  Future<void> reset({bool includeTotal = false}) async {
    final active = activeCounter;
    _replace(
      active.id,
      active.copyWith(
        currentCount: 0,
        totalCount: includeTotal ? 0 : active.totalCount,
        lastUsedAt: DateTime.now(),
        lastResetAt: DateTime.now(),
      ),
    );
    _lastCount = null;
    await _persist();
    notifyListeners();
  }

  Future<void> addCounter(String name) async {
    final counter = AdhkarCounter(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
    );
    _counters = [..._counters, counter];
    _activeId = counter.id;
    _lastCount = null;
    await _persist();
    notifyListeners();
  }

  Future<void> renameCounter(String id, String name) =>
      _updateCounter(id, (c) => c.copyWith(name: name));

  Future<void> deleteCounter(String id) async {
    final index = _counters.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _counters = List.of(_counters)..removeAt(index);
    if (_activeId == id) {
      _activeId = _counters.isEmpty ? '' : _counters.first.id;
    }
    _lastCount = null;
    await _persist();
    await _reschedule();
    notifyListeners();
  }

  Future<void> setDailyTarget(String id, int value) =>
      _updateCounter(id, (c) => c.copyWith(dailyTarget: value));

  Future<bool> setRemindersEnabled(String id, bool enabled) async {
    if (enabled) {
      final granted = await _notificationService.requestPermission();
      if (!granted) return false;
    }
    await _updateCounter(id, (c) => c.copyWith(remindersEnabled: enabled));
    await _reschedule();
    return true;
  }

  Future<void> setReminderType(String id, ReminderType type) async {
    await _updateCounter(id, (c) => c.copyWith(reminderType: type));
    await _reschedule();
  }

  Future<void> setReminderInterval(String id, int minutes) async {
    await _updateCounter(id, (c) => c.copyWith(reminderIntervalMinutes: minutes));
    await _reschedule();
  }

  Future<void> setDailyReminderTimes(String id, List<int> times) async {
    await _updateCounter(id, (c) => c.copyWith(dailyReminderTimes: times));
    await _reschedule();
  }

  Future<void> notifyDailyTargetReached() async {
    await _notificationService.showDailyTargetReached(activeCounter.name);
  }

  Future<void> rolloverIfNewDay() => _rolloverAll();

  Future<void> _updateCounter(
    String id,
    AdhkarCounter Function(AdhkarCounter) update,
  ) async {
    final index = _counters.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _counters[index] = update(_counters[index]);
    await _persist();
    notifyListeners();
  }

  void _replace(String id, AdhkarCounter counter) {
    final index = _counters.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _counters[index] = counter;
    }
  }

  AdhkarCounter _rolloverIfNeeded(AdhkarCounter counter) {
    final now = DateTime.now();
    final last = counter.lastUsedAt;
    if (last.year == now.year &&
        last.month == now.month &&
        last.day == now.day) {
      return counter;
    }
    final history = Map<String, int>.from(counter.history);
    if (counter.currentCount > 0) {
      history[dailyKey(last)] = counter.currentCount;
    }
    return counter.copyWith(
      currentCount: 0,
      history: history,
      lastUsedAt: now,
      lastResetAt: now,
    );
  }

  Future<void> _rolloverAll() async {
    var changed = false;
    for (var i = 0; i < _counters.length; i++) {
      final rolled = _rolloverIfNeeded(_counters[i]);
      if (!identical(rolled, _counters[i])) {
        _counters[i] = rolled;
        changed = true;
      }
    }
    if (changed) {
      await _persist();
    }
  }

  Future<void> _reschedule() async {
    await _notificationService.rescheduleAll(_counters);
  }

  Future<void> _persist() => _storage.saveCounters(_counters);
}
