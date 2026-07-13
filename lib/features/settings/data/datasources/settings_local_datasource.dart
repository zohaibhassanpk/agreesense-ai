import '../models/settings_dashboard_model.dart';

abstract class SettingsLocalDataSource {
  Future<SettingsDashboardModel> getDashboard();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  @override
  Future<SettingsDashboardModel> getDashboard() async {
    return const SettingsDashboardModel(
      selectedCrop: 'Tobacco',
      minMoisture: 60,
      maxTemperature: 30,
      maxHumidity: 75,
      pushNotificationsEnabled: true,
      language: 'English',
    );
  }
}
