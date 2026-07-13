import 'package:flutter/foundation.dart';

import '../local_storage/local_storage_service.dart';

/// Owns the canonical user-adjustable crop-condition warning boundaries.
class ThresholdSettingsService extends ChangeNotifier {
  ThresholdSettingsService({required LocalStorageService storage})
    : _storage = storage;

  final LocalStorageService _storage;

  // Canonical crop-condition zone table. A value beyond a critical boundary
  // is Critical; a value outside the normal warning boundaries is Warning.
  static const double temperatureCriticalLow = 10;
  static const double temperatureWarningLow = 20;
  static const double temperatureCriticalHigh = 36;

  static const double humidityCriticalLow = 40;
  static const double humidityWarningLow = 60;
  static const double humidityCriticalHigh = 85;

  static const double soilMoistureCriticalLow = 50;
  static const double soilMoistureWarningHigh = 85;
  static const double soilMoistureCriticalHigh = 90;

  static const double lightCriticalLow = 20000;
  static const double lightWarningLow = 45000;
  static const double lightWarningHigh = 70000;
  static const double lightCriticalHigh = 90000;
  static const double lightCriticalHighTemperature = 35;

  /// Default and allowed moisture warning-low values.
  static const double defaultMinMoisture = 60;
  static const double minMoistureLowerBound = soilMoistureCriticalLow;
  static const double minMoistureUpperBound = soilMoistureWarningHigh;

  /// Default and allowed temperature warning-high values.
  static const double defaultMaxTemperature = 30;
  static const double maxTemperatureLowerBound = temperatureWarningLow;
  static const double maxTemperatureUpperBound = temperatureCriticalHigh;

  /// Default and allowed humidity warning-high values.
  static const double defaultMaxHumidity = 75;
  static const double maxHumidityLowerBound = humidityWarningLow;
  static const double maxHumidityUpperBound = humidityCriticalHigh;

  double _minMoisture = defaultMinMoisture;
  double _maxTemperature = defaultMaxTemperature;
  double _maxHumidity = defaultMaxHumidity;

  double get minMoisture => _minMoisture;
  double get maxTemperature => _maxTemperature;
  double get maxHumidity => _maxHumidity;

  /// Whether [value] is inside the configured normal soil-moisture band.
  bool isSoilMoistureNormal(double value) {
    return value >= minMoisture && value <= soilMoistureWarningHigh;
  }

  /// Whether [value] is inside the configured normal temperature band.
  bool isTemperatureNormal(double value) {
    return value >= temperatureWarningLow && value <= maxTemperature;
  }

  /// Whether [value] is inside the configured normal humidity band.
  bool isHumidityNormal(double value) {
    return value >= humidityWarningLow && value <= maxHumidity;
  }

  /// Whether [value] is inside the fixed normal light-intensity band.
  bool isLightIntensityNormal(double value) {
    return value >= lightWarningLow && value <= lightWarningHigh;
  }

  /// Loads saved boundaries, retaining canonical defaults for unset values.
  Future<void> load() async {
    _minMoisture = _clamp(
      await _storage.getMinMoistureThreshold() ?? defaultMinMoisture,
      minMoistureLowerBound,
      minMoistureUpperBound,
    );
    _maxTemperature = _clamp(
      await _storage.getMaxTemperatureThreshold() ?? defaultMaxTemperature,
      maxTemperatureLowerBound,
      maxTemperatureUpperBound,
    );
    _maxHumidity = _clamp(
      await _storage.getMaxHumidityThreshold() ?? defaultMaxHumidity,
      maxHumidityLowerBound,
      maxHumidityUpperBound,
    );
    notifyListeners();
  }

  /// Updates the moisture warning-low boundary and optionally persists it.
  Future<void> setMinMoisture(double value, {bool persist = true}) async {
    _minMoisture = _clamp(value, minMoistureLowerBound, minMoistureUpperBound);
    notifyListeners();
    if (persist) {
      await _storage.saveMinMoistureThreshold(_minMoisture);
    }
  }

  /// Updates the temperature warning-high boundary and optionally persists it.
  Future<void> setMaxTemperature(double value, {bool persist = true}) async {
    _maxTemperature = _clamp(
      value,
      maxTemperatureLowerBound,
      maxTemperatureUpperBound,
    );
    notifyListeners();
    if (persist) {
      await _storage.saveMaxTemperatureThreshold(_maxTemperature);
    }
  }

  /// Updates the humidity warning-high boundary and optionally persists it.
  Future<void> setMaxHumidity(double value, {bool persist = true}) async {
    _maxHumidity = _clamp(value, maxHumidityLowerBound, maxHumidityUpperBound);
    notifyListeners();
    if (persist) {
      await _storage.saveMaxHumidityThreshold(_maxHumidity);
    }
  }

  double _clamp(double value, double minimum, double maximum) {
    return value.clamp(minimum, maximum).toDouble();
  }
}
