import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logger/logger_service.dart';

class CachedSensorStatus {
  const CachedSensorStatus({required this.isOnline, required this.updatedAt});

  final bool isOnline;
  final DateTime updatedAt;
}

class LocalStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LoggerService _appLogger = LoggerService(className: "Local Storage");

  // Storage keys
  static const String _authStateKey = 'auth_state';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _expiryTimeKey = 'auth_expiry_time';
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _minTemperatureThresholdKey = 'min_temperature_threshold';
  static const String _minMoistureThresholdKey = 'min_moisture_threshold';
  static const String _maxTemperatureThresholdKey = 'max_temperature_threshold';
  static const String _minHumidityThresholdKey = 'min_humidity_threshold';
  static const String _maxHumidityThresholdKey = 'max_humidity_threshold';
  static const String _maxMoistureThresholdKey = 'max_moisture_threshold';
  static const String _minLightThresholdKey = 'min_light_threshold';
  static const String _maxLightThresholdKey = 'max_light_threshold';
  static const String _sensorAlertsKey = 'sensor_alerts';
  static const String _sensorMonitorUserIdKey = 'sensor_monitor_user_id';
  static const String _sensorMonitorUserKey = 'sensor_monitor_user_key';
  static const String _lastSensorStatusUserIdKey = 'last_sensor_status_user_id';
  static const String _lastSensorStatusUpdatedAtKey =
      'last_sensor_status_updated_at';
  static const String _lastSensorStatusOnlineKey = 'last_sensor_status_online';

  // ============ AUTH TOKEN METHODS ============

  /// Get stored access token
  Future<String?> getAccessToken() async {
    _appLogger.info("Retrieving access token", tag: "[Auth][Storage]");
    final token = await _secureStorage.read(key: _accessTokenKey);
    return token;
  }

  /// Save access token securely
  Future<void> saveAccessToken(String token) async {
    _appLogger.info("Saving access token", tag: "[Auth][Storage]");
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    _appLogger.info("Retrieving refresh token", tag: "[Auth][Storage]");
    final token = await _secureStorage.read(key: _refreshTokenKey);
    return token;
  }

  /// Save refresh token securely
  Future<void> saveRefreshToken(String token) async {
    _appLogger.info("Saving refresh token", tag: "[Auth][Storage]");
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  /// Get token expiry time (ISO 8601 format)
  Future<String?> getExpiryTime() async {
    _appLogger.info("Retrieving token expiry time", tag: "[Auth][Storage]");
    final expiryStr = await _secureStorage.read(key: _expiryTimeKey);
    return expiryStr;
  }

  /// Save token expiry time (ISO 8601 format)
  Future<void> saveExpiryTime(String isoTimestamp) async {
    _appLogger.info(
      "Saving token expiry time: $isoTimestamp",
      tag: "[Auth][Storage]",
    );
    await _secureStorage.write(key: _expiryTimeKey, value: isoTimestamp);
  }

  /// Clear all authentication-related tokens
  Future<void> clearTokens() async {
    _appLogger.info(
      "Clearing all authentication tokens",
      tag: "[Auth][Storage]",
    );
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _expiryTimeKey);
  }

  /// Get stored auth state ('signed' or 'guest')
  Future<String?> getAuthState() async {
    _appLogger.info("Retrieving auth state", tag: "[Auth][Storage]");
    final state = await _secureStorage.read(key: _authStateKey);
    return state;
  }

  /// Save auth state ('signed' or 'guest')
  Future<void> saveAuthState(String state) async {
    _appLogger.info("Saving auth state: $state", tag: "[Auth][Storage]");
    await _secureStorage.write(key: _authStateKey, value: state);
  }

  /// Clear all auth-related data (tokens + state + FCM token + cached profile)
  Future<void> clearAuthData() async {
    _appLogger.info("Clearing all authentication data", tag: "[Auth][Storage]");
    await clearTokens();
    await clearFcmToken();
    await clearSensorMonitorTarget();
    await _secureStorage.delete(key: _authStateKey);
  }

  // ============ ONBOARDING METHODS ============

  /// Returns whether the user has completed onboarding.
  Future<bool> getOnboardingCompleted() async {
    final stored = await _secureStorage.read(key: _onboardingCompletedKey);
    if (stored == null) return false;
    return stored == 'true';
  }

  /// Persist onboarding completion state.
  Future<void> saveOnboardingCompleted(bool completed) async {
    await _secureStorage.write(
      key: _onboardingCompletedKey,
      value: completed.toString(),
    );
  }

  // ============ FCM TOKEN METHODS ============

  /// Save FCM device token (used for push notifications)
  Future<void> saveFcmToken(String token) async {
    _appLogger.info("Saving FCM token", tag: "[Notification][Storage]");
    await _secureStorage.write(key: _fcmTokenKey, value: token);
  }

  /// Get stored FCM token
  Future<String?> getFcmToken() async {
    _appLogger.info("Retrieving FCM token", tag: "[Notification][Storage]");
    return _secureStorage.read(key: _fcmTokenKey);
  }

  /// Clear stored FCM token
  Future<void> clearFcmToken() async {
    _appLogger.info("Clearing FCM token", tag: "[Notification][Storage]");
    await _secureStorage.delete(key: _fcmTokenKey);
  }

  // ============ NOTIFICATION PREFERENCES ============

  /// Returns whether the user has enabled push notifications.
  /// Defaults to true when unset (first install / pre-toggle state).
  Future<bool> getNotificationsEnabled() async {
    final stored = await _secureStorage.read(key: _notificationsEnabledKey);
    if (stored == null) return true;
    return stored == 'true';
  }

  /// Persist the user's notifications-enabled preference.
  Future<void> saveNotificationsEnabled(bool enabled) async {
    _appLogger.info(
      "Saving notifications enabled: $enabled",
      tag: "[Notification][Storage]",
    );
    await _secureStorage.write(
      key: _notificationsEnabledKey,
      value: enabled.toString(),
    );
  }

  // ============ SENSOR ALERT HISTORY ============

  /// Returns the serialized Warning/Critical alerts saved on this device.
  Future<String?> getSensorAlertsJson() {
    return _secureStorage.read(key: _sensorAlertsKey);
  }

  /// Persists the bounded in-app Warning/Critical alert history.
  Future<void> saveSensorAlertsJson(String json) {
    return _secureStorage.write(key: _sensorAlertsKey, value: json);
  }

  Future<void> clearSensorAlerts() {
    return _secureStorage.delete(key: _sensorAlertsKey);
  }

  // ============ BACKGROUND SENSOR MONITOR ============

  /// Persists the RTDB field owner selected while the authenticated UI is
  /// active. A WorkManager isolate can then read the correct field without
  /// waiting for Firebase Auth restoration.
  Future<void> saveSensorMonitorTarget({
    required String userId,
    required String userKey,
  }) async {
    await Future.wait<void>(<Future<void>>[
      _secureStorage.write(key: _sensorMonitorUserIdKey, value: userId),
      _secureStorage.write(key: _sensorMonitorUserKey, value: userKey),
    ]);
  }

  Future<({String userId, String userKey})?> getSensorMonitorTarget() async {
    final List<String?> values = await Future.wait<String?>(<Future<String?>>[
      _secureStorage.read(key: _sensorMonitorUserIdKey),
      _secureStorage.read(key: _sensorMonitorUserKey),
    ]);
    final String? userId = values[0];
    final String? userKey = values[1];
    if (userId == null ||
        userId.isEmpty ||
        userKey == null ||
        userKey.isEmpty) {
      return null;
    }
    return (userId: userId, userKey: userKey);
  }

  Future<void> clearSensorMonitorTarget() async {
    await Future.wait<void>(<Future<void>>[
      _secureStorage.delete(key: _sensorMonitorUserIdKey),
      _secureStorage.delete(key: _sensorMonitorUserKey),
    ]);
  }

  Future<void> saveLastSensorStatus({
    required String userId,
    required DateTime updatedAt,
    required bool isOnline,
  }) async {
    await Future.wait<void>(<Future<void>>[
      _secureStorage.write(key: _lastSensorStatusUserIdKey, value: userId),
      _secureStorage.write(
        key: _lastSensorStatusUpdatedAtKey,
        value: updatedAt.millisecondsSinceEpoch.toString(),
      ),
      _secureStorage.write(
        key: _lastSensorStatusOnlineKey,
        value: isOnline.toString(),
      ),
    ]);
  }

  Future<CachedSensorStatus?> getLastSensorStatus({
    required String userId,
  }) async {
    final List<String?> values = await Future.wait<String?>(<Future<String?>>[
      _secureStorage.read(key: _lastSensorStatusUserIdKey),
      _secureStorage.read(key: _lastSensorStatusUpdatedAtKey),
      _secureStorage.read(key: _lastSensorStatusOnlineKey),
    ]);
    if (values[0] != userId) {
      return null;
    }
    final int? milliseconds = int.tryParse(values[1] ?? '');
    final bool? isOnline = switch (values[2]) {
      'true' => true,
      'false' => false,
      _ => null,
    };
    if (milliseconds == null || isOnline == null) {
      return null;
    }
    return CachedSensorStatus(
      isOnline: isOnline,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(milliseconds),
    );
  }

  // ============ SENSOR THRESHOLDS ============

  Future<double?> _getThreshold(String key) async {
    final String? stored = await _secureStorage.read(key: key);
    return double.tryParse(stored ?? '');
  }

  Future<void> _saveThreshold(String key, double value) {
    return _secureStorage.write(key: key, value: value.toString());
  }

  Future<double?> getMinTemperatureThreshold() {
    return _getThreshold(_minTemperatureThresholdKey);
  }

  Future<void> saveMinTemperatureThreshold(double value) {
    return _saveThreshold(_minTemperatureThresholdKey, value);
  }

  /// Returns the persisted minimum soil-moisture warning boundary.
  Future<double?> getMinMoistureThreshold() {
    return _getThreshold(_minMoistureThresholdKey);
  }

  /// Persists the minimum soil-moisture warning boundary.
  Future<void> saveMinMoistureThreshold(double value) {
    return _saveThreshold(_minMoistureThresholdKey, value);
  }

  /// Returns the persisted maximum-temperature warning boundary.
  Future<double?> getMaxTemperatureThreshold() {
    return _getThreshold(_maxTemperatureThresholdKey);
  }

  /// Persists the maximum-temperature warning boundary.
  Future<void> saveMaxTemperatureThreshold(double value) {
    return _saveThreshold(_maxTemperatureThresholdKey, value);
  }

  Future<double?> getMinHumidityThreshold() {
    return _getThreshold(_minHumidityThresholdKey);
  }

  Future<void> saveMinHumidityThreshold(double value) {
    return _saveThreshold(_minHumidityThresholdKey, value);
  }

  /// Returns the persisted maximum-humidity warning boundary.
  Future<double?> getMaxHumidityThreshold() {
    return _getThreshold(_maxHumidityThresholdKey);
  }

  /// Persists the maximum-humidity warning boundary.
  Future<void> saveMaxHumidityThreshold(double value) {
    return _saveThreshold(_maxHumidityThresholdKey, value);
  }

  Future<double?> getMaxMoistureThreshold() {
    return _getThreshold(_maxMoistureThresholdKey);
  }

  Future<void> saveMaxMoistureThreshold(double value) {
    return _saveThreshold(_maxMoistureThresholdKey, value);
  }

  Future<double?> getMinLightThreshold() {
    return _getThreshold(_minLightThresholdKey);
  }

  Future<void> saveMinLightThreshold(double value) {
    return _saveThreshold(_minLightThresholdKey, value);
  }

  Future<double?> getMaxLightThreshold() {
    return _getThreshold(_maxLightThresholdKey);
  }

  Future<void> saveMaxLightThreshold(double value) {
    return _saveThreshold(_maxLightThresholdKey, value);
  }

  Future<void> clearThresholdSettings() async {
    await Future.wait(<Future<void>>[
      _secureStorage.delete(key: _minTemperatureThresholdKey),
      _secureStorage.delete(key: _maxTemperatureThresholdKey),
      _secureStorage.delete(key: _minHumidityThresholdKey),
      _secureStorage.delete(key: _maxHumidityThresholdKey),
      _secureStorage.delete(key: _minMoistureThresholdKey),
      _secureStorage.delete(key: _maxMoistureThresholdKey),
      _secureStorage.delete(key: _minLightThresholdKey),
      _secureStorage.delete(key: _maxLightThresholdKey),
    ]);
  }

  /// Clears user-configurable settings while preserving authentication and
  /// onboarding, so the Settings screen returns to first-install defaults.
  Future<void> clearSettingsAndPreferences() async {
    await clearThresholdSettings();
    await Future.wait(<Future<void>>[
      _secureStorage.delete(key: _notificationsEnabledKey),
      clearSensorAlerts(),
    ]);
  }
}
