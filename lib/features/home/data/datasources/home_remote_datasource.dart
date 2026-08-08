import 'dart:async';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/sensor_db_constants.dart';
import '../../../../core/entities/app_user.dart';
import '../../../../core/providers/auth_session_provider.dart';
import '../../../../core/services/realtime_db/sensor_database_service.dart';
import '../../../../core/services/local_storage/local_storage_service.dart';
import '../../../../core/services/settings/threshold_settings_service.dart';
import '../../../../core/utils/relative_time.dart';
import '../../domain/entities/home_dashboard.dart';
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
    this.storage,
  });

  final LiveSensorDatabase sensorDatabase;
  final AuthSession authSessionProvider;
  final ThresholdSettingsService thresholdSettings;
  final LocalStorageService? storage;

  /// Re-emission cadence that keeps the "Updated Xm ago" label and the
  /// staleness-based online state fresh between database events.
  static const Duration _refreshInterval = Duration(seconds: 10);

  @override
  Stream<HomeDashboardModel> watchDashboard() {
    late StreamController<HomeDashboardModel> controller;
    StreamSubscription<FieldCurrentReading?>? currentSubscription;
    StreamSubscription<bool>? pumpSubscription;
    Timer? refreshTimer;
    bool isActive = false;
    int bindingGeneration = 0;
    String? boundAuthState;

    FieldCurrentReading? reading;
    DateTime? lastConfirmedUpdatedAt;
    bool pumpOn = false;
    DeviceStatus deviceStatus = DeviceStatus.unknown;
    bool? lastCachedOnline;

    void emit() {
      if (controller.isClosed) {
        return;
      }
      controller.add(
        _mapDashboard(
          reading,
          pumpOn,
          deviceStatus: deviceStatus,
          lastConfirmedUpdatedAt: lastConfirmedUpdatedAt,
        ),
      );
    }

    void cacheStatus(AppUser user) {
      final DateTime? updatedAt = lastConfirmedUpdatedAt;
      final bool? isOnline = switch (deviceStatus) {
        DeviceStatus.online => true,
        DeviceStatus.offline => false,
        _ => null,
      };
      if (updatedAt == null ||
          isOnline == null ||
          lastCachedOnline == isOnline) {
        return;
      }
      lastCachedOnline = isOnline;
      unawaited(
        storage?.saveLastSensorStatus(
              userId: user.uid,
              updatedAt: updatedAt,
              isOnline: isOnline,
            ) ??
            Future<void>.value(),
      );
    }

    void acceptReading(FieldCurrentReading? value, AppUser user) {
      if (value == null) {
        return;
      }
      reading = value;
      final DateTime? updatedAt = value.updatedAt;
      if (updatedAt == null) {
        emit();
        return;
      }
      lastConfirmedUpdatedAt = updatedAt;
      lastCachedOnline = null;
      deviceStatus = SensorDbConstants.isReadingFresh(updatedAt)
          ? DeviceStatus.online
          : DeviceStatus.offline;
      cacheStatus(user);
      emit();
    }

    String? identityOf(AppUser? user) {
      if (user == null) {
        return null;
      }
      return '${user.uid}\u0000${user.email ?? ''}\u0000${user.phoneNumber ?? ''}';
    }

    Future<void> bindCurrentUser() async {
      final int generation = ++bindingGeneration;
      final AppUser? user = authSessionProvider.user;

      await currentSubscription?.cancel();
      currentSubscription = null;
      await pumpSubscription?.cancel();
      pumpSubscription = null;

      if (!isActive || generation != bindingGeneration) {
        return;
      }

      reading = null;
      pumpOn = false;
      lastConfirmedUpdatedAt = null;
      lastCachedOnline = null;
      deviceStatus = DeviceStatus.loading;
      emit();

      if (!authSessionProvider.isReady || user == null) {
        return;
      }

      try {
        final CachedSensorStatus? cached = await storage?.getLastSensorStatus(
          userId: user.uid,
        );
        if (!isActive || generation != bindingGeneration) {
          return;
        }
        lastConfirmedUpdatedAt = cached?.updatedAt;
        lastCachedOnline = cached?.isOnline;
        if (cached != null &&
            SensorDbConstants.isReadingFresh(cached.updatedAt)) {
          deviceStatus = DeviceStatus.online;
          emit();
        }
      } catch (_) {
        // A local cache failure must not classify the Firebase device offline.
      }

      pumpSubscription = sensorDatabase
          .watchPumpStatus(userUid: user.uid)
          .listen(
            (bool value) {
              if (!isActive || generation != bindingGeneration) {
                return;
              }
              pumpOn = value;
              emit();
            },
            onError: (Object error, StackTrace stackTrace) {
              if (isActive &&
                  generation == bindingGeneration &&
                  !controller.isClosed) {
                controller.addError(error, stackTrace);
              }
            },
          );

      try {
        final String userKey = await sensorDatabase.resolveUserKey(user);
        if (!isActive || generation != bindingGeneration) {
          return;
        }

        try {
          final FieldCurrentReading? initialReading = await sensorDatabase
              .getCurrent(userKey: userKey);
          if (!isActive || generation != bindingGeneration) {
            return;
          }
          acceptReading(initialReading, user);
        } catch (_) {
          if (!isActive || generation != bindingGeneration) {
            return;
          }
          deviceStatus = DeviceStatus.error;
          emit();
        }

        currentSubscription = sensorDatabase
            .watchCurrent(userKey: userKey)
            .listen(
              (FieldCurrentReading? value) {
                if (!isActive || generation != bindingGeneration) {
                  return;
                }
                acceptReading(value, user);
              },
              onError: (Object _, StackTrace _) {
                if (isActive &&
                    generation == bindingGeneration &&
                    !controller.isClosed) {
                  deviceStatus = DeviceStatus.error;
                  emit();
                }
              },
            );
      } catch (_) {
        if (isActive &&
            generation == bindingGeneration &&
            !controller.isClosed) {
          deviceStatus = DeviceStatus.error;
          emit();
        }
      }
    }

    void handleAuthChange() {
      final String? identity = identityOf(authSessionProvider.user);
      final String authState =
          '${authSessionProvider.isReady}\u0000${identity ?? ''}';
      if (authState == boundAuthState) {
        return;
      }
      boundAuthState = authState;
      unawaited(bindCurrentUser());
    }

    controller = StreamController<HomeDashboardModel>(
      onListen: () {
        isActive = true;
        authSessionProvider.addListener(handleAuthChange);
        refreshTimer = Timer.periodic(_refreshInterval, (_) {
          final AppUser? user = authSessionProvider.user;
          final DateTime? updatedAt = lastConfirmedUpdatedAt;
          if (user != null &&
              updatedAt != null &&
              (deviceStatus == DeviceStatus.online ||
                  deviceStatus == DeviceStatus.offline)) {
            final DeviceStatus refreshedStatus =
                SensorDbConstants.isReadingFresh(updatedAt)
                ? DeviceStatus.online
                : DeviceStatus.offline;
            if (refreshedStatus != deviceStatus) {
              deviceStatus = refreshedStatus;
              cacheStatus(user);
            }
          }
          emit();
        });
        handleAuthChange();
      },
      onCancel: () async {
        isActive = false;
        bindingGeneration++;
        authSessionProvider.removeListener(handleAuthChange);
        refreshTimer?.cancel();
        await currentSubscription?.cancel();
        await pumpSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> setPumpStatus(bool isOn) {
    final AppUser? user = authSessionProvider.user;
    if (user == null) {
      throw StateError(
        'An authenticated user is required to control the pump.',
      );
    }
    return sensorDatabase.setPumpStatus(userUid: user.uid, isOn: isOn);
  }

  HomeDashboardModel _mapDashboard(
    FieldCurrentReading? reading,
    bool pumpOn, {
    required DeviceStatus deviceStatus,
    DateTime? lastConfirmedUpdatedAt,
  }) {
    final DateTime? updatedAt = reading?.updatedAt ?? lastConfirmedUpdatedAt;

    return HomeDashboardModel(
      greeting: 'Welcome back',
      fieldName: _fieldDisplayName(SensorDbConstants.defaultFieldKey),
      connectionStatus: switch (deviceStatus) {
        DeviceStatus.online => 'Online',
        DeviceStatus.offline => 'Offline',
        DeviceStatus.error => 'Unable to check status',
        DeviceStatus.unknown || DeviceStatus.loading => 'Checking status...',
      },
      smartAction: _buildSmartAction(reading),
      updatedLabel: updatedAt == null
          ? 'No data yet'
          : 'Updated ${relativeTime(updatedAt)}',
      sensors: _buildSensors(reading),
      deviceStatus: deviceStatus,
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

    if (moisture != null && moisture > thresholdSettings.maxMoisture) {
      return SmartActionModel(
        title: 'Smart Action',
        message:
            'Soil moisture is at ${_formatValue(moisture)}%, above the '
            '${_formatValue(thresholdSettings.maxMoisture)}% '
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

    if (temperature != null && temperature < thresholdSettings.minTemperature) {
      return SmartActionModel(
        title: 'Smart Action',
        message:
            'Temperature is ${_formatValue(temperature)}°C, below the '
            '${_formatValue(thresholdSettings.minTemperature)}°C '
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

    if (humidity != null && humidity < thresholdSettings.minHumidity) {
      return SmartActionModel(
        title: 'Smart Action',
        message:
            'Humidity is ${_formatValue(humidity)}%, below the '
            '${_formatValue(thresholdSettings.minHumidity)}% '
            'optimal range. ',
        highlight: 'Watch for crop water stress.',
      );
    }

    if (light != null && light < thresholdSettings.minLight) {
      return SmartActionModel(
        title: 'Smart Action',
        message:
            'Light intensity is ${_formatValue(light)} lx, below the '
            '${_formatValue(thresholdSettings.minLight)} lx threshold. ',
        highlight: 'Check for excessive shading.',
      );
    }

    if (light != null && light > thresholdSettings.maxLight) {
      return SmartActionModel(
        title: 'Smart Action',
        message:
            'Light intensity is ${_formatValue(light)} lx, above the '
            '${_formatValue(thresholdSettings.maxLight)} lx threshold. ',
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
