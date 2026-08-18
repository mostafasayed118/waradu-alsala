class CounterData {
  final int currentCount;
  final int totalCount;
  final DateTime lastUsedAt;
  final DateTime? lastResetAt;

  CounterData({
    this.currentCount = 0,
    this.totalCount = 0,
    DateTime? lastUsedAt,
    this.lastResetAt,
  }) : lastUsedAt = lastUsedAt ?? DateTime.now();

  CounterData copyWith({
    int? currentCount,
    int? totalCount,
    DateTime? lastUsedAt,
    DateTime? lastResetAt,
  }) {
    return CounterData(
      currentCount: currentCount ?? this.currentCount,
      totalCount: totalCount ?? this.totalCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      lastResetAt: lastResetAt ?? this.lastResetAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentCount': currentCount,
      'totalCount': totalCount,
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'lastResetAt': lastResetAt?.toIso8601String(),
    };
  }

  factory CounterData.fromJson(Map<String, dynamic> json) {
    return CounterData(
      currentCount: json['currentCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      lastUsedAt: DateTime.parse(json['lastUsedAt'] ?? DateTime.now().toIso8601String()),
      lastResetAt: json['lastResetAt'] != null 
          ? DateTime.parse(json['lastResetAt']) 
          : null,
    );
  }
}
