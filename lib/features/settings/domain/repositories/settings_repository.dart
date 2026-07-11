import '../entities/settings_dashboard.dart';

abstract class SettingsRepository {
  Future<SettingsDashboard> getDashboard();
}
