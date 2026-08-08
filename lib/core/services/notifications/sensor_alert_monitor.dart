import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../features/alerts/domain/entities/alert_item.dart';
import '../../constants/app_assets.dart';
import '../../constants/sensor_db_constants.dart';
import '../../entities/app_user.dart';
import '../../providers/auth_session_provider.dart';
import '../alerts/alerts_store.dart';
import '../logger/logger_service.dart';
import '../local_storage/local_storage_service.dart';
import '../realtime_db/sensor_database_service.dart';
import '../settings/threshold_settings_service.dart';
import 'notification_local_handler.dart';

enum AlertZone { normal, warning, critical }

/// Resolves the RTDB key for the current authenticated user.
typedef SensorUserKeyResolver = Future<String> Function(AppUser? user);

/// Opens the live current-reading stream for a resolved RTDB user key.
typedef SensorCurrentWatcher =
    Stream<FieldCurrentReading?> Function({required String userKey});

/// Displays an operating-system notification for a sensor transition.
typedef SensorNotificationPresenter =
    Future<void> Function({
      required String title,
      required String body,
      String? payload,
    });

class _ZoneResult {
  const _ZoneResult(
    this.zone, {
    this.title = '',
    this.metricLabel = '',
    this.value = 0,
    this.unit = '',
    this.thresholdLabel = '',
    this.thresholdValue = 0,
    this.icon = '',
    this.body = '',
  });

  final AlertZone zone;
  final String title;
  final String metricLabel;
  final double value;
  final String unit;
  final String thresholdLabel;
  final double thresholdValue;
  final String icon;
  final String body;
}

/// Watches fresh live readings and emits alerts at a fixed online interval.
///
/// Every Warning/Critical transition drives both the operating-system
/// notification and the in-app [AlertsStore] from the same structured result.
class SensorAlertMonitor {
  SensorAlertMonitor({
    required SensorDatabaseService sensorDatabase,
    required NotificationLocalHandler notificationHandler,
    required AuthSessionProvider authSessionProvider,
    required this.thresholdSettings,
    required this.alertsStore,
    LocalStorageService? storage,
  }) : _authSession = authSessionProvider,
       _currentUser = (() => authSessionProvider.user),
       _resolveUserKey = sensorDatabase.resolveUserKey,
       _watchCurrent = sensorDatabase.watchCurrent,
       _showNotification = notificationHandler.show,
       _now = DateTime.now,
       _storage = storage;

  /// Creates a monitor with deterministic I/O seams for focused unit tests.
  @visibleForTesting
  SensorAlertMonitor.forTesting({
    required AppUser? Function() currentUser,
    required SensorUserKeyResolver resolveUserKey,
    required SensorCurrentWatcher watchCurrent,
    required SensorNotificationPresenter showNotification,
    required this.thresholdSettings,
    required this.alertsStore,
    AuthSession? authSession,
    DateTime Function()? now,
  }) : _authSession = authSession,
       _currentUser = currentUser,
       _resolveUserKey = resolveUserKey,
       _watchCurrent = watchCurrent,
       _showNotification = showNotification,
       _now = now ?? DateTime.now,
       _storage = null;

  /// Builds a one-shot evaluator for an Android background worker.
  SensorAlertMonitor.forBackground({
    required SensorUserKeyResolver resolveUserKey,
    required SensorCurrentWatcher watchCurrent,
    required SensorNotificationPresenter showNotification,
    required this.thresholdSettings,
    required this.alertsStore,
    required AppUser user,
  }) : _authSession = null,
       _currentUser = (() => user),
       _resolveUserKey = resolveUserKey,
       _watchCurrent = watchCurrent,
       _showNotification = showNotification,
       _now = DateTime.now,
       _storage = null;

  static const Duration notificationInterval = Duration(minutes: 5);

  final ThresholdSettingsService thresholdSettings;
  final AlertsStore alertsStore;
  final AuthSession? _authSession;
  final AppUser? Function() _currentUser;
  final SensorUserKeyResolver _resolveUserKey;
  final SensorCurrentWatcher _watchCurrent;
  final SensorNotificationPresenter _showNotification;
  final DateTime Function() _now;
  final LoggerService _logger = LoggerService(className: 'SensorAlertMonitor');
  final LocalStorageService? _storage;

