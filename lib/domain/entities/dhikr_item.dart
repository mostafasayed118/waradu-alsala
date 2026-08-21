enum DhikrCategory { morning, evening, general }

/// A curated dhikr entry shown in the adhkar library.
class DhikrItem {
  const DhikrItem({
    required this.id,
    required this.name,
    required this.text,
    required this.category,
    this.recommendedCount,
  });

  final String id;

  /// Short label used as the counter name when the user starts counting it.
  final String name;
  final String text;
  final DhikrCategory category;

  /// Sunnah-recommended repetitions, when established.
  final int? recommendedCount;
}

