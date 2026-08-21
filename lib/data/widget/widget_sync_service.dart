import 'dart:async';

import 'package:home_widget/home_widget.dart';

import 'package:salawat_app/domain/entities/adhkar_counter.dart';
import 'package:salawat_app/data/counters_repository_impl.dart';

/// Keeps the Android home-screen widget in sync with the active counter.
class WidgetSyncService {
  WidgetSyncService();

  static const String androidWidgetName = 'SalawatWidgetProvider';
  static const Duration _debounceDelay = Duration(milliseconds: 250);

  Timer? _timer;
  AdhkarCounter? _pending;

  /// Debounced push: rapid taps coalesce into one widget update.
  void sync(AdhkarCounter counter) {
    _pending = counter;
    _timer?.cancel();
    _timer = Timer(_debounceDelay, () {
      final c = _pending;
      if (c != null) unawaited(_push(c));
    });
  }

  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    final c = _pending;
    if (c == null) return Future.value();
    return _push(c);
  }

  void dispose() => _timer?.cancel();

  Future<void> _push(AdhkarCounter counter) async {
    try {
      await HomeWidget.saveWidgetData<String>(
          'counter_name', counter.name);
      await HomeWidget.saveWidgetData<int>(
          'counter_count', counter.currentCount);
      await HomeWidget.updateWidget(androidName: androidWidgetName);
    } catch (_) {
      // Widget APIs are unavailable on some platforms (tests, desktop);
      // never let a decorative surface break the app.
    }
  }
}

/// Runs in a background isolate when the widget's increment button is tapped.
/// Re-reads state from storage because no provider exists in this isolate.
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri?.host != 'increment') return;
  try {
    final storage = CountersRepositoryImpl();
    final counters = await storage.getCounters();
    if (counters.isEmpty) return;

    final storedId = await storage.getActiveCounterId();
    var index = counters.indexWhere((c) => c.id == storedId);
    if (index < 0) index = 0;

    final now = DateTime.now();
    final rolled = counters[index].rolledOver(now);
    final updated = rolled.copyWith(
      currentCount: rolled.currentCount + 1,
      totalCount: rolled.totalCount + 1,
      lastUsedAt: now,
    );
    counters[index] = updated;
    await storage.saveCounters(counters);

    await HomeWidget.saveWidgetData<int>(
        'counter_count', updated.currentCount);
    await HomeWidget.updateWidget(
        androidName: WidgetSyncService.androidWidgetName);
  } catch (_) {
    // Never crash the background isolate.
  }
}

