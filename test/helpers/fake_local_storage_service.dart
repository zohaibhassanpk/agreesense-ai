import 'package:agrisenseaiapp/core/services/local_storage/local_storage_service.dart';

class FakeLocalStorageService extends LocalStorageService {
  double? minMoistureThreshold;
  double? maxTemperatureThreshold;
  double? maxHumidityThreshold;

  double? savedMinMoistureThreshold;
  double? savedMaxTemperatureThreshold;
  double? savedMaxHumidityThreshold;

  @override
  Future<double?> getMinMoistureThreshold() async => minMoistureThreshold;

  @override
  Future<void> saveMinMoistureThreshold(double value) async {
    savedMinMoistureThreshold = value;
    minMoistureThreshold = value;
  }

  @override
  Future<double?> getMaxTemperatureThreshold() async => maxTemperatureThreshold;

  @override
  Future<void> saveMaxTemperatureThreshold(double value) async {
    savedMaxTemperatureThreshold = value;
    maxTemperatureThreshold = value;
  }

  @override
  Future<double?> getMaxHumidityThreshold() async => maxHumidityThreshold;

  @override
  Future<void> saveMaxHumidityThreshold(double value) async {
    savedMaxHumidityThreshold = value;
    maxHumidityThreshold = value;
  }
}
