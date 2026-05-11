import '../logger/logger_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LoggerService _appLogger = LoggerService(className: "Local Storage");

  // Storage keys
  static const String _authStateKey = 'auth_state';
  static const String _expiryTimeKey = 'auth_expiry_time';
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _notificationsEnabledKey = 'notifications_enabled';

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
    await _secureStorage.delete(key: _authStateKey);
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
}
