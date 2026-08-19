class AppSettings {
  final bool vibrationEnabled;
  final bool isDarkMode;

  AppSettings({
    this.vibrationEnabled = true,
    this.isDarkMode = false,
  });

  AppSettings copyWith({
    bool? vibrationEnabled,
    bool? isDarkMode,
  }) {
    return AppSettings(
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vibrationEnabled': vibrationEnabled,
      'isDarkMode': isDarkMode,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      isDarkMode: json['isDarkMode'] ?? false,
    );
  }
}
