import 'dart:async';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/sensor_db_constants.dart';
import '../../../../core/services/realtime_db/sensor_database_service.dart';
import '../../../../core/utils/relative_time.dart';
import '../models/home_dashboard_model.dart';
import '../models/sensor_reading_model.dart';
import '../models/smart_action_model.dart';

abstract class HomeRemoteDataSource {
  Stream<HomeDashboardModel> watchDashboard();
  Future<void> setPumpStatus(bool isOn);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  HomeRemoteDataSourceImpl({required this.sensorDatabase});

  final SensorDatabaseService sensorDatabase;

  /// Re-emission cadence that keeps the "Updated Xm ago" label and the
  /// staleness-based online state fresh between database events.
  static const Duration _refreshInterval = Duration(minutes: 1);

  @override
  Stream<HomeDashboardModel> watchDashboard() {
    late StreamController<HomeDashboardModel> controller;
    StreamSubscription<FieldCurrentReading?>? currentSubscription;
    StreamSubscription<bool>? pumpSubscription;
    Timer? refreshTimer;

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
      onListen: () {
        currentSubscription = sensorDatabase.watchCurrent().listen((
          FieldCurrentReading? value,
        ) {
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
      },
      onCancel: () async {
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
    final bool isFresh =
        updatedAt != null &&
        DateTime.now().difference(updatedAt) <
            SensorDbConstants.onlineStaleness;
    final bool isOnline = (reading?.deviceOnline ?? false) && isFresh;

    return HomeDashboardModel(
      greeting: 'Welcome back',
      fieldName: _fieldDisplayName(SensorDbConstants.defaultFieldKey),
      connectionStatus: isOnline ? 'Device Connected (Live)' : 'Device Offline',
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
        moisture == null || moisture < SensorThresholds.minSoilMoisturePercent;
    final bool temperatureWarning =
        temperature == null || temperature > SensorThresholds.maxTemperatureC;
    final bool humidityWarning =
        humidity == null ||
        humidity < SensorThresholds.minHumidityPercent ||
        humidity > SensorThresholds.maxHumidityPercent;

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
        statusColorKey: light == null ? 'yellow' : 'primary',
      ),
    ];
  }

  SmartActionModel _buildSmartAction(FieldCurrentReading? reading) {
    // Compare the same rounded value that gets displayed, so the message
    // can never claim a reading is past a threshold it displays as equal to.
    final double? moisture = _roundToDisplay(reading?.soilMoisturePercent);
    final double? temperature = _roundToDisplay(reading?.temperatureC);

    if (moisture == null && temperature == null) {
      return const SmartActionModel(
        title: 'Smart Action',
        message:
            'Waiting for sensor data. Insights will appear once your '
            'device is ',
        highlight: 'online.',
      );
    }

    if (moisture != null &&
        moisture < SensorThresholds.minSoilMoisturePercent) {
      return SmartActionModel(
        title: 'Smart Action',
        message:
            'Soil moisture is at ${_formatValue(moisture)}%, below the '
            '${SensorThresholds.minSoilMoisturePercent.round()}% threshold. ',
        highlight: 'Irrigation recommended.',
      );
    }

    if (temperature != null && temperature > SensorThresholds.maxTemperatureC) {
      return SmartActionModel(
        title: 'Smart Action',
        message:
            'Temperature is ${_formatValue(temperature)}°C, above the '
            '${SensorThresholds.maxTemperatureC.round()}°C threshold. '
            'Consider irrigating during ',
        highlight: 'cooler hours.',
      );
    }

    if (moisture == null || temperature == null) {
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
