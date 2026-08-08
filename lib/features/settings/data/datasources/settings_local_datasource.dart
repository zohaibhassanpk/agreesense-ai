import '../../../../core/services/local_storage/local_storage_service.dart';
import '../models/settings_dashboard_model.dart';

abstract class SettingsLocalDataSource {
  Future<SettingsDashboardModel> getDashboard();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  SettingsLocalDataSourceImpl({this.localStorageService});

  final LocalStorageService? localStorageService;

  @override
  Future<SettingsDashboardModel> getDashboard() async {
    return SettingsDashboardModel(
      selectedCrop: 'Tobacco',
      minTemperature: 20,
      maxTemperature: 30,
      minHumidity: 60,
      maxHumidity: 75,
      minMoisture: 60,
      maxMoisture: 85,
      minLight: 45000,
      maxLight: 70000,
      pushNotificationsEnabled:
          await localStorageService?.getNotificationsEnabled() ?? true,
      language: 'English',
    );
  }
}
