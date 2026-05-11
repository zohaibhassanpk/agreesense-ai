import '../models/settings_dashboard_model.dart';

abstract class SettingsLocalDataSource {
  Future<SettingsDashboardModel> getDashboard();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  @override
  Future<SettingsDashboardModel> getDashboard() async {
    return const SettingsDashboardModel(
      selectedCrop: 'Tobacco',
      minMoisture: 30,
      maxTemperature: 35,
      pushNotificationsEnabled: true,
      language: 'English',
    );
  }
}
