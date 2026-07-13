import 'dart:async';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/sensor_db_constants.dart';
import '../../../../core/providers/auth_session_provider.dart';
import '../../../../core/services/realtime_db/sensor_database_service.dart';
import '../../../../core/services/settings/threshold_settings_service.dart';
import '../../../../core/utils/relative_time.dart';
import '../models/home_dashboard_model.dart';
import '../models/sensor_reading_model.dart';
import '../models/smart_action_model.dart';

abstract class HomeRemoteDataSource {
  Stream<HomeDashboardModel> watchDashboard();
  Future<void> setPumpStatus(bool isOn);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  HomeRemoteDataSourceImpl({
    required this.sensorDatabase,
    required this.authSessionProvider,
    required this.thresholdSettings,
  });

  final SensorDatabaseService sensorDatabase;
  final AuthSessionProvider authSessionProvider;
  final ThresholdSettingsService thresholdSettings;

  /// Re-emission cadence that keeps the "Updated Xm ago" label and the
  /// staleness-based online state fresh between database events.
  static const Duration _refreshInterval = Duration(seconds: 10);

  @override
  Stream<HomeDashboardModel> watchDashboard() {
    late StreamController<HomeDashboardModel> controller;
    StreamSubscription<FieldCurrentReading?>? currentSubscription;
    StreamSubscription<bool>? pumpSubscription;
    Timer? refreshTimer;
    bool isCancelled = false;

    FieldCurrentReading? reading;
    bool pumpOn = false;
    bool hasReading = false;

    void emit() {
      if (!hasReading || controller.isClosed) {
        return;
      }
      controller.add(_mapDashboard(reading, pumpOn));
    }

    controller = StreamController<HomeDashboardModel>(
      onListen: () async {
        try {
          final String userKey = await sensorDatabase.resolveUserKey(
            authSessionProvider.user,
          );
          if (isCancelled || controller.isClosed) {
            return;
          }

          currentSubscription = sensorDatabase
              .watchCurrent(userKey: userKey)
              .listen((FieldCurrentReading? value) {
                reading = value;
                hasReading = true;
                emit();
              }, onError: controller.addError);

          pumpSubscription = sensorDatabase.watchPumpStatus().listen((
            bool value,
          ) {
            pumpOn = value;
            emit();
          }, onError: controller.addError);

          refreshTimer = Timer.periodic(_refreshInterval, (_) => emit());
        } catch (error, stackTrace) {
          if (!isCancelled && !controller.isClosed) {
            controller.addError(error, stackTrace);
          }
        }
      },
      onCancel: () async {
        isCancelled = true;
        refreshTimer?.cancel();
        await currentSubscription?.cancel();
        await pumpSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> setPumpStatus(bool isOn) {
    return sensorDatabase.setPumpStatus(isOn);
  }

  HomeDashboardModel _mapDashboard(FieldCurrentReading? reading, bool pumpOn) {
    final DateTime? updatedAt = reading?.updatedAt;

    // Compare the sensor timestamp directly with now. The periodic re-emit
    // above keeps this status current even between Firebase events.
    final bool isOnline =
        updatedAt != null && SensorDbConstants.isReadingFresh(updatedAt);

    return HomeDashboardModel(
      greeting: 'Welcome back',
      fieldName: _fieldDisplayName(SensorDbConstants.defaultFieldKey),
      connectionStatus: isOnline ? 'Device Online' : 'Device Offline',
      smartAction: _buildSmartAction(reading),
      updatedLabel: updatedAt == null
          ? 'No data yet'
          : 'Updated ${relativeTime(updatedAt)}',
      sensors: _buildSensors(reading),
      deviceOnline: isOnline,
      updatedAt: updatedAt,
      pumpOn: pumpOn,
    );
  }

  List<SensorReadingModel> _buildSensors(FieldCurrentReading? reading) {
    final double? moisture = _roundToDisplay(reading?.soilMoisturePercent);
    final double? temperature = _roundToDisplay(reading?.temperatureC);
    final double? humidity = _roundToDisplay(reading?.humidityPercent);
    final double? light = reading?.lightLux;

    final bool moistureWarning =
        moisture == null || !thresholdSettings.isSoilMoistureNormal(moisture);
    final bool temperatureWarning =
        temperature == null ||
        !thresholdSettings.isTemperatureNormal(temperature);
    final bool humidityWarning =
        humidity == null || !thresholdSettings.isHumidityNormal(humidity);
    final bool lightWarning =
        light == null || !thresholdSettings.isLightIntensityNormal(light);

    return [
      SensorReadingModel(
        label: 'Soil Moisture',
        value: _formatValue(moisture),
        unit: '%',
        icon: AppAssets.drop,
        iconColorKey: moistureWarning ? 'yellow' : 'blue',
        statusColorKey: moistureWarning ? 'yellow' : 'primary',
      ),
      SensorReadingModel(
        label: 'Temperature',
        value: _formatValue(temperature),
        unit: '°C',
        icon: AppAssets.temprature,
        iconColorKey: temperatureWarning ? 'yellow' : 'primary',
        statusColorKey: temperatureWarning ? 'yellow' : 'primary',
      ),
      SensorReadingModel(
        label: 'Humidity',
        value: _formatValue(humidity),
        unit: '%',
        icon: AppAssets.cloud,
        iconColorKey: humidityWarning ? 'yellow' : 'blue',
        statusColorKey: humidityWarning ? 'yellow' : 'primary',
      ),
      SensorReadingModel(
        label: 'Light Intensity',
        value: _formatValue(light),
        unit: 'lx',
        icon: AppAssets.sun,
        iconColorKey: 'yellow',
        statusColorKey: lightWarning ? 'yellow' : 'primary',
      ),
    ];
  }

  SmartActionModel _buildSmartAction(FieldCurrentReading? reading) {
    // Compare the same rounded value that gets displayed, so the message
    // can never claim a reading is past a threshold it displays as equal to.
    final double? moisture = _roundToDisplay(reading?.soilMoisturePercent);
    final double? temperature = _roundToDisplay(reading?.temperatureC);
    final double? humidity = _roundToDisplay(reading?.humidityPercent);
    final double? light = _roundToDisplay(reading?.lightLux);

    if (moisture == null &&
        temperature == null &&
        humidity == null &&
        light == null) {
      return const SmartActionModel(
        title: 'Smart Action',
        message:
            'Waiting for sensor data. Insights will appear once your '
            'device is ',
        highlight: 'online.',
      );
    }

    if (moisture != null && moisture < thresholdSettings.minMoisture) {
      return SmartActionModel(
        title: 'Smart Action',
        message:
            'Soil moisture is at ${_formatValue(moisture)}%, below the '
            '${_formatValue(thresholdSettings.minMoisture)}% threshold. ',
        highlight: 'Irrigation recommended.',
      );
    }

    if (moisture != null &&
        moisture > ThresholdSettingsService.soilMoistureWarningHigh) {
      return SmartActionModel(
        title: 'Smart Action',
        message:
            'Soil moisture is at ${_formatValue(moisture)}%, above the '
            '${ThresholdSettingsService.soilMoistureWarningHigh.round()}% '
            'optimal range. ',
        highlight: 'Pause irrigation and check drainage.',
      );
    }

    if (temperature != null && temperature > thresholdSettings.maxTemperature) {
      return SmartActionModel(
        title: 'Smart Action',
        message:
            'Temperature is ${_formatValue(temperature)}°C, above the '
            '${_formatValue(thresholdSettings.maxTemperature)}°C threshold. '
            'Consider irrigating during ',
        highlight: 'cooler hours.',
      );
    }

    if (temperature != null &&
        temperature < ThresholdSettingsService.temperatureWarningLow) {
      return SmartActionModel(
        title: 'Smart Action',
        message:
            'Temperature is ${_formatValue(temperature)}°C, below the '
            '${ThresholdSettingsService.temperatureWarningLow.round()}°C '
            'optimal range. ',
        highlight: 'Protect crops from cold stress.',
      );
    }

    if (humidity != null && humidity > thresholdSettings.maxHumidity) {
      return SmartActionModel(
        title: 'Smart Action',
        message:
            'Humidity is ${_formatValue(humidity)}%, above the '
            '${_formatValue(thresholdSettings.maxHumidity)}% threshold. ',
        highlight: 'Improve ventilation and monitor disease risk.',
      );
    }

    if (humidity != null &&
        humidity < ThresholdSettingsService.humidityWarningLow) {
      return SmartActionModel(
        title: 'Smart Action',
        message:
            'Humidity is ${_formatValue(humidity)}%, below the '
            '${ThresholdSettingsService.humidityWarningLow.round()}% '
            'optimal range. ',
        highlight: 'Watch for crop water stress.',
      );
    }

    if (light != null && light < ThresholdSettingsService.lightWarningLow) {
      return const SmartActionModel(
        title: 'Smart Action',
        message: 'Light intensity is below the optimal crop range. ',
        highlight: 'Check for excessive shading.',
      );
    }

    if (light != null && light > ThresholdSettingsService.lightWarningHigh) {
      return const SmartActionModel(
        title: 'Smart Action',
        message: 'Light intensity is above the optimal crop range. ',
        highlight: 'Monitor heat and light stress.',
      );
    }

    if (moisture == null ||
        temperature == null ||
        humidity == null ||
        light == null) {
      return const SmartActionModel(
        title: 'Smart Action',
        message: 'One or more sensors is not reporting. ',
        highlight: 'Check the probe connections.',
      );
    }

    return const SmartActionModel(
      title: 'Smart Action',
      message: 'Soil and climate conditions look healthy. ',
      highlight: 'No action needed.',
    );
  }

  String _fieldDisplayName(String fieldKey) {
    final List<String> parts = fieldKey
        .split('_')
        .where((String part) => part.isNotEmpty)
        .map((String part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .toList();
    return parts.isEmpty ? 'My Field' : parts.join(' ');
  }

  String _formatValue(double? value) {
    if (value == null) {
      return '--';
    }
    final double rounded = _roundToDisplay(value)!;
    if (rounded == rounded.roundToDouble()) {
      return rounded.round().toString();
    }
    return rounded.toStringAsFixed(1);
  }

  double? _roundToDisplay(double? value) {
    if (value == null) {
      return null;
    }
    return (value * 10).roundToDouble() / 10;
  }
}
