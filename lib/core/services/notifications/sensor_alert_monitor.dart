import 'dart:async';

import '../logger/logger_service.dart';
import '../realtime_db/sensor_database_service.dart';
import 'notification_local_handler.dart';

enum AlertZone { normal, warning, critical }

class _ZoneResult {
  const _ZoneResult(this.zone, [this.title = '', this.body = '']);

  final AlertZone zone;
  final String title;
  final String body;
}

/// Watches the live sensor stream and fires a local notification whenever a
/// metric crosses into (or between) the Warning/Critical zones defined by
/// the crop's optimum-condition table. Fires once per transition — repeated
/// readings that stay in the same zone do not re-notify.
class SensorAlertMonitor {
  SensorAlertMonitor({
    required this.sensorDatabase,
    required this.notificationHandler,
  });

  final SensorDatabaseService sensorDatabase;
  final NotificationLocalHandler notificationHandler;
  final LoggerService _logger = LoggerService(className: 'SensorAlertMonitor');

  StreamSubscription<FieldCurrentReading?>? _subscription;
  final Map<String, AlertZone> _lastZone = {};

  void start() {
    _subscription ??= sensorDatabase.watchCurrent().listen(
      _handleReading,
      onError: (Object error, StackTrace stackTrace) {
        _logger.error(
          'Sensor alert monitor stream failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _handleReading(FieldCurrentReading? reading) {
    if (reading == null) {
      return;
    }

    final Map<String, _ZoneResult?> results = {
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
        notificationHandler.show(
          title: result.title,
          body: result.body,
          payload: metric,
        );
      }
    });
  }

  // -- Zone tables --------------------------------------------------------
  // Boundaries below come directly from the crop's optimum-condition table.
  // Any gap the table leaves unlabeled between a Warning and a Critical
  // bound is treated as Warning, erring on the side of alerting sooner.

  _ZoneResult _temperatureZone(double value) {
    final String v = _fmt(value);
    if (value < 10) {
      return _ZoneResult(
        AlertZone.critical,
        'Critical: Low Temperature',
        'Temperature is $v°C — critical low. Frost risk to crops; take protective action.',
      );
    }
    if (value > 36) {
      return _ZoneResult(
        AlertZone.critical,
        'Critical: High Temperature',
        'Temperature is $v°C — critical high. Crops may be heat-stressed; take immediate action.',
      );
    }
    if (value < 20) {
      return _ZoneResult(
        AlertZone.warning,
        'Warning: Low Temperature',
        'Temperature is $v°C — below the optimal 20–30°C range.',
      );
    }
    if (value > 30) {
      return _ZoneResult(
        AlertZone.warning,
        'Warning: High Temperature',
        'Temperature is $v°C — above the optimal 20–30°C range.',
      );
    }
    return const _ZoneResult(AlertZone.normal);
  }

  _ZoneResult _humidityZone(double value) {
    final String v = _fmt(value);
    if (value < 40) {
      return _ZoneResult(
        AlertZone.critical,
        'Critical: Low Humidity',
        'Humidity is $v% — critical low. Crops may be under water stress.',
      );
    }
    if (value > 85) {
      return _ZoneResult(
        AlertZone.critical,
        'Critical: High Humidity',
        'Humidity is $v% — critical high. Elevated risk of fungal disease.',
      );
    }
    if (value < 60) {
      return _ZoneResult(
        AlertZone.warning,
        'Warning: Low Humidity',
        'Humidity is $v% — below the optimal 60–75% range.',
      );
    }
    if (value > 75) {
      return _ZoneResult(
        AlertZone.warning,
        'Warning: High Humidity',
        'Humidity is $v% — above the optimal 60–75% range.',
      );
    }
    return const _ZoneResult(AlertZone.normal);
  }

  _ZoneResult _soilMoistureZone(double value) {
    final String v = _fmt(value);
    if (value < 50) {
      return _ZoneResult(
        AlertZone.critical,
        'Critical: Low Soil Moisture',
        'Soil moisture is $v% — critical low. Irrigate immediately.',
      );
    }
    if (value > 90) {
      return _ZoneResult(
        AlertZone.critical,
        'Critical: High Soil Moisture',
        'Soil moisture is $v% — critical high. Risk of waterlogging/root damage.',
      );
    }
    if (value < 60) {
      return _ZoneResult(
        AlertZone.warning,
        'Warning: Low Soil Moisture',
        'Soil moisture is $v% — below the optimal 60–85% range.',
      );
    }
    if (value > 85) {
      return _ZoneResult(
        AlertZone.warning,
        'Warning: High Soil Moisture',
        'Soil moisture is $v% — above the optimal 60–85% range.',
      );
    }
    return const _ZoneResult(AlertZone.normal);
  }

  /// Light's critical-high bound only applies when combined with a
  /// temperature above 35°C, per the crop's optimum-condition table.
  _ZoneResult _lightZone(double lux, double? temperatureC) {
    final String v = _fmt(lux);
    if (lux < 20000) {
      return _ZoneResult(
        AlertZone.critical,
        'Critical: Low Light Intensity',
        'Light intensity is $v lux — critical low. Photosynthesis may be severely limited.',
      );
    }
    if (lux > 90000 && temperatureC != null && temperatureC > 35) {
      return _ZoneResult(
        AlertZone.critical,
        'Critical: High Light & Heat',
        'Light intensity is $v lux with temperature above 35°C — critical heat/light stress risk.',
      );
    }
    if (lux >= 45000 && lux <= 70000) {
      return const _ZoneResult(AlertZone.normal);
    }
    if (lux < 45000) {
      return _ZoneResult(
        AlertZone.warning,
        'Warning: Low Light Intensity',
        'Light intensity is $v lux — below the optimal 45,000–70,000 lux range.',
      );
    }
    return _ZoneResult(
      AlertZone.warning,
      'Warning: High Light Intensity',
      'Light intensity is $v lux — above the optimal 45,000–70,000 lux range.',
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
