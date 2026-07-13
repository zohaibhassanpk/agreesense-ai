import 'package:agrisenseaiapp/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:agrisenseaiapp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:agrisenseaiapp/features/settings/presentation/providers/settings_provider.dart';
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
    expect(provider.minMoisture, 60);
    expect(provider.maxTemperature, 30);
    expect(provider.maxHumidity, 75);
  });
}
