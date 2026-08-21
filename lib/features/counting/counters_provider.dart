import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:salawat_app/domain/entities/adhkar_counter.dart';
import 'package:salawat_app/data/notifications/notification_service.dart';
import 'package:salawat_app/data/storage_service.dart';
import 'package:salawat_app/domain/services/rollover.dart';

class CountersProvider with ChangeNotifier {
  final StorageService _storage;
  final NotificationService _notificationService;

  List<AdhkarCounter> _counters = [];
  String _activeId = '';
  int? _lastCount;

  // Debounced persistence: the UI notifies first, the write lands shortly
  // after (or on app pause) so rapid taps never wait on disk.
  static const Duration _persistDelay = Duration(milliseconds: 300);
  Timer? _persistTimer;
  bool _persistPending = false;

  static final AdhkarCounter _empty = AdhkarCounter(id: '', name: '');

  CountersProvider(this._storage, this._notificationService);

  List<AdhkarCounter> get counters => List.unmodifiable(_counters);

  AdhkarCounter get activeCounter {
    for (final c in _counters) {
      if (c.id == _activeId) return c;
    }
    if (_counters.isNotEmpty) return _counters.first;
    return _empty;
  }

  bool get canUndo => _lastCount != null;

  Future<void> load() async {
    _counters = List.of(await _storage.getCounters());
    final stored = await _storage.getActiveCounterId();
    if (stored != null &&
        stored.isNotEmpty &&
        _counters.any((c) => c.id == stored)) {
      _activeId = stored;
    } else if (_activeId.isEmpty || !_counters.any((c) => c.id == _activeId)) {
      _activeId = _counters.isEmpty ? '' : _counters.first.id;
    }
    await _rolloverAll();
    notifyListeners();
  }

  Future<void> setActive(String id) async {
    if (_activeId == id) return;
    _activeId = id;
    _lastCount = null;
    await _storage.saveActiveCounterId(id);
    notifyListeners();
  }

  Future<void> increment() async {
    final active = activeCounter;
    final rolled = rollOverCounter(active, DateTime.now());
    _lastCount = rolled.currentCount;
    _replace(
      active.id,
      rolled.copyWith(
        currentCount: rolled.currentCount + 1,
        totalCount: rolled.totalCount + 1,
        lastUsedAt: DateTime.now(),
      ),
    );
    notifyListeners();
    _schedulePersist();
  }

  Future<void> undo() async {
    if (_lastCount == null) return;
    final active = activeCounter;
    _replace(
      active.id,
      active.copyWith(
        currentCount: _lastCount!,
        totalCount: active.totalCount > 0 ? active.totalCount - 1 : 0,
        lastUsedAt: DateTime.now(),
      ),
    );
    _lastCount = null;
    notifyListeners();
    _schedulePersist();
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
    notifyListeners();
    _schedulePersist();
  }

  Future<void> addCounter(String name) async {
    final counter = AdhkarCounter(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
    );
    _counters = [..._counters, counter];
    _activeId = counter.id;
    _lastCount = null;
    notifyListeners();
    await _flushPersist();
    await _storage.saveActiveCounterId(counter.id);
  }

  /// Activates an existing counter named [name], creating it first when no
  /// counter has that name yet. Returns its id.
  Future<String> ensureCounterNamed(String name) async {
    final existing = _counters.indexWhere((c) => c.name == name);
    if (existing >= 0) {
      final id = _counters[existing].id;
      await setActive(id);
      return id;
    }
    await addCounter(name);
    return activeCounter.id;
  }

  Future<void> renameCounter(String id, String name) =>
      _updateCounter(id, (c) => c.copyWith(name: name));

  Future<void> deleteCounter(String id) async {
    final index = _counters.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _counters = List.of(_counters)..removeAt(index);
    if (_activeId == id) {
      _activeId = _counters.isEmpty ? '' : _counters.first.id;
      await _storage.saveActiveCounterId(
          _counters.isEmpty ? null : _activeId);
    }
    _lastCount = null;
    notifyListeners();
    await _flushPersist();
    await _reschedule();
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

  Future<void> setPrayerOffset(String id, int minutes) async {
    await _updateCounter(id, (c) => c.copyWith(prayerOffsetMinutes: minutes));
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

  /// Writes any pending counter changes immediately (e.g. app paused).
  Future<void> flushPendingSave() => _flushPersist();

  Future<void> _updateCounter(
    String id,
    AdhkarCounter Function(AdhkarCounter) update,
  ) async {
    final index = _counters.indexWhere((c) => c.id == id);
    if (index < 0) return;
    _counters[index] = update(_counters[index]);
    notifyListeners();
    await _flushPersist();
  }

  void _schedulePersist() {
    _persistPending = true;
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDelay, _flushPersist);
  }

  Future<void> _flushPersist() {
    _persistTimer?.cancel();
    _persistTimer = null;
    if (!_persistPending) return Future.value();
    _persistPending = false;
    return _storage.saveCounters(_counters);
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    if (_persistPending) {
      _persistPending = false;
      unawaited(_storage.saveCounters(_counters));
    }
    super.dispose();
  }

  void _replace(String id, AdhkarCounter counter) {
    final index = _counters.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _counters[index] = counter;
    }
  }

  Future<void> _rolloverAll() async {
    var changed = false;
    final now = DateTime.now();
    for (var i = 0; i < _counters.length; i++) {
      final rolled = rollOverCounter(_counters[i], now);
      if (!identical(rolled, _counters[i])) {
        _counters[i] = rolled;
        changed = true;
      }
    }
    _lastCount = null;
    if (changed) {
      _schedulePersist();
    }
  }

  Future<void> _reschedule() async {
    // Prayer-type counters need the configured location from settings.
    final settings = await _storage.getSettings();
    await _notificationService.rescheduleAll(_counters, settings: settings);
  }
}


