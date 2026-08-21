enum ReminderType { interval, daily, prayer }

class AdhkarCounter {
  final String id;
  final String name;
  final int currentCount;
  final int totalCount;
  final int dailyTarget;
  final Map<String, int> history;
  final DateTime lastUsedAt;
  final DateTime? lastResetAt;
  final bool remindersEnabled;
  final ReminderType reminderType;
  final int reminderIntervalMinutes;
  final List<int> dailyReminderTimes;

  /// Minutes after each prayer, for [ReminderType.prayer].
  final int prayerOffsetMinutes;

  AdhkarCounter({
    required this.id,
    required this.name,
    this.currentCount = 0,
    this.totalCount = 0,
    this.dailyTarget = 0,
    this.history = const {},
    DateTime? lastUsedAt,
    this.lastResetAt,
    this.remindersEnabled = false,
    this.reminderType = ReminderType.interval,
    this.reminderIntervalMinutes = 60,
    this.dailyReminderTimes = const [],
    this.prayerOffsetMinutes = 10,
  }) : lastUsedAt = lastUsedAt ?? DateTime.now();

  AdhkarCounter copyWith({
    String? id,
    String? name,
    int? currentCount,
    int? totalCount,
    int? dailyTarget,
    Map<String, int>? history,
    DateTime? lastUsedAt,
    DateTime? lastResetAt,
    bool? remindersEnabled,
    ReminderType? reminderType,
    int? reminderIntervalMinutes,
    List<int>? dailyReminderTimes,
    int? prayerOffsetMinutes,
  }) {
    return AdhkarCounter(
      id: id ?? this.id,
      name: name ?? this.name,
      currentCount: currentCount ?? this.currentCount,
      totalCount: totalCount ?? this.totalCount,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      history: history ?? this.history,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      lastResetAt: lastResetAt ?? this.lastResetAt,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderType: reminderType ?? this.reminderType,
      reminderIntervalMinutes:
          reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      dailyReminderTimes: dailyReminderTimes ?? this.dailyReminderTimes,
      prayerOffsetMinutes: prayerOffsetMinutes ?? this.prayerOffsetMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currentCount': currentCount,
      'totalCount': totalCount,
      'dailyTarget': dailyTarget,
      'history': history,
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'lastResetAt': lastResetAt?.toIso8601String(),
      'remindersEnabled': remindersEnabled,
      'reminderType': reminderType.index,
      'reminderIntervalMinutes': reminderIntervalMinutes,
      'dailyReminderTimes': dailyReminderTimes,
      'prayerOffsetMinutes': prayerOffsetMinutes,
    };
  }

  factory AdhkarCounter.fromJson(Map<String, dynamic> json) {
    return AdhkarCounter(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      currentCount: json['currentCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      dailyTarget: json['dailyTarget'] ?? 0,
      history: _historyFromJson(json['history']),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : DateTime.now(),
      lastResetAt: json['lastResetAt'] != null
          ? DateTime.parse(json['lastResetAt'] as String)
          : null,
      remindersEnabled: json['remindersEnabled'] ?? false,
      reminderType: ReminderType.values[json['reminderType'] ?? 0],
      reminderIntervalMinutes: json['reminderIntervalMinutes'] ?? 60,
      dailyReminderTimes:
          List<int>.from(json['dailyReminderTimes'] ?? const []),
      prayerOffsetMinutes: json['prayerOffsetMinutes'] ?? 10,
    );
  }

  static Map<String, int> _historyFromJson(dynamic value) {
    if (value is! Map) return const {};
    return value.map<String, int>(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    );
  }
}

