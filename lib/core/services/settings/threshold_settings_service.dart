import 'package:flutter/foundation.dart';

import '../local_storage/local_storage_service.dart';

/// Owns the canonical user-adjustable Normal ranges for every sensor.
///
/// The fixed critical limits remain the safety envelope. Values inside a
/// configured range are Normal, values outside it are Warning, and values
/// beyond the critical envelope are Critical.
class ThresholdSettingsService extends ChangeNotifier {
  ThresholdSettingsService({required LocalStorageService storage})
    : _storage = storage;

  final LocalStorageService _storage;

  static const double temperatureCriticalLow = 10;
  static const double temperatureCriticalHigh = 36;
  static const double humidityCriticalLow = 40;
  static const double humidityCriticalHigh = 85;
  static const double soilMoistureCriticalLow = 50;
  static const double soilMoistureCriticalHigh = 90;
  static const double lightCriticalLow = 20000;
  static const double lightCriticalHigh = 90000;
  static const double lightCriticalHighTemperature = 35;

  static const double defaultMinTemperature = 20;
  static const double defaultMaxTemperature = 30;
  static const double defaultMinHumidity = 60;
  static const double defaultMaxHumidity = 75;
  static const double defaultMinMoisture = 60;
  static const double defaultMaxMoisture = 85;
  static const double defaultMinLight = 45000;
  static const double defaultMaxLight = 70000;

  // Presentation/demo bounds are intentionally wider than the fixed Critical
  // boundaries, allowing both low and high scenarios to be configured.
  static const double temperatureRangeMin = 0;
  static const double temperatureRangeMax = 50;
  static const double humidityRangeMin = 0;
  static const double humidityRangeMax = 100;
  static const double moistureRangeMin = 0;
  static const double moistureRangeMax = 100;
  static const double lightRangeMin = 0;
  static const double lightRangeMax = 100000;

  double _minTemperature = defaultMinTemperature;
  double _maxTemperature = defaultMaxTemperature;
  double _minHumidity = defaultMinHumidity;
  double _maxHumidity = defaultMaxHumidity;
  double _minMoisture = defaultMinMoisture;
  double _maxMoisture = defaultMaxMoisture;
  double _minLight = defaultMinLight;
  double _maxLight = defaultMaxLight;

  double get minTemperature => _minTemperature;
  double get maxTemperature => _maxTemperature;
  double get minHumidity => _minHumidity;
  double get maxHumidity => _maxHumidity;
  double get minMoisture => _minMoisture;
  double get maxMoisture => _maxMoisture;
  double get minLight => _minLight;
  double get maxLight => _maxLight;

  bool isTemperatureNormal(double value) =>
      value >= minTemperature && value <= maxTemperature;

  bool isHumidityNormal(double value) =>
      value >= minHumidity && value <= maxHumidity;

  bool isSoilMoistureNormal(double value) =>
      value >= minMoisture && value <= maxMoisture;

  bool isLightIntensityNormal(double value) =>
      value >= minLight && value <= maxLight;

  Future<void> load() async {
    final ({double min, double max}) temperature = _normalizeRange(
      await _storage.getMinTemperatureThreshold() ?? defaultMinTemperature,
      await _storage.getMaxTemperatureThreshold() ?? defaultMaxTemperature,
      temperatureRangeMin,
      temperatureRangeMax,
    );
    final ({double min, double max}) humidity = _normalizeRange(
      await _storage.getMinHumidityThreshold() ?? defaultMinHumidity,
      await _storage.getMaxHumidityThreshold() ?? defaultMaxHumidity,
      humidityRangeMin,
      humidityRangeMax,
    );
    final ({double min, double max}) moisture = _normalizeRange(
      await _storage.getMinMoistureThreshold() ?? defaultMinMoisture,
      await _storage.getMaxMoistureThreshold() ?? defaultMaxMoisture,
      moistureRangeMin,
      moistureRangeMax,
    );
    final ({double min, double max}) light = _normalizeRange(
      await _storage.getMinLightThreshold() ?? defaultMinLight,
      await _storage.getMaxLightThreshold() ?? defaultMaxLight,
      lightRangeMin,
      lightRangeMax,
    );

    _minTemperature = temperature.min;
    _maxTemperature = temperature.max;
    _minHumidity = humidity.min;
    _maxHumidity = humidity.max;
    _minMoisture = moisture.min;
    _maxMoisture = moisture.max;
    _minLight = light.min;
    _maxLight = light.max;
    notifyListeners();
  }

  Future<void> setTemperatureRange({
    required double minimum,
    required double maximum,
    bool persist = true,
  }) async {
    final ({double min, double max}) range = _normalizeRange(
      minimum,
      maximum,
      temperatureRangeMin,
      temperatureRangeMax,
    );
    _minTemperature = range.min;
    _maxTemperature = range.max;
    notifyListeners();
    if (persist) {
      await _storage.saveMinTemperatureThreshold(_minTemperature);
      await _storage.saveMaxTemperatureThreshold(_maxTemperature);
    }
  }

  Future<void> setHumidityRange({
    required double minimum,
    required double maximum,
    bool persist = true,
  }) async {
    final ({double min, double max}) range = _normalizeRange(
      minimum,
      maximum,
      humidityRangeMin,
      humidityRangeMax,
    );
    _minHumidity = range.min;
    _maxHumidity = range.max;
    notifyListeners();
    if (persist) {
      await _storage.saveMinHumidityThreshold(_minHumidity);
      await _storage.saveMaxHumidityThreshold(_maxHumidity);
    }
  }

  Future<void> setMoistureRange({
    required double minimum,
    required double maximum,
    bool persist = true,
  }) async {
    final ({double min, double max}) range = _normalizeRange(
      minimum,
      maximum,
      moistureRangeMin,
      moistureRangeMax,
    );
    _minMoisture = range.min;
    _maxMoisture = range.max;
    notifyListeners();
    if (persist) {
      await _storage.saveMinMoistureThreshold(_minMoisture);
      await _storage.saveMaxMoistureThreshold(_maxMoisture);
    }
  }

  Future<void> setLightRange({
    required double minimum,
    required double maximum,
    bool persist = true,
  }) async {
    final ({double min, double max}) range = _normalizeRange(
      minimum,
      maximum,
      lightRangeMin,
      lightRangeMax,
    );
    _minLight = range.min;
    _maxLight = range.max;
    notifyListeners();
    if (persist) {
      await _storage.saveMinLightThreshold(_minLight);
      await _storage.saveMaxLightThreshold(_maxLight);
    }
  }

  Future<void> resetToDefaults({bool clearPersisted = true}) async {
    if (clearPersisted) {
      await _storage.clearThresholdSettings();
    }
    _minTemperature = defaultMinTemperature;
    _maxTemperature = defaultMaxTemperature;
    _minHumidity = defaultMinHumidity;
    _maxHumidity = defaultMaxHumidity;
    _minMoisture = defaultMinMoisture;
    _maxMoisture = defaultMaxMoisture;
    _minLight = defaultMinLight;
    _maxLight = defaultMaxLight;
    notifyListeners();
  }

  ({double min, double max}) _normalizeRange(
    double first,
    double second,
    double lowerBound,
    double upperBound,
  ) {
    final double firstClamped = _clamp(first, lowerBound, upperBound);
    final double secondClamped = _clamp(second, lowerBound, upperBound);
    return firstClamped <= secondClamped
        ? (min: firstClamped, max: secondClamped)
        : (min: secondClamped, max: firstClamped);
  }

  double _clamp(double value, double minimum, double maximum) {
    return value.clamp(minimum, maximum).toDouble();
  }
}
