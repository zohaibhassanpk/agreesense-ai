import 'package:agrisenseaiapp/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:agrisenseaiapp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:agrisenseaiapp/core/services/settings/threshold_settings_service.dart';
import 'package:agrisenseaiapp/features/settings/domain/entities/settings_dashboard.dart';
import 'package:agrisenseaiapp/features/settings/domain/repositories/settings_repository.dart';
import 'package:agrisenseaiapp/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_local_storage_service.dart';

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
        thresholdSettings: ThresholdSettingsService(
          storage: FakeLocalStorageService(),
        ),
      );

      await provider.loadSettings();

      expect(provider.minMoisture, 60);
      expect(provider.maxTemperature, 30);
      expect(provider.maxHumidity, 75);
      expect(provider.pushNotificationsEnabled, isTrue);
      expect(provider.errorMessage, isNull);
    });

    test('provider update methods notify state', () async {
      final provider = SettingsProvider(
        repository: SettingsRepositoryImpl(
          localDataSource: SettingsLocalDataSourceImpl(),
        ),
        thresholdSettings: ThresholdSettingsService(
          storage: FakeLocalStorageService(),
        ),
      );

      await provider.updateMinMoisture(65);
      await provider.updateMaxTemperature(31);
      await provider.updateMaxHumidity(80);
      provider.togglePushNotifications(false);

      expect(provider.minMoisture, 65);
      expect(provider.maxTemperature, 31);
      expect(provider.maxHumidity, 80);
      expect(provider.pushNotificationsEnabled, isFalse);
    });

    test('provider reports load error', () async {
      final provider = SettingsProvider(
        repository: _FailingSettingsRepo(),
        thresholdSettings: ThresholdSettingsService(
          storage: FakeLocalStorageService(),
        ),
      );
      await provider.loadSettings();
      expect(provider.errorMessage, 'Unable to load settings.');
    });
  });
}
