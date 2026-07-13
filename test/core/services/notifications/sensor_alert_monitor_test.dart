import 'dart:async';

import 'package:agrisenseaiapp/core/entities/app_user.dart';
import 'package:agrisenseaiapp/core/services/alerts/alerts_store.dart';
import 'package:agrisenseaiapp/core/services/local_storage/local_storage_service.dart';
import 'package:agrisenseaiapp/core/services/notifications/sensor_alert_monitor.dart';
import 'package:agrisenseaiapp/core/services/realtime_db/sensor_database_service.dart';
import 'package:agrisenseaiapp/core/services/settings/threshold_settings_service.dart';
import 'package:agrisenseaiapp/features/alerts/domain/entities/alert_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monitor emits OS and in-app alerts once per zone transition', () async {
    final StreamController<FieldCurrentReading?> readings =
        StreamController<FieldCurrentReading?>.broadcast(sync: true);
    final AlertsStore alertsStore = AlertsStore();
    final ThresholdSettingsService thresholds = ThresholdSettingsService(
      storage: LocalStorageService(),
    );
    await thresholds.setMaxTemperature(30, persist: false);
    await thresholds.setMaxHumidity(80, persist: false);
    await thresholds.setMinMoisture(65, persist: false);

    const AppUser user = AppUser(uid: 'user-1', email: 'farmer@example.com');
    AppUser? resolvedUser;
    String? watchedKey;
    final notifications = <({String title, String body, String? payload})>[];
    final SensorAlertMonitor monitor = SensorAlertMonitor.forTesting(
      currentUser: () => user,
      resolveUserKey: (AppUser? currentUser) async {
        resolvedUser = currentUser;
        return 'farmer_example_com';
      },
      watchCurrent: ({required String userKey}) {
        watchedKey = userKey;
        return readings.stream;
      },
      showNotification:
          ({
            required String title,
            required String body,
            String? payload,
          }) async {
            notifications.add((title: title, body: body, payload: payload));
          },
      thresholdSettings: thresholds,
      alertsStore: alertsStore,
    );

    await monitor.start();
    expect(resolvedUser, same(user));
    expect(watchedKey, 'farmer_example_com');

    readings.add(
      const FieldCurrentReading(
        deviceOnline: true,
        temperatureC: 31,
        humidityPercent: 81,
        soilMoisturePercent: 64,
        lightLux: 44000,
      ),
    );

    expect(alertsStore.liveItems, hasLength(4));
    expect(notifications, hasLength(4));
    expect(
      _findAlert(alertsStore, 'Warning: High Temperature').message,
      contains('configured threshold of 30°C'),
    );
    expect(
      _findAlert(alertsStore, 'Warning: High Humidity').message,
      contains('configured threshold of 80%'),
    );
    expect(
      _findAlert(alertsStore, 'Warning: Low Soil Moisture').message,
      contains('configured threshold of 65%'),
    );
    expect(
      _findAlert(alertsStore, 'Warning: Low Light Intensity').message,
      contains('warning threshold of 45000 lux'),
    );

    readings.add(
      const FieldCurrentReading(
        deviceOnline: true,
        temperatureC: 32,
        humidityPercent: 82,
        soilMoisturePercent: 63,
        lightLux: 43000,
      ),
    );
    expect(alertsStore.liveItems, hasLength(4));
    expect(notifications, hasLength(4));

    readings.add(
      const FieldCurrentReading(
        deviceOnline: true,
        temperatureC: 25,
        humidityPercent: 70,
        soilMoisturePercent: 70,
        lightLux: 50000,
      ),
    );
    readings.add(
      const FieldCurrentReading(
        deviceOnline: true,
        temperatureC: 37,
        humidityPercent: 86,
        soilMoisturePercent: 49,
        lightLux: 91000,
      ),
    );

    expect(alertsStore.liveItems, hasLength(8));
    expect(notifications, hasLength(8));
    final AlertItem temperature = _findAlert(
      alertsStore,
      'Critical: High Temperature',
    );
    expect(temperature.severity, AlertSeverity.critical);
    expect(temperature.message, contains('critical threshold of 36°C'));
    expect(temperature.timeLabel, 'just now');
    expect(
      _findAlert(alertsStore, 'Critical: High Light & Heat').message,
      allOf(contains('90000 lux'), contains('35°C')),
    );
    expect(
      notifications.map((notification) => notification.payload).toSet(),
      <String>{'temperature', 'humidity', 'soilMoisture', 'lightIntensity'},
    );

    await monitor.stop();
    await readings.close();
  });

  test('stale async starts cannot create duplicate sensor streams', () async {
    final Completer<String> firstResolution = Completer<String>();
    final Completer<String> secondResolution = Completer<String>();
    final StreamController<FieldCurrentReading?> readings =
        StreamController<FieldCurrentReading?>.broadcast();
    final List<String> watchedKeys = <String>[];
    int resolutionCalls = 0;
    final SensorAlertMonitor monitor = SensorAlertMonitor.forTesting(
      currentUser: () => null,
      resolveUserKey: (AppUser? _) {
        resolutionCalls++;
        return resolutionCalls == 1
            ? firstResolution.future
            : secondResolution.future;
      },
      watchCurrent: ({required String userKey}) {
        watchedKeys.add(userKey);
        return readings.stream;
      },
      showNotification:
          ({
            required String title,
            required String body,
            String? payload,
          }) async {},
      thresholdSettings: ThresholdSettingsService(
        storage: LocalStorageService(),
      ),
      alertsStore: AlertsStore(),
    );

    final Future<void> firstStart = monitor.start();
    await Future<void>.delayed(Duration.zero);
    await monitor.stop();
    final Future<void> secondStart = monitor.start();
    await Future<void>.delayed(Duration.zero);

    firstResolution.complete('stale-key');
    await firstStart;
    secondResolution.complete('active-key');
    await secondStart;

    expect(resolutionCalls, 2);
    expect(watchedKeys, <String>['active-key']);

    await monitor.stop();
    await readings.close();
  });
}

AlertItem _findAlert(AlertsStore store, String title) {
  return store.liveItems.firstWhere((AlertItem item) => item.title == title);
}
