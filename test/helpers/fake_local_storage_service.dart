import 'package:agrisenseaiapp/core/services/local_storage/local_storage_service.dart';

class FakeLocalStorageService extends LocalStorageService {
  final Map<String, CachedSensorStatus> sensorStatuses =
      <String, CachedSensorStatus>{};
  double? minTemperatureThreshold;
  double? maxTemperatureThreshold;
  double? minHumidityThreshold;
  double? maxHumidityThreshold;
  double? minMoistureThreshold;
  double? maxMoistureThreshold;
  double? minLightThreshold;
  double? maxLightThreshold;

  double? savedMinTemperatureThreshold;
  double? savedMaxTemperatureThreshold;
  double? savedMinHumidityThreshold;
  double? savedMaxHumidityThreshold;
  double? savedMinMoistureThreshold;
  double? savedMaxMoistureThreshold;
  double? savedMinLightThreshold;
  double? savedMaxLightThreshold;
  bool? notificationsEnabled;
  String? sensorAlertsJson;
  bool thresholdSettingsCleared = false;
  bool settingsAndPreferencesCleared = false;

  @override
  Future<CachedSensorStatus?> getLastSensorStatus({
    required String userId,
  }) async => sensorStatuses[userId];

  @override
  Future<void> saveLastSensorStatus({
    required String userId,
    required DateTime updatedAt,
    required bool isOnline,
  }) async {
    sensorStatuses[userId] = CachedSensorStatus(
      isOnline: isOnline,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<double?> getMinTemperatureThreshold() async => minTemperatureThreshold;

  @override
  Future<void> saveMinTemperatureThreshold(double value) async {
    savedMinTemperatureThreshold = value;
    minTemperatureThreshold = value;
  }

  @override
  Future<double?> getMaxTemperatureThreshold() async => maxTemperatureThreshold;

  @override
  Future<void> saveMaxTemperatureThreshold(double value) async {
    savedMaxTemperatureThreshold = value;
    maxTemperatureThreshold = value;
  }

  @override
  Future<double?> getMinHumidityThreshold() async => minHumidityThreshold;

  @override
  Future<void> saveMinHumidityThreshold(double value) async {
    savedMinHumidityThreshold = value;
    minHumidityThreshold = value;
  }

  @override
  Future<double?> getMaxHumidityThreshold() async => maxHumidityThreshold;

  @override
  Future<void> saveMaxHumidityThreshold(double value) async {
    savedMaxHumidityThreshold = value;
    maxHumidityThreshold = value;
  }

  @override
  Future<double?> getMinMoistureThreshold() async => minMoistureThreshold;

  @override
  Future<void> saveMinMoistureThreshold(double value) async {
    savedMinMoistureThreshold = value;
    minMoistureThreshold = value;
  }

  @override
  Future<double?> getMaxMoistureThreshold() async => maxMoistureThreshold;

  @override
  Future<void> saveMaxMoistureThreshold(double value) async {
    savedMaxMoistureThreshold = value;
    maxMoistureThreshold = value;
  }

  @override
  Future<double?> getMinLightThreshold() async => minLightThreshold;

  @override
  Future<void> saveMinLightThreshold(double value) async {
    savedMinLightThreshold = value;
    minLightThreshold = value;
  }

  @override
  Future<double?> getMaxLightThreshold() async => maxLightThreshold;

  @override
  Future<void> saveMaxLightThreshold(double value) async {
    savedMaxLightThreshold = value;
    maxLightThreshold = value;
  }

  @override
  Future<void> saveNotificationsEnabled(bool enabled) async {
    notificationsEnabled = enabled;
  }

  @override
  Future<bool> getNotificationsEnabled() async => notificationsEnabled ?? true;

  @override
  Future<String?> getSensorAlertsJson() async => sensorAlertsJson;

  @override
  Future<void> saveSensorAlertsJson(String json) async {
    sensorAlertsJson = json;
  }

  @override
  Future<void> clearSensorAlerts() async {
    sensorAlertsJson = null;
  }

  @override
  Future<void> clearThresholdSettings() async {
    thresholdSettingsCleared = true;
    minTemperatureThreshold = null;
    maxTemperatureThreshold = null;
    minHumidityThreshold = null;
    maxHumidityThreshold = null;
    minMoistureThreshold = null;
    maxMoistureThreshold = null;
    minLightThreshold = null;
    maxLightThreshold = null;
  }

  @override
  Future<void> clearSettingsAndPreferences() async {
    settingsAndPreferencesCleared = true;
    notificationsEnabled = null;
    sensorAlertsJson = null;
    await clearThresholdSettings();
  }
}
