import 'package:agrisenseaiapp/core/services/settings/threshold_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_local_storage_service.dart';

void main() {
  group('ThresholdSettingsService', () {
    test(
      'loads canonical minimum and maximum defaults for every sensor',
      () async {
        final service = ThresholdSettingsService(
          storage: FakeLocalStorageService(),
        );

        await service.load();

        expect(service.minTemperature, 20);
        expect(service.maxTemperature, 30);
        expect(service.minHumidity, 60);
        expect(service.maxHumidity, 75);
        expect(service.minMoisture, 60);
        expect(service.maxMoisture, 85);
        expect(service.minLight, 45000);
        expect(service.maxLight, 70000);
      },
    );

    test('clamps and orders persisted ranges inside expanded bounds', () async {
      final storage = FakeLocalStorageService()
        ..minTemperatureThreshold = 0
        ..maxTemperatureThreshold = 50
        ..minHumidityThreshold = 100
        ..maxHumidityThreshold = 0
        ..minMoistureThreshold = 20
        ..maxMoistureThreshold = 120
        ..minLightThreshold = 100000
        ..maxLightThreshold = 10000;
      final service = ThresholdSettingsService(storage: storage);

      await service.load();

      expect((service.minTemperature, service.maxTemperature), (0, 50));
      expect((service.minHumidity, service.maxHumidity), (0, 100));
      expect((service.minMoisture, service.maxMoisture), (20, 100));
      expect((service.minLight, service.maxLight), (10000, 100000));
    });

    test('live range updates do not persist until committed', () async {
      final storage = FakeLocalStorageService();
      final service = ThresholdSettingsService(storage: storage);

      await service.setTemperatureRange(
        minimum: 18,
        maximum: 32,
        persist: false,
      );
      await service.setHumidityRange(minimum: 55, maximum: 80, persist: false);
      await service.setMoistureRange(minimum: 64, maximum: 87, persist: false);
      await service.setLightRange(
        minimum: 40000,
        maximum: 75000,
        persist: false,
      );

      expect((service.minTemperature, service.maxTemperature), (18, 32));
      expect((service.minHumidity, service.maxHumidity), (55, 80));
      expect((service.minMoisture, service.maxMoisture), (64, 87));
      expect((service.minLight, service.maxLight), (40000, 75000));
      expect(storage.savedMinTemperatureThreshold, isNull);
      expect(storage.savedMaxTemperatureThreshold, isNull);
      expect(storage.savedMinHumidityThreshold, isNull);
      expect(storage.savedMaxHumidityThreshold, isNull);
      expect(storage.savedMinMoistureThreshold, isNull);
      expect(storage.savedMaxMoistureThreshold, isNull);
      expect(storage.savedMinLightThreshold, isNull);
      expect(storage.savedMaxLightThreshold, isNull);

      await service.setTemperatureRange(minimum: 5, maximum: 45);
      await service.setHumidityRange(minimum: 20, maximum: 95);
      await service.setMoistureRange(minimum: 40, maximum: 100);
      await service.setLightRange(minimum: 10000, maximum: 100000);

      expect(storage.savedMinTemperatureThreshold, 5);
      expect(storage.savedMaxTemperatureThreshold, 45);
      expect(storage.savedMinHumidityThreshold, 20);
      expect(storage.savedMaxHumidityThreshold, 95);
      expect(storage.savedMinMoistureThreshold, 40);
      expect(storage.savedMaxMoistureThreshold, 100);
      expect(storage.savedMinLightThreshold, 10000);
      expect(storage.savedMaxLightThreshold, 100000);
    });

    test('normal helpers use both configured boundaries inclusively', () async {
      final service = ThresholdSettingsService(
        storage: FakeLocalStorageService(),
      );
      await service.setTemperatureRange(
        minimum: 18,
        maximum: 32,
        persist: false,
      );
      await service.setHumidityRange(minimum: 55, maximum: 80, persist: false);
      await service.setMoistureRange(minimum: 65, maximum: 86, persist: false);
      await service.setLightRange(
        minimum: 40000,
        maximum: 75000,
        persist: false,
      );

      expect(service.isTemperatureNormal(17), isFalse);
      expect(service.isTemperatureNormal(18), isTrue);
      expect(service.isTemperatureNormal(32), isTrue);
      expect(service.isTemperatureNormal(33), isFalse);
      expect(service.isHumidityNormal(54), isFalse);
      expect(service.isHumidityNormal(80), isTrue);
      expect(service.isHumidityNormal(81), isFalse);
      expect(service.isSoilMoistureNormal(64), isFalse);
      expect(service.isSoilMoistureNormal(65), isTrue);
      expect(service.isSoilMoistureNormal(87), isFalse);
      expect(service.isLightIntensityNormal(39999), isFalse);
      expect(service.isLightIntensityNormal(40000), isTrue);
      expect(service.isLightIntensityNormal(75001), isFalse);
    });

    test('reset restores defaults and removes persisted thresholds', () async {
      final storage = FakeLocalStorageService();
      final service = ThresholdSettingsService(storage: storage);
      await service.setTemperatureRange(minimum: 5, maximum: 45);
      await service.setHumidityRange(minimum: 10, maximum: 95);
      await service.setMoistureRange(minimum: 15, maximum: 98);
      await service.setLightRange(minimum: 100, maximum: 95000);

      await service.resetToDefaults();

      expect((service.minTemperature, service.maxTemperature), (20, 30));
      expect((service.minHumidity, service.maxHumidity), (60, 75));
      expect((service.minMoisture, service.maxMoisture), (60, 85));
      expect((service.minLight, service.maxLight), (45000, 70000));
      expect(storage.thresholdSettingsCleared, isTrue);
    });
  });
}
