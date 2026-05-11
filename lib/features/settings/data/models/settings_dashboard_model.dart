import '../../domain/entities/settings_dashboard.dart';

class SettingsDashboardModel extends SettingsDashboard {
  const SettingsDashboardModel({
    required super.selectedCrop,
    required super.minMoisture,
    required super.maxTemperature,
    required super.pushNotificationsEnabled,
    required super.language,
  });
}
