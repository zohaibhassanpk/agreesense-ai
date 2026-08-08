class SettingsDashboard {
  const SettingsDashboard({
    required this.selectedCrop,
    required this.minTemperature,
    required this.maxTemperature,
    required this.minHumidity,
    required this.maxHumidity,
    required this.minMoisture,
    required this.maxMoisture,
    required this.minLight,
    required this.maxLight,
    required this.pushNotificationsEnabled,
    required this.language,
  });

  final String selectedCrop;
  final double minTemperature;
  final double maxTemperature;
  final double minHumidity;
  final double maxHumidity;
  final double minMoisture;
  final double maxMoisture;
  final double minLight;
  final double maxLight;
  final bool pushNotificationsEnabled;
  final String language;
}
