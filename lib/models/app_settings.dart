/// Language preference: 'system' (follow platform), 'ar', or 'en'.
class AppSettings {
  final bool vibrationEnabled;
  final bool soundEnabled;
  final bool isDarkMode;
  final String languageCode;

  /// Prayer-time calculation location (null = not configured yet).
  final double? latitude;
  final double? longitude;

  /// One of [CalculationMethod] names from the adhan package.
  final String calculationMethod;

  AppSettings({
    this.vibrationEnabled = true,
    this.soundEnabled = false,
    this.isDarkMode = false,
    this.languageCode = 'ar',
    this.latitude,
    this.longitude,
    this.calculationMethod = 'muslim_world_league',
  });

  AppSettings copyWith({
    bool? vibrationEnabled,
    bool? soundEnabled,
    bool? isDarkMode,
    String? languageCode,
    double? latitude,
    double? longitude,
    String? calculationMethod,
  }) {
    return AppSettings(
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      languageCode: languageCode ?? this.languageCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      calculationMethod: calculationMethod ?? this.calculationMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vibrationEnabled': vibrationEnabled,
      'soundEnabled': soundEnabled,
      'isDarkMode': isDarkMode,
      'languageCode': languageCode,
      'latitude': latitude,
      'longitude': longitude,
      'calculationMethod': calculationMethod,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? false,
      isDarkMode: json['isDarkMode'] ?? false,
      languageCode: json['languageCode'] ?? 'ar',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      calculationMethod: json['calculationMethod'] ?? 'muslim_world_league',
    );
  }
}


