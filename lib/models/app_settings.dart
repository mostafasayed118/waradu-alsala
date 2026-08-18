class AppSettings {
  final bool notificationsEnabled;
  final bool vibrationEnabled;
  final bool dailyCounter;
  final ReminderType reminderType;
  final int reminderIntervalMinutes;
  final List<int> dailyReminderTimes;
  final bool isDarkMode;

  AppSettings({
    this.notificationsEnabled = true,
    this.vibrationEnabled = true,
    this.dailyCounter = false,
    this.reminderType = ReminderType.interval,
    this.reminderIntervalMinutes = 60,
    this.dailyReminderTimes = const [],
    this.isDarkMode = false,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? vibrationEnabled,
    bool? dailyCounter,
    ReminderType? reminderType,
    int? reminderIntervalMinutes,
    List<int>? dailyReminderTimes,
    bool? isDarkMode,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      dailyCounter: dailyCounter ?? this.dailyCounter,
      reminderType: reminderType ?? this.reminderType,
      reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      dailyReminderTimes: dailyReminderTimes ?? this.dailyReminderTimes,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'vibrationEnabled': vibrationEnabled,
      'dailyCounter': dailyCounter,
      'reminderType': reminderType.index,
      'reminderIntervalMinutes': reminderIntervalMinutes,
      'dailyReminderTimes': dailyReminderTimes,
      'isDarkMode': isDarkMode,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      dailyCounter: json['dailyCounter'] ?? false,
      reminderType: ReminderType.values[json['reminderType'] ?? 0],
      reminderIntervalMinutes: json['reminderIntervalMinutes'] ?? 60,
      dailyReminderTimes: List<int>.from(json['dailyReminderTimes'] ?? []),
      isDarkMode: json['isDarkMode'] ?? false,
    );
  }
}

enum ReminderType {
  interval,
  daily,
}
