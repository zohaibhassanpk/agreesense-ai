import 'package:agrisenseaiapp/core/services/settings/threshold_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_local_storage_service.dart';

void main() {
  group('ThresholdSettingsService', () {
    test('loads canonical defaults when storage is empty', () async {
      final service = ThresholdSettingsService(
        storage: FakeLocalStorageService(),
      );

      await service.load();

      expect(service.minMoisture, 60);
      expect(service.maxTemperature, 30);
      expect(service.maxHumidity, 75);
    });

    test(
      'clamps persisted values to their canonical critical bounds',
      () async {
        final storage = FakeLocalStorageService()
          ..minMoistureThreshold = 20
          ..maxTemperatureThreshold = 45
          ..maxHumidityThreshold = 50;
        final service = ThresholdSettingsService(storage: storage);

        await service.load();

        expect(service.minMoisture, 50);
        expect(service.maxTemperature, 36);
        expect(service.maxHumidity, 60);
      },
    );

    test('live updates do not persist until committed', () async {
      final storage = FakeLocalStorageService();
      final service = ThresholdSettingsService(storage: storage);

      await service.setMinMoisture(64, persist: false);
      await service.setMaxTemperature(33, persist: false);
      await service.setMaxHumidity(78, persist: false);

      expect(service.minMoisture, 64);
      expect(service.maxTemperature, 33);
      expect(service.maxHumidity, 78);
      expect(storage.savedMinMoistureThreshold, isNull);
      expect(storage.savedMaxTemperatureThreshold, isNull);
      expect(storage.savedMaxHumidityThreshold, isNull);

      await service.setMinMoisture(49);
      await service.setMaxTemperature(40);
      await service.setMaxHumidity(90);

      expect(storage.savedMinMoistureThreshold, 50);
      expect(storage.savedMaxTemperatureThreshold, 36);
      expect(storage.savedMaxHumidityThreshold, 85);
    });

    test('normal-range helpers use configured warning boundaries', () async {
      final service = ThresholdSettingsService(
        storage: FakeLocalStorageService(),
      );
      await service.setMinMoisture(65, persist: false);
      await service.setMaxTemperature(32, persist: false);
      await service.setMaxHumidity(80, persist: false);

      expect(service.isSoilMoistureNormal(64), isFalse);
      expect(service.isSoilMoistureNormal(65), isTrue);
      expect(service.isSoilMoistureNormal(86), isFalse);
      expect(service.isTemperatureNormal(19), isFalse);
      expect(service.isTemperatureNormal(32), isTrue);
      expect(service.isTemperatureNormal(33), isFalse);
      expect(service.isHumidityNormal(59), isFalse);
      expect(service.isHumidityNormal(80), isTrue);
      expect(service.isHumidityNormal(81), isFalse);
      expect(service.isLightIntensityNormal(45000), isTrue);
      expect(service.isLightIntensityNormal(70001), isFalse);
    });
  });
}
