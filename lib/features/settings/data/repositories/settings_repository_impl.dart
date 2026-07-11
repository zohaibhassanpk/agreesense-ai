import '../../domain/entities/settings_dashboard.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl({required this.localDataSource});

  final SettingsLocalDataSource localDataSource;

  @override
  Future<SettingsDashboard> getDashboard() {
    return localDataSource.getDashboard();
  }
}
