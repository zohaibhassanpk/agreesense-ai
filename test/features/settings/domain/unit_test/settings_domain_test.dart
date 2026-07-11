import 'package:agrisenseaiapp/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:agrisenseaiapp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:agrisenseaiapp/features/settings/domain/entities/settings_dashboard.dart';
import 'package:agrisenseaiapp/features/settings/domain/repositories/settings_repository.dart';
import 'package:agrisenseaiapp/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingSettingsRepo implements SettingsRepository {
  @override
  Future<SettingsDashboard> getDashboard() async {
    throw Exception('err');
  }
}

void main() {
  group('Settings Unit Tests', () {
    test('datasource returns settings defaults', () async {
      final source = SettingsLocalDataSourceImpl();
      final data = await source.getDashboard();
      expect(data.selectedCrop, 'Tobacco');
      expect(data.pushNotificationsEnabled, isTrue);
    });

    test('provider loadSettings maps dashboard fields', () async {
      final provider = SettingsProvider(
        repository: SettingsRepositoryImpl(
          localDataSource: SettingsLocalDataSourceImpl(),
        ),
      );

      await provider.loadSettings();

      expect(provider.minMoisture, 30);
      expect(provider.maxTemperature, 35);
      expect(provider.pushNotificationsEnabled, isTrue);
      expect(provider.errorMessage, isNull);
    });

    test('provider update methods notify state', () {
      final provider = SettingsProvider(
        repository: SettingsRepositoryImpl(
          localDataSource: SettingsLocalDataSourceImpl(),
        ),
      );

      provider.updateMinMoisture(20);
      provider.updateMaxTemperature(31);
      provider.togglePushNotifications(false);

      expect(provider.minMoisture, 20);
      expect(provider.maxTemperature, 31);
      expect(provider.pushNotificationsEnabled, isFalse);
    });

    test('provider reports load error', () async {
      final provider = SettingsProvider(repository: _FailingSettingsRepo());
      await provider.loadSettings();
      expect(provider.errorMessage, 'Unable to load settings.');
    });
  });
}
