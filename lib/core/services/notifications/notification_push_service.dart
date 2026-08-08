import 'dart:async';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../features/alerts/domain/entities/alert_item.dart';
import '../../constants/app_assets.dart';
import '../../constants/sensor_db_constants.dart';
import '../../entities/app_user.dart';
import '../../providers/auth_session_provider.dart';
import '../alerts/alerts_store.dart';
import '../local_storage/local_storage_service.dart';
import '../logger/logger_service.dart';
import '../realtime_db/sensor_database_service.dart';
import '../settings/threshold_settings_service.dart';
import 'notification_local_handler.dart';

/// Registers this installation for FCM sensor alerts and handles messages
/// delivered while the Flutter application is in the foreground.
///
/// Sensor evaluation and the five-minute schedule live in Cloud Functions.
/// That is what allows notifications to continue after the app process has
/// been terminated by the operating system.
class NotificationPushService {
  NotificationPushService({
    required FirebaseMessaging messaging,
    required FirebaseDatabase database,
    required AuthSessionProvider authSession,
    required SensorDatabaseService sensorDatabase,
    required ThresholdSettingsService thresholdSettings,
    required NotificationLocalHandler localNotifications,
    required LocalStorageService localStorage,
    required AlertsStore alertsStore,
  }) : _messaging = messaging,
       _database = database,
       _authSession = authSession,
       _sensorDatabase = sensorDatabase,
       _thresholdSettings = thresholdSettings,
       _localNotifications = localNotifications,
       _localStorage = localStorage,
       _alertsStore = alertsStore;

  final FirebaseMessaging _messaging;
  final FirebaseDatabase _database;
  final AuthSessionProvider _authSession;
  final SensorDatabaseService _sensorDatabase;
  final ThresholdSettingsService _thresholdSettings;
  final NotificationLocalHandler _localNotifications;
  final LocalStorageService _localStorage;
  final AlertsStore _alertsStore;
  final LoggerService _logger = LoggerService(
    className: 'NotificationPushService',
  );

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  Timer? _thresholdSyncTimer;
  DatabaseReference? _registeredTokenReference;
  String? _registeredTokenPath;
  String? _registeredToken;
  bool _started = false;
  bool _notificationsEnabled = true;
  bool _permissionGranted = false;
  int _registrationGeneration = 0;
  final Set<String> _recordedMessageIds = <String>{};

