import '../entities/adhkar_counter.dart';

abstract class CountersRepository {
  Future<List<AdhkarCounter>> getCounters();
  Future<void> saveCounters(List<AdhkarCounter> counters);
  Future<String?> getActiveCounterId();
  Future<void> saveActiveCounterId(String? id);
}
