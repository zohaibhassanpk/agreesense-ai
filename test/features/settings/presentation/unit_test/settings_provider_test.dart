import 'package:agrisenseaiapp/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:agrisenseaiapp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:agrisenseaiapp/features/settings/presentation/providers/settings_provider.dart';
import 'package:agrisenseaiapp/core/services/alerts/alerts_store.dart';
import 'package:agrisenseaiapp/core/services/settings/threshold_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_local_storage_service.dart';

void main() {
  test('settings provider loads values', () async {
    final provider = SettingsProvider(
      repository: SettingsRepositoryImpl(
        localDataSource: SettingsLocalDataSourceImpl(),
      ),
      thresholdSettings: ThresholdSettingsService(
        storage: FakeLocalStorageService(),
      ),
    );
    await provider.loadSettings();
    expect(provider.minTemperature, 20);
    expect(provider.maxTemperature, 30);
    expect(provider.minHumidity, 60);
    expect(provider.maxHumidity, 75);
    expect(provider.minMoisture, 60);
    expect(provider.maxMoisture, 85);
    expect(provider.minLight, 45000);
    expect(provider.maxLight, 70000);
  });

  test(
    'clear local data restores the complete Settings default state',
    () async {
      final FakeLocalStorageService storage = FakeLocalStorageService();
      final provider = SettingsProvider(
        repository: SettingsRepositoryImpl(
          localDataSource: SettingsLocalDataSourceImpl(),
        ),
        thresholdSettings: ThresholdSettingsService(storage: storage),
        localStorageService: storage,
        alertsStore: AlertsStore(storage: storage),
      );
      await provider.loadSettings();
      await provider.commitTemperatureRange(5, 45);
      await provider.commitHumidityRange(10, 95);
      await provider.commitMoistureRange(15, 98);
      await provider.commitLightRange(100, 95000);
      await provider.togglePushNotifications(false);

      expect(await provider.clearLocalData(), isTrue);

      expect((provider.minTemperature, provider.maxTemperature), (20, 30));
      expect((provider.minHumidity, provider.maxHumidity), (60, 75));
      expect((provider.minMoisture, provider.maxMoisture), (60, 85));
      expect((provider.minLight, provider.maxLight), (45000, 70000));
      expect(provider.pushNotificationsEnabled, isTrue);
      expect(storage.settingsAndPreferencesCleared, isTrue);
    },
  );
}
