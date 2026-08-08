import 'package:agrisenseaiapp/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:agrisenseaiapp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:agrisenseaiapp/core/services/settings/threshold_settings_service.dart';
import 'package:agrisenseaiapp/features/settings/domain/entities/settings_dashboard.dart';
import 'package:agrisenseaiapp/features/settings/domain/repositories/settings_repository.dart';
import 'package:agrisenseaiapp/features/settings/presentation/providers/settings_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_local_storage_service.dart';

class _FailingSettingsRepository implements SettingsRepository {
  @override
  Future<SettingsDashboard> getDashboard() async {
    throw Exception('settings fail');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Integration', () {
    testWidgets('load and mutate values', (tester) async {
      final provider = SettingsProvider(
        repository: SettingsRepositoryImpl(
          localDataSource: SettingsLocalDataSourceImpl(),
        ),
        thresholdSettings: ThresholdSettingsService(
          storage: FakeLocalStorageService(),
        ),
      );

      await provider.loadSettings();
      await provider.updateTemperatureRange(18, 31);
      await provider.updateHumidityRange(55, 80);
      await provider.updateMoistureRange(65, 87);
      await provider.updateLightRange(40000, 75000);
      provider.togglePushNotifications(false);

      expect(provider.minTemperature, 18);
      expect(provider.maxTemperature, 31);
      expect(provider.minHumidity, 55);
      expect(provider.maxHumidity, 80);
      expect(provider.minMoisture, 65);
      expect(provider.maxMoisture, 87);
      expect(provider.minLight, 40000);
      expect(provider.maxLight, 75000);
      expect(provider.pushNotificationsEnabled, isFalse);
    });

    testWidgets('load failure produces error', (tester) async {
      final provider = SettingsProvider(
        repository: _FailingSettingsRepository(),
        thresholdSettings: ThresholdSettingsService(
          storage: FakeLocalStorageService(),
        ),
      );

      await provider.loadSettings();
      expect(provider.dashboard, isNull);
      expect(provider.errorMessage, 'Unable to load settings.');
    });
  });
}