  StreamSubscription<FieldCurrentReading?>? _subscription;
  final Map<String, String> _activeConditionByMetric = <String, String>{};
  final Map<String, DateTime> _nextNotificationAt = <String, DateTime>{};
  DateTime? _lastReadingUpdatedAt;
  bool _shouldRun = false;
  int _startGeneration = 0;
  String? _boundUserIdentity;
  List<Future<void>>? _backgroundEmissions;
  final Set<String> _inFlightEventIds = <String>{};

  /// Starts monitoring and follows Google Sign-In account changes.
  Future<void> start() async {
    if (_shouldRun) {
      return;
    }
    _shouldRun = true;
    _authSession?.addListener(_handleAuthChange);
    await _bindCurrentUser(force: true);
  }

  void _handleAuthChange() {
    unawaited(_bindCurrentUser());
  }

  Future<void> _bindCurrentUser({bool force = false}) async {
    final AppUser? user = _currentUser();
    final String? identity = _identityOf(user);
    if (!force && identity == _boundUserIdentity) {
      return;
    }
    _boundUserIdentity = identity;
    final int generation = ++_startGeneration;

    final StreamSubscription<FieldCurrentReading?>? previousSubscription =
        _subscription;
    _subscription = null;
    _activeConditionByMetric.clear();
    _nextNotificationAt.clear();
    _lastReadingUpdatedAt = null;

    try {
      await previousSubscription?.cancel();
      if (!_shouldRun || generation != _startGeneration || user == null) {
        return;
      }

      final String userKey = await _resolveUserKey(user);
      unawaited(
        _storage?.saveSensorMonitorTarget(userId: user.uid, userKey: userKey) ??
            Future<void>.value(),
      );
      if (!_shouldRun || generation != _startGeneration) {
        return;
      }

      _subscription = _watchCurrent(userKey: userKey).listen(
        _handleReading,
        onError: (Object error, StackTrace stackTrace) {
          _markOffline();
          _logger.error(
            'Sensor alert monitor stream failed',
            error: error,
            stackTrace: stackTrace,
          );
        },
        onDone: () {
          if (generation == _startGeneration) {
            _subscription = null;
            _markOffline();
          }
        },
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Could not start the sensor alert monitor',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String? _identityOf(AppUser? user) {
    if (user == null) {
      return null;
    }
    return '${user.uid}\u0000${user.email ?? ''}\u0000${user.phoneNumber ?? ''}';
  }

  /// Stops monitoring and detaches from authentication changes.
  Future<void> stop() async {
    _shouldRun = false;
    _startGeneration++;
    _authSession?.removeListener(_handleAuthChange);
    _boundUserIdentity = null;
    await _subscription?.cancel();
    _subscription = null;
    _activeConditionByMetric.clear();
    _nextNotificationAt.clear();
    _lastReadingUpdatedAt = null;
  }

  void _handleReading(FieldCurrentReading? reading) {
    _evaluateReading(reading);
  }

  /// Evaluates one reading from an Android background worker. The worker is
  /// invoked at the monitoring cadence, so a new warning condition is emitted
  /// immediately rather than waiting for a live-stream transition.
  Future<void> evaluateBackgroundReading(FieldCurrentReading? reading) async {
    _backgroundEmissions = <Future<void>>[];
    _evaluateReading(reading, notifyOnConditionStart: true);
    final List<Future<void>> emissions = _backgroundEmissions!;
    _backgroundEmissions = null;
    await Future.wait(emissions);
  }

  void _evaluateReading(
    FieldCurrentReading? reading, {
    bool notifyOnConditionStart = false,
  }) {
    if (reading == null) {
      _markOffline();
      return;
    }

    final DateTime now = _now();
    final DateTime? updatedAt = reading.updatedAt;
    if (updatedAt == null ||
        !SensorDbConstants.isReadingFresh(updatedAt, now: now)) {
      _markOffline(lastReadingUpdatedAt: updatedAt);
      return;
    }

    final DateTime? previousUpdatedAt = _lastReadingUpdatedAt;
    final bool startsNewOnlineSession =
        previousUpdatedAt == null ||
        updatedAt.difference(previousUpdatedAt).abs() >
            SensorDbConstants.onlineStaleness;
    _lastReadingUpdatedAt = updatedAt;
    if (startsNewOnlineSession) {
      _resetNotificationSchedule();
    }

    final Map<String, _ZoneResult?> results = <String, _ZoneResult?>{
      'temperature': reading.temperatureC == null
          ? null
          : _temperatureZone(reading.temperatureC!),
      'humidity': reading.humidityPercent == null
          ? null
          : _humidityZone(reading.humidityPercent!),
      'soilMoisture': reading.soilMoisturePercent == null
          ? null
          : _soilMoistureZone(reading.soilMoisturePercent!),
      'lightIntensity': reading.lightLux == null
          ? null
          : _lightZone(reading.lightLux!, reading.temperatureC),
    };

    results.forEach((String metric, _ZoneResult? result) {
      if (result == null) {
        return;
      }
      final String? previousCondition = _activeConditionByMetric[metric];
      if (result.zone == AlertZone.normal) {
        _activeConditionByMetric.remove(metric);
        if (previousCondition != null) {
          _nextNotificationAt.remove(previousCondition);
        }
        return;
      }

      final String condition = '$metric:${result.title}';
      final bool conditionChanged = condition != previousCondition;
      if (conditionChanged) {
        if (previousCondition != null) {
          _nextNotificationAt.remove(previousCondition);
        }
        _activeConditionByMetric[metric] = condition;
        _nextNotificationAt[condition] = now.add(notificationInterval);
        if (notifyOnConditionStart) {
          _queueAlert(metric, result, timestamp: now);
        }
        return;
      }

      final DateTime nextNotification =
          _nextNotificationAt[condition] ?? now.add(notificationInterval);
      _nextNotificationAt.putIfAbsent(condition, () => nextNotification);
      if (!now.isBefore(nextNotification)) {
        _nextNotificationAt[condition] = now.add(notificationInterval);
        _queueAlert(metric, result, timestamp: now);
      }
    });
  }

  void _markOffline({DateTime? lastReadingUpdatedAt}) {
    _lastReadingUpdatedAt = lastReadingUpdatedAt;
    _resetNotificationSchedule();
  }

  void _resetNotificationSchedule() {
    _activeConditionByMetric.clear();
    _nextNotificationAt.clear();
  }

  void _queueAlert(
    String metric,
    _ZoneResult result, {
    required DateTime timestamp,
  }) {
    final Future<void> emission = _emitAlert(
      metric,
      result,
      timestamp: timestamp,
    );
    final List<Future<void>>? backgroundEmissions = _backgroundEmissions;
    if (backgroundEmissions != null) {
      backgroundEmissions.add(emission);
    } else {
      unawaited(emission);
    }
  }

  Future<void> _emitAlert(
    String metric,
    _ZoneResult result, {
    required DateTime timestamp,
  }) async {
    final AlertSeverity severity = result.zone == AlertZone.critical
        ? AlertSeverity.critical
        : AlertSeverity.warning;
    final String eventId =
        '$metric:${severity.name}:${timestamp.millisecondsSinceEpoch}';
    if (!_inFlightEventIds.add(eventId)) {
      return;
    }
    final AlertItem event = AlertItem(
      eventId: eventId,
      title: result.title,
      message:
          'Sensor: ${result.metricLabel}\n'
          'Current value: ${_fmt(result.value)}${result.unit}\n'
          'Severity: ${severity == AlertSeverity.critical ? 'Critical' : 'Warning'}\n'
          'Threshold: ${result.thresholdLabel} '
          '(${_fmt(result.thresholdValue)}${result.unit})\n'
          'Message: ${result.body}\n'
          'Time: ${_formatTimestamp(timestamp)}',
      timestamp: timestamp,
      severity: severity,
      icon: result.icon,
    );
    try {
      final Future<void> popup = _showNotification(
        title: event.title,
        body: event.message,
        payload: metric,
      );
      alertsStore.addAlert(event);
      await popup;
      await alertsStore.flush();
    } catch (error, stackTrace) {
      alertsStore.removeEvent(eventId);
      _logger.error(
        'Could not display sensor notification',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _inFlightEventIds.remove(eventId);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${timestamp.year}-${twoDigits(timestamp.month)}-'
        '${twoDigits(timestamp.day)} ${twoDigits(timestamp.hour)}:'
        '${twoDigits(timestamp.minute)}:${twoDigits(timestamp.second)} '
        '${timestamp.timeZoneName}';
  }

  _ZoneResult _temperatureZone(double value) {
    const String metric = 'Temperature';
    const String unit = '°C';
    final String formattedValue = _fmt(value);

    if (value < ThresholdSettingsService.temperatureCriticalLow) {
      return _ZoneResult(
        AlertZone.critical,
        title: 'Critical: Low Temperature',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'critical low',
        thresholdValue: ThresholdSettingsService.temperatureCriticalLow,
        icon: AppAssets.temprature,
        body:
            '$metric is $formattedValue$unit — below the critical threshold '
            'of ${_fmt(ThresholdSettingsService.temperatureCriticalLow)}$unit. '
            'Frost risk to crops; take protective action.',
      );
    }
    if (value > ThresholdSettingsService.temperatureCriticalHigh) {
      return _ZoneResult(
        AlertZone.critical,
        title: 'Critical: High Temperature',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'critical high',
        thresholdValue: ThresholdSettingsService.temperatureCriticalHigh,
        icon: AppAssets.temprature,
        body:
            '$metric is $formattedValue$unit — above the critical threshold '
            'of ${_fmt(ThresholdSettingsService.temperatureCriticalHigh)}$unit. '
            'Crops may be heat-stressed; take immediate action.',
      );
    }
    if (value < thresholdSettings.minTemperature) {
      return _ZoneResult(
        AlertZone.warning,
        title: 'Warning: Low Temperature',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'configured warning low',
        thresholdValue: thresholdSettings.minTemperature,
        icon: AppAssets.temprature,
        body:
            '$metric is $formattedValue$unit — below your configured threshold '
            'of ${_fmt(thresholdSettings.minTemperature)}$unit.',
      );
    }
    if (value > thresholdSettings.maxTemperature) {
      return _ZoneResult(
        AlertZone.warning,
        title: 'Warning: High Temperature',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'configured warning high',
        thresholdValue: thresholdSettings.maxTemperature,
        icon: AppAssets.temprature,
        body:
            '$metric is $formattedValue$unit — above your configured threshold '
            'of ${_fmt(thresholdSettings.maxTemperature)}$unit.',
      );
    }
    return const _ZoneResult(AlertZone.normal);
  }

  _ZoneResult _humidityZone(double value) {
    const String metric = 'Humidity';
    const String unit = '%';
    final String formattedValue = _fmt(value);

    if (value < ThresholdSettingsService.humidityCriticalLow) {
      return _ZoneResult(
        AlertZone.critical,
        title: 'Critical: Low Humidity',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'critical low',
        thresholdValue: ThresholdSettingsService.humidityCriticalLow,
        icon: AppAssets.cloud,
        body:
            '$metric is $formattedValue$unit — below the critical threshold '
            'of ${_fmt(ThresholdSettingsService.humidityCriticalLow)}$unit. '
            'Crops may be under water stress.',
      );
    }
    if (value > ThresholdSettingsService.humidityCriticalHigh) {
      return _ZoneResult(
        AlertZone.critical,
        title: 'Critical: High Humidity',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'critical high',
        thresholdValue: ThresholdSettingsService.humidityCriticalHigh,
        icon: AppAssets.cloud,
        body:
            '$metric is $formattedValue$unit — above the critical threshold '
            'of ${_fmt(ThresholdSettingsService.humidityCriticalHigh)}$unit. '
            'Elevated risk of fungal disease.',
      );
    }
    if (value < thresholdSettings.minHumidity) {
      return _ZoneResult(
        AlertZone.warning,
        title: 'Warning: Low Humidity',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'configured warning low',
        thresholdValue: thresholdSettings.minHumidity,
        icon: AppAssets.cloud,
        body:
            '$metric is $formattedValue$unit — below your configured threshold '
            'of ${_fmt(thresholdSettings.minHumidity)}$unit.',
      );
    }
    if (value > thresholdSettings.maxHumidity) {
      return _ZoneResult(
        AlertZone.warning,
        title: 'Warning: High Humidity',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'configured warning high',
        thresholdValue: thresholdSettings.maxHumidity,
        icon: AppAssets.cloud,
        body:
            '$metric is $formattedValue$unit — above your configured threshold '
            'of ${_fmt(thresholdSettings.maxHumidity)}$unit.',
      );
    }
    return const _ZoneResult(AlertZone.normal);
  }

  _ZoneResult _soilMoistureZone(double value) {
    const String metric = 'Soil Moisture';
    const String unit = '%';
    final String formattedValue = _fmt(value);

    if (value < ThresholdSettingsService.soilMoistureCriticalLow) {
      return _ZoneResult(
        AlertZone.critical,
        title: 'Critical: Low Soil Moisture',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'critical low',
        thresholdValue: ThresholdSettingsService.soilMoistureCriticalLow,
        icon: AppAssets.drop,
        body:
            '$metric is $formattedValue$unit — below the critical threshold '
            'of ${_fmt(ThresholdSettingsService.soilMoistureCriticalLow)}$unit. '
            'Irrigate immediately.',
      );
    }
    if (value > ThresholdSettingsService.soilMoistureCriticalHigh) {
      return _ZoneResult(
        AlertZone.critical,
        title: 'Critical: High Soil Moisture',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'critical high',
        thresholdValue: ThresholdSettingsService.soilMoistureCriticalHigh,
        icon: AppAssets.drop,
        body:
            '$metric is $formattedValue$unit — above the critical threshold '
            'of ${_fmt(ThresholdSettingsService.soilMoistureCriticalHigh)}$unit. '
            'Risk of waterlogging or root damage.',
      );
    }
    if (value < thresholdSettings.minMoisture) {
      return _ZoneResult(
        AlertZone.warning,
        title: 'Warning: Low Soil Moisture',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'configured warning low',
        thresholdValue: thresholdSettings.minMoisture,
        icon: AppAssets.drop,
        body:
            '$metric is $formattedValue$unit — below your configured threshold '
            'of ${_fmt(thresholdSettings.minMoisture)}$unit.',
      );
    }
    if (value > thresholdSettings.maxMoisture) {
      return _ZoneResult(
        AlertZone.warning,
        title: 'Warning: High Soil Moisture',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'configured warning high',
        thresholdValue: thresholdSettings.maxMoisture,
        icon: AppAssets.drop,
        body:
            '$metric is $formattedValue$unit — above your configured threshold '
            'of ${_fmt(thresholdSettings.maxMoisture)}$unit.',
      );
    }
    return const _ZoneResult(AlertZone.normal);
  }

  _ZoneResult _lightZone(double value, double? temperatureC) {
    const String metric = 'Light Intensity';
    const String unit = ' lux';
    final String formattedValue = _fmt(value);

    if (value < ThresholdSettingsService.lightCriticalLow) {
      return _ZoneResult(
        AlertZone.critical,
        title: 'Critical: Low Light Intensity',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'critical low',
        thresholdValue: ThresholdSettingsService.lightCriticalLow,
        icon: AppAssets.sun,
        body:
            '$metric is $formattedValue$unit — below the critical threshold '
            'of ${_fmt(ThresholdSettingsService.lightCriticalLow)}$unit. '
            'Photosynthesis may be severely limited.',
      );
    }
    if (value > ThresholdSettingsService.lightCriticalHigh &&
        temperatureC != null &&
        temperatureC > ThresholdSettingsService.lightCriticalHighTemperature) {
      return _ZoneResult(
        AlertZone.critical,
        title: 'Critical: High Light & Heat',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'critical high with heat',
        thresholdValue: ThresholdSettingsService.lightCriticalHigh,
        icon: AppAssets.sun,
        body:
            '$metric is $formattedValue$unit — above the critical threshold '
            'of ${_fmt(ThresholdSettingsService.lightCriticalHigh)}$unit while '
            'temperature is above '
            '${_fmt(ThresholdSettingsService.lightCriticalHighTemperature)}°C. '
            'Crops face critical heat and light stress.',
      );
    }
    if (value >= thresholdSettings.minLight &&
        value <= thresholdSettings.maxLight) {
      return const _ZoneResult(AlertZone.normal);
    }
    if (value < thresholdSettings.minLight) {
      return _ZoneResult(
        AlertZone.warning,
        title: 'Warning: Low Light Intensity',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'configured warning low',
        thresholdValue: thresholdSettings.minLight,
        icon: AppAssets.sun,
        body:
            '$metric is $formattedValue$unit — below your configured threshold '
            'of ${_fmt(thresholdSettings.minLight)}$unit.',
      );
    }
    return _ZoneResult(
      AlertZone.warning,
      title: 'Warning: High Light Intensity',
      metricLabel: metric,
      value: value,
      unit: unit,
      thresholdLabel: 'configured warning high',
      thresholdValue: thresholdSettings.maxLight,
      icon: AppAssets.sun,
      body:
          '$metric is $formattedValue$unit — above your configured threshold '
          'of ${_fmt(thresholdSettings.maxLight)}$unit.',
    );
  }

  String _fmt(double value) {
    final double rounded = (value * 10).roundToDouble() / 10;
    if (rounded == rounded.roundToDouble()) {
      return rounded.round().toString();
    }
    return rounded.toStringAsFixed(1);
  }
}
