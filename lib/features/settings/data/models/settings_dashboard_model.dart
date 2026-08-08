import '../../domain/entities/settings_dashboard.dart';

class SettingsDashboardModel extends SettingsDashboard {
  const SettingsDashboardModel({
    required super.selectedCrop,
    required super.minTemperature,
    required super.maxTemperature,
    required super.minHumidity,
    required super.maxHumidity,
    required super.minMoisture,
    required super.maxMoisture,
    required super.minLight,
    required super.maxLight,
    required super.pushNotificationsEnabled,
    required super.language,
  });
}
