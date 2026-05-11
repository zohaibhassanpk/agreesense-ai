class SettingsDashboard {
  const SettingsDashboard({
    required this.selectedCrop,
    required this.minMoisture,
    required this.maxTemperature,
    required this.pushNotificationsEnabled,
    required this.language,
  });

  final String selectedCrop;
  final double minMoisture;
  final double maxTemperature;
  final bool pushNotificationsEnabled;
  final String language;
}