  /// Initializes FCM, follows authentication/token changes, and registers the
  /// current installation under the linked RTDB sensor account.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    _logger.info(
      'Starting sensor push notification registration',
      tag: '[Notification][Push]',
    );

    _notificationsEnabled = await _localStorage.getNotificationsEnabled();
    await _refreshPermissionStatus();

    // Foreground notification messages are displayed through the local
    // plugin on both platforms. Disabling native foreground presentation on
    // Apple platforms prevents the same message appearing twice.
    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Could not configure foreground notification presentation',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: _logStreamError,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _recordAlert,
      onError: _logStreamError,
    );
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (String token) => unawaited(_registerCurrentInstallation(token: token)),
      onError: _logStreamError,
    );
    _authSession.addListener(_handleAuthChange);
    _thresholdSettings.addListener(_handleThresholdChange);

    try {
      final RemoteMessage? initialMessage = await _messaging
          .getInitialMessage();
      if (initialMessage != null) {
        _recordAlert(initialMessage);
      }
    } catch (error, stackTrace) {
      _logger.error(
        'Could not inspect the notification that opened the app',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await _registerCurrentInstallation();
  }

  /// Updates the server-side preference used by the Cloud Function sender.
  Future<void> setEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _localStorage.saveNotificationsEnabled(enabled);

    if (enabled) {
      await _refreshPermissionStatus();
    }

    await _syncRemotePreferences();
    if (enabled && _registeredTokenReference == null) {
      await _registerCurrentInstallation();
    }
  }

  /// Removes only this device token before an explicit account sign-out.
  /// Other devices registered to the same account continue receiving alerts.
  Future<void> unregisterCurrentDevice() async {
    _registrationGeneration++;
    final DatabaseReference? tokenReference = _registeredTokenReference;
    _registeredTokenReference = null;
    _registeredTokenPath = null;
    _registeredToken = null;

    if (tokenReference != null) {
      try {
        await tokenReference.remove();
      } catch (error, stackTrace) {
        _logger.error(
          'Could not remove the FCM token before sign-out',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    try {
      await _messaging.deleteToken();
    } catch (error, stackTrace) {
      _logger.error(
        'Could not invalidate the local FCM token before sign-out',
        error: error,
        stackTrace: stackTrace,
      );
    }
    await _localStorage.clearFcmToken();
  }

  /// Releases listeners. The app-wide singleton normally lives for the whole
  /// process, but an explicit stop keeps lifecycle ownership deterministic in
  /// tests and during dependency-container resets.
  Future<void> stop() async {
    if (!_started) {
      return;
    }
    _started = false;
    _registrationGeneration++;
    _thresholdSyncTimer?.cancel();
    _thresholdSyncTimer = null;
    _authSession.removeListener(_handleAuthChange);
    _thresholdSettings.removeListener(_handleThresholdChange);
    await Future.wait<void>(<Future<void>>[
      if (_foregroundSubscription != null) _foregroundSubscription!.cancel(),
      if (_openedSubscription != null) _openedSubscription!.cancel(),
      if (_tokenRefreshSubscription != null)
        _tokenRefreshSubscription!.cancel(),
    ]);
    _foregroundSubscription = null;
    _openedSubscription = null;
    _tokenRefreshSubscription = null;
  }

  void _handleAuthChange() {
    unawaited(_registerCurrentInstallation());
  }

  Future<void> _refreshPermissionStatus() async {
    try {
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _permissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!_permissionGranted) {
        _logger.warning('System notification permission was not granted.');
      }
    } catch (error, stackTrace) {
      _permissionGranted = false;
      _logger.error(
        'Could not request system notification permission',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleThresholdChange() {
    // Slider changes can fire rapidly. A short debounce keeps the remote
    // configuration current without writing once for every drag pixel.
    _thresholdSyncTimer?.cancel();
    _thresholdSyncTimer = Timer(
      const Duration(milliseconds: 500),
      () => unawaited(_syncRemotePreferences()),
    );
  }

  Future<void> _registerCurrentInstallation({String? token}) async {
    final int generation = ++_registrationGeneration;
    final AppUser? user = _authSession.user;
    if (!_started || user == null) {
      return;
    }

    try {
      final String? resolvedToken = token ?? await _messaging.getToken();
      if (resolvedToken == null || resolvedToken.isEmpty) {
        _logger.warning('FCM did not return a registration token.');
        return;
      }

      final String sensorUserKey = await _sensorDatabase.resolveUserKey(user);
      if (!_started || generation != _registrationGeneration) {
        return;
      }

      final DatabaseReference recipientReference = _database.ref(
        'notificationRecipients/$sensorUserKey/${user.uid}',
      );
      final String tokenKey = SensorDbConstants.sanitizeRtdbKey(resolvedToken);
      final String tokenPath =
          'notificationRecipients/$sensorUserKey/${user.uid}/tokens/$tokenKey';
      final DatabaseReference tokenReference = _database.ref(tokenPath);

      await recipientReference.update(_remotePreferences());
      await tokenReference.set(<String, Object>{
        'token': resolvedToken,
        'platform': Platform.operatingSystem,
        'updatedAt': ServerValue.timestamp,
      });

      if (!_started || generation != _registrationGeneration) {
        await tokenReference.remove();
        return;
      }

      final DatabaseReference? oldReference = _registeredTokenReference;
      final String? oldPath = _registeredTokenPath;
      final String? oldToken = _registeredToken;
      _registeredTokenReference = tokenReference;
      _registeredTokenPath = tokenPath;
      _registeredToken = resolvedToken;
      await _localStorage.saveFcmToken(resolvedToken);

      if (oldReference != null &&
          (oldPath != tokenPath || oldToken != resolvedToken)) {
        await oldReference.remove();
      }
      _logger.info(
        'Registered this device for sensor push alerts',
        tag: '[Notification][Push]',
        data: <String, Object>{
          'sensorUserKey': sensorUserKey,
          'enabled': _notificationsEnabled && _permissionGranted,
          'platform': Platform.operatingSystem,
        },
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Could not register this installation for sensor push alerts',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _syncRemotePreferences() async {
    final AppUser? user = _authSession.user;
    if (!_started || user == null) {
      return;
    }

    try {
      final String sensorUserKey = await _sensorDatabase.resolveUserKey(user);
      await _database
          .ref('notificationRecipients/$sensorUserKey/${user.uid}')
          .update(_remotePreferences());
      _logger.info(
        'Synchronized remote sensor alert preferences',
        tag: '[Notification][Push]',
        data: <String, Object>{
          'sensorUserKey': sensorUserKey,
          'enabled': _notificationsEnabled && _permissionGranted,
        },
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Could not synchronize sensor alert preferences',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Map<String, Object> _remotePreferences() {
    return <String, Object>{
      'enabled': _notificationsEnabled && _permissionGranted,
      'updatedAt': ServerValue.timestamp,
      'thresholds': <String, double>{
        'minTemperature': _thresholdSettings.minTemperature,
        'maxTemperature': _thresholdSettings.maxTemperature,
        'minHumidity': _thresholdSettings.minHumidity,
        'maxHumidity': _thresholdSettings.maxHumidity,
        'minMoisture': _thresholdSettings.minMoisture,
        'maxMoisture': _thresholdSettings.maxMoisture,
        'minLight': _thresholdSettings.minLight,
        'maxLight': _thresholdSettings.maxLight,
      },
    };
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.data['type'] != 'sensor_alert') {
      return;
    }
    _logger.info(
      'Received foreground sensor alert push',
      tag: '[Notification][Push]',
      data: <String, Object?>{
        'messageId': message.messageId,
        'metric': message.data['metric'],
        'severity': message.data['severity'],
      },
    );

    final String title =
        message.notification?.title ?? message.data['title'] ?? 'Sensor Alert';
    final String body =
        message.notification?.body ?? message.data['body'] ?? '';
    unawaited(
      _localNotifications
          .show(title: title, body: body, payload: message.data['metric'])
          .catchError((Object error, StackTrace stackTrace) {
            _logger.error(
              'Could not display a foreground push notification',
              error: error,
              stackTrace: stackTrace,
            );
          }),
    );
    _recordAlert(message);
  }

  void _recordAlert(RemoteMessage message) {
    if (message.data['type'] != 'sensor_alert') {
      return;
    }
    final String? messageId = message.messageId;
    if (messageId != null && !_recordedMessageIds.add(messageId)) {
      return;
    }

    final String metric = message.data['metric'] ?? '';
    final String title =
        message.notification?.title ?? message.data['title'] ?? 'Sensor Alert';
    final String popupBody =
        message.notification?.body ?? message.data['body'] ?? '';
    final AlertSeverity severity = message.data['severity'] == 'critical'
        ? AlertSeverity.critical
        : AlertSeverity.warning;
    final int? timestampMs = int.tryParse(message.data['timestamp'] ?? '');
    final int? createdAtMs = int.tryParse(message.data['createdAt'] ?? '');

    _alertsStore.addAlert(
      AlertItem(
        title: title,
        message: message.data['detailMessage'] ?? popupBody,
        recommendedAction: message.data['recommendedAction'] ?? '',
        timestamp: timestampMs == null
            ? message.sentTime ?? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(timestampMs),
        createdAt: createdAtMs == null
            ? message.sentTime ?? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(createdAtMs),
        severity: severity,
        icon: switch (metric) {
          'temperature' => AppAssets.temprature,
          'humidity' => AppAssets.cloud,
          'soilMoisture' => AppAssets.drop,
          'lightIntensity' => AppAssets.sun,
          _ => AppAssets.alert,
        },
      ),
    );
    _logger.info(
      'Recorded sensor alert in local in-app history',
      tag: '[Notification][Push]',
      data: <String, Object?>{
        'messageId': messageId,
        'metric': metric,
        'severity': severity.name,
      },
    );
  }

  void _logStreamError(Object error, StackTrace stackTrace) {
    _logger.error(
      'Firebase Messaging stream failed',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
