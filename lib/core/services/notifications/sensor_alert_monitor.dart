import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../features/alerts/domain/entities/alert_item.dart';
import '../../constants/app_assets.dart';
import '../../entities/app_user.dart';
import '../../providers/auth_session_provider.dart';
import '../../utils/relative_time.dart';
import '../alerts/alerts_store.dart';
import '../logger/logger_service.dart';
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

/// Watches live sensor readings and emits one alert per zone transition.
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
  }) : _currentUser = (() => authSessionProvider.user),
       _resolveUserKey = sensorDatabase.resolveUserKey,
       _watchCurrent = sensorDatabase.watchCurrent,
       _showNotification = notificationHandler.show;

  /// Creates a monitor with deterministic I/O seams for focused unit tests.
  @visibleForTesting
  SensorAlertMonitor.forTesting({
    required AppUser? Function() currentUser,
    required SensorUserKeyResolver resolveUserKey,
    required SensorCurrentWatcher watchCurrent,
    required SensorNotificationPresenter showNotification,
    required this.thresholdSettings,
    required this.alertsStore,
  }) : _currentUser = currentUser,
       _resolveUserKey = resolveUserKey,
       _watchCurrent = watchCurrent,
       _showNotification = showNotification;

  final ThresholdSettingsService thresholdSettings;
  final AlertsStore alertsStore;
  final AppUser? Function() _currentUser;
  final SensorUserKeyResolver _resolveUserKey;
  final SensorCurrentWatcher _watchCurrent;
  final SensorNotificationPresenter _showNotification;
  final LoggerService _logger = LoggerService(className: 'SensorAlertMonitor');

  StreamSubscription<FieldCurrentReading?>? _subscription;
  final Map<String, AlertZone> _lastZone = <String, AlertZone>{};
  bool _shouldRun = false;
  int _startGeneration = 0;

  /// Resolves the active user's field and starts monitoring its live readings.
  Future<void> start() async {
    if (_shouldRun) {
      return;
    }
    _shouldRun = true;
    final int generation = ++_startGeneration;

    try {
      final String userKey = await _resolveUserKey(_currentUser());
      if (!_shouldRun || generation != _startGeneration) {
        return;
      }

      _subscription = _watchCurrent(userKey: userKey).listen(
        _handleReading,
        onError: (Object error, StackTrace stackTrace) {
          _logger.error(
            'Sensor alert monitor stream failed',
            error: error,
            stackTrace: stackTrace,
          );
        },
        onDone: () {
          if (generation == _startGeneration) {
            _subscription = null;
            _shouldRun = false;
          }
        },
      );
    } catch (error, stackTrace) {
      if (generation == _startGeneration) {
        _shouldRun = false;
      }
      _logger.error(
        'Could not start the sensor alert monitor',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Stops monitoring without changing the remembered zone transitions.
  Future<void> stop() async {
    _shouldRun = false;
    _startGeneration++;
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handleReading(FieldCurrentReading? reading) {
    if (reading == null) {
      return;
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
      final AlertZone previousZone = _lastZone[metric] ?? AlertZone.normal;
      _lastZone[metric] = result.zone;

      if (result.zone != AlertZone.normal && result.zone != previousZone) {
        _emitAlert(metric, result);
      }
    });
  }

  void _emitAlert(String metric, _ZoneResult result) {
    unawaited(
      _showNotification(
        title: result.title,
        body: result.body,
        payload: metric,
      ).catchError((Object error, StackTrace stackTrace) {
        _logger.error(
          'Could not display sensor notification',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );

    final DateTime timestamp = DateTime.now();
    alertsStore.addAlert(
      AlertItem(
        title: result.title,
        message: result.body,
        timeLabel: relativeTime(timestamp),
        timestamp: timestamp,
        severity: result.zone == AlertZone.critical
            ? AlertSeverity.critical
            : AlertSeverity.warning,
        icon: result.icon,
      ),
    );
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
    if (value < ThresholdSettingsService.temperatureWarningLow) {
      return _ZoneResult(
        AlertZone.warning,
        title: 'Warning: Low Temperature',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'warning low',
        thresholdValue: ThresholdSettingsService.temperatureWarningLow,
        icon: AppAssets.temprature,
        body:
            '$metric is $formattedValue$unit — below the warning threshold '
            'of ${_fmt(ThresholdSettingsService.temperatureWarningLow)}$unit.',
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
    if (value < ThresholdSettingsService.humidityWarningLow) {
      return _ZoneResult(
        AlertZone.warning,
        title: 'Warning: Low Humidity',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'warning low',
        thresholdValue: ThresholdSettingsService.humidityWarningLow,
        icon: AppAssets.cloud,
        body:
            '$metric is $formattedValue$unit — below the warning threshold '
            'of ${_fmt(ThresholdSettingsService.humidityWarningLow)}$unit.',
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
    if (value > ThresholdSettingsService.soilMoistureWarningHigh) {
      return _ZoneResult(
        AlertZone.warning,
        title: 'Warning: High Soil Moisture',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'warning high',
        thresholdValue: ThresholdSettingsService.soilMoistureWarningHigh,
        icon: AppAssets.drop,
        body:
            '$metric is $formattedValue$unit — above the warning threshold '
            'of ${_fmt(ThresholdSettingsService.soilMoistureWarningHigh)}$unit.',
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
    if (value >= ThresholdSettingsService.lightWarningLow &&
        value <= ThresholdSettingsService.lightWarningHigh) {
      return const _ZoneResult(AlertZone.normal);
    }
    if (value < ThresholdSettingsService.lightWarningLow) {
      return _ZoneResult(
        AlertZone.warning,
        title: 'Warning: Low Light Intensity',
        metricLabel: metric,
        value: value,
        unit: unit,
        thresholdLabel: 'warning low',
        thresholdValue: ThresholdSettingsService.lightWarningLow,
        icon: AppAssets.sun,
        body:
            '$metric is $formattedValue$unit — below the warning threshold '
            'of ${_fmt(ThresholdSettingsService.lightWarningLow)}$unit.',
      );
    }
    return _ZoneResult(
      AlertZone.warning,
      title: 'Warning: High Light Intensity',
      metricLabel: metric,
      value: value,
      unit: unit,
      thresholdLabel: 'warning high',
      thresholdValue: ThresholdSettingsService.lightWarningHigh,
      icon: AppAssets.sun,
      body:
          '$metric is $formattedValue$unit — above the warning threshold '
          'of ${_fmt(ThresholdSettingsService.lightWarningHigh)}$unit.',
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
