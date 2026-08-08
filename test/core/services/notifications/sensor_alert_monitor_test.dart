import 'dart:async';

import 'package:agrisenseaiapp/core/entities/app_user.dart';
import 'package:agrisenseaiapp/core/providers/auth_session_provider.dart';
import 'package:agrisenseaiapp/core/services/alerts/alerts_store.dart';
import 'package:agrisenseaiapp/core/services/local_storage/local_storage_service.dart';
import 'package:agrisenseaiapp/core/services/notifications/sensor_alert_monitor.dart';
import 'package:agrisenseaiapp/core/services/realtime_db/sensor_database_service.dart';
import 'package:agrisenseaiapp/core/services/settings/threshold_settings_service.dart';
import 'package:agrisenseaiapp/features/alerts/domain/entities/alert_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthSession extends ChangeNotifier implements AuthSession {
  _FakeAuthSession(this._user);

  AppUser? _user;

  @override
  AppUser? get user => _user;

  @override
  bool get isReady => true;

  void setUser(AppUser? user) {
    _user = user;
    notifyListeners();
  }
}

void main() {
  test(
    'configured ranges generate matching Warning and Critical alerts',
    () async {
      final StreamController<FieldCurrentReading?> readings =
          StreamController<FieldCurrentReading?>.broadcast(sync: true);
      final AlertsStore alertsStore = AlertsStore();
      final ThresholdSettingsService thresholds = ThresholdSettingsService(
        storage: LocalStorageService(),
      );
      await thresholds.setTemperatureRange(
        minimum: 20,
        maximum: 30,
        persist: false,
      );
      await thresholds.setHumidityRange(
        minimum: 60,
        maximum: 80,
        persist: false,
      );
      await thresholds.setMoistureRange(
        minimum: 65,
        maximum: 85,
        persist: false,
      );
      await thresholds.setLightRange(
        minimum: 45000,
        maximum: 70000,
        persist: false,
      );

      const AppUser user = AppUser(uid: 'user-1', email: 'farmer@example.com');
      DateTime now = DateTime(2026, 7, 13, 19, 8, 5);
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
        now: () => now,
      );

      await monitor.start();
      expect(resolvedUser, same(user));
      expect(watchedKey, 'farmer_example_com');

      readings.add(
        FieldCurrentReading(
          deviceOnline: true,
          temperatureC: 31,
          humidityPercent: 81,
          soilMoisturePercent: 64,
          lightLux: 44000,
          updatedAt: now,
        ),
      );

      expect(alertsStore.liveItems, isEmpty);
      expect(notifications, isEmpty);

      now = _emitContinuously(
        readings: readings,
        start: now,
        setNow: (DateTime value) => now = value,
        duration: SensorAlertMonitor.notificationInterval,
        readingAt: (DateTime updatedAt) => FieldCurrentReading(
          deviceOnline: true,
          temperatureC: 31,
          humidityPercent: 81,
          soilMoisturePercent: 64,
          lightLux: 44000,
          updatedAt: updatedAt,
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
        contains('configured threshold of 45000 lux'),
      );
      expect(
        notifications.first.body,
        allOf(
          contains('Sensor: Temperature'),
          contains('Current value: 31°C'),
          contains('Severity: Warning'),
          contains('Time: 2026-07-13 19:13:05'),
        ),
      );

      readings.add(
        FieldCurrentReading(
          deviceOnline: true,
          temperatureC: 25,
          humidityPercent: 70,
          soilMoisturePercent: 70,
          lightLux: 50000,
          updatedAt: now,
        ),
      );
      readings.add(
        FieldCurrentReading(
          deviceOnline: true,
          temperatureC: 37,
          humidityPercent: 86,
          soilMoisturePercent: 49,
          lightLux: 91000,
          updatedAt: now,
        ),
      );

      expect(alertsStore.liveItems, hasLength(4));
      now = _emitContinuously(
        readings: readings,
        start: now,
        setNow: (DateTime value) => now = value,
        duration: SensorAlertMonitor.notificationInterval,
        readingAt: (DateTime updatedAt) => FieldCurrentReading(
          deviceOnline: true,
          temperatureC: 37,
          humidityPercent: 86,
          soilMoisturePercent: 49,
          lightLux: 91000,
          updatedAt: updatedAt,
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
      expect(temperature.timestamp, now);
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
    },
  );

  test(
    'alerts require continuous online data and repeat every five minutes',
    () async {
      final StreamController<FieldCurrentReading?> readings =
          StreamController<FieldCurrentReading?>.broadcast(sync: true);
      final AlertsStore alertsStore = AlertsStore();
      DateTime now = DateTime(2026, 7, 13, 12);
      int popupCount = 0;
      final SensorAlertMonitor monitor = SensorAlertMonitor.forTesting(
        currentUser: () => const AppUser(uid: 'user-1'),
        resolveUserKey: (_) async => 'user-1',
        watchCurrent: ({required String userKey}) => readings.stream,
        showNotification:
            ({
              required String title,
              required String body,
              String? payload,
            }) async {
              popupCount++;
            },
        thresholdSettings: ThresholdSettingsService(
          storage: LocalStorageService(),
        ),
        alertsStore: alertsStore,
        now: () => now,
      );
      await monitor.start();

      FieldCurrentReading warningAt(DateTime updatedAt) => FieldCurrentReading(
        deviceOnline: true,
        temperatureC: 31,
        humidityPercent: 70,
        soilMoisturePercent: 70,
        lightLux: 50000,
        updatedAt: updatedAt,
      );

      readings.add(warningAt(now));
      expect(popupCount, 0, reason: 'Opening the app must only arm the timer.');

      now = _emitContinuously(
        readings: readings,
        start: now,
        setNow: (DateTime value) => now = value,
        duration: const Duration(minutes: 2, seconds: 40),
        readingAt: warningAt,
      );
      expect(popupCount, 0);

      now = _emitContinuously(
        readings: readings,
        start: now,
        setNow: (DateTime value) => now = value,
        duration: const Duration(minutes: 2, seconds: 20),
        readingAt: warningAt,
      );
      expect(popupCount, 1);

      now = _emitContinuously(
        readings: readings,
        start: now,
        setNow: (DateTime value) => now = value,
        duration: SensorAlertMonitor.notificationInterval,
        readingAt: warningAt,
      );
      expect(popupCount, 2);
      expect(alertsStore.liveItems, hasLength(2));

      readings.add(
        FieldCurrentReading(
          deviceOnline: true,
          temperatureC: 25,
          humidityPercent: 70,
          soilMoisturePercent: 70,
          lightLux: 50000,
          updatedAt: now,
        ),
      );
      readings.add(warningAt(now));
      expect(popupCount, 2, reason: 'A new condition must restart the timer.');

      now = _emitContinuously(
        readings: readings,
        start: now,
        setNow: (DateTime value) => now = value,
        duration: SensorAlertMonitor.notificationInterval,
        readingAt: warningAt,
      );
      expect(popupCount, 3);

      await monitor.stop();
      await readings.close();
    },
  );

  test(
    'offline and reconnected readings reset the notification timer',
    () async {
      final StreamController<FieldCurrentReading?> readings =
          StreamController<FieldCurrentReading?>.broadcast(sync: true);
      final AlertsStore alertsStore = AlertsStore();
      DateTime now = DateTime(2026, 7, 13, 12);
      int popupCount = 0;
      final SensorAlertMonitor monitor = SensorAlertMonitor.forTesting(
        currentUser: () => const AppUser(uid: 'user-1'),
        resolveUserKey: (_) async => 'user-1',
        watchCurrent: ({required String userKey}) => readings.stream,
        showNotification:
            ({
              required String title,
              required String body,
              String? payload,
            }) async {
              popupCount++;
            },
        thresholdSettings: ThresholdSettingsService(
          storage: LocalStorageService(),
        ),
        alertsStore: alertsStore,
        now: () => now,
      );
      await monitor.start();

      FieldCurrentReading warningAt(DateTime updatedAt) => FieldCurrentReading(
        deviceOnline: true,
        temperatureC: 31,
        humidityPercent: 70,
        soilMoisturePercent: 70,
        lightLux: 50000,
        updatedAt: updatedAt,
      );

      readings.add(warningAt(now));
      now = _emitContinuously(
        readings: readings,
        start: now,
        setNow: (DateTime value) => now = value,
        duration: const Duration(minutes: 1),
        readingAt: warningAt,
      );

      now = now.add(const Duration(minutes: 2));
      readings.add(warningAt(now.subtract(const Duration(seconds: 31))));
      expect(popupCount, 0, reason: 'Stale Firebase data is Offline.');

      readings.add(warningAt(now));
      expect(
        popupCount,
        0,
        reason: 'Reconnection must arm a new timer, not notify immediately.',
      );

      now = _emitContinuously(
        readings: readings,
        start: now,
        setNow: (DateTime value) => now = value,
        duration: SensorAlertMonitor.notificationInterval,
        readingAt: warningAt,
      );
      expect(popupCount, 1);
      expect(alertsStore.liveItems, hasLength(1));

      await monitor.stop();
      await readings.close();
    },
  );

  test('every configured range produces low and high warnings', () async {
    final StreamController<FieldCurrentReading?> readings =
        StreamController<FieldCurrentReading?>.broadcast(sync: true);
    final AlertsStore alertsStore = AlertsStore();
    final ThresholdSettingsService thresholds = ThresholdSettingsService(
      storage: LocalStorageService(),
    );
    await thresholds.setTemperatureRange(
      minimum: 18,
      maximum: 32,
      persist: false,
    );
    await thresholds.setHumidityRange(minimum: 55, maximum: 80, persist: false);
    await thresholds.setMoistureRange(minimum: 65, maximum: 85, persist: false);
    await thresholds.setLightRange(
      minimum: 40000,
      maximum: 75000,
      persist: false,
    );
    DateTime now = DateTime(2026, 7, 13, 12);
    final SensorAlertMonitor monitor = SensorAlertMonitor.forTesting(
      currentUser: () => const AppUser(uid: 'user-1'),
      resolveUserKey: (_) async => 'user-1',
      watchCurrent: ({required String userKey}) => readings.stream,
      showNotification:
          ({
            required String title,
            required String body,
            String? payload,
          }) async {},
      thresholdSettings: thresholds,
      alertsStore: alertsStore,
      now: () => now,
    );
    await monitor.start();

    FieldCurrentReading lowWarningsAt(DateTime updatedAt) =>
        FieldCurrentReading(
          deviceOnline: true,
          temperatureC: 17,
          humidityPercent: 81,
          soilMoisturePercent: 86,
          lightLux: 39000,
          updatedAt: updatedAt,
        );
    FieldCurrentReading highWarningsAt(DateTime updatedAt) =>
        FieldCurrentReading(
          deviceOnline: true,
          temperatureC: 33,
          humidityPercent: 54,
          soilMoisturePercent: 64,
          lightLux: 76000,
          updatedAt: updatedAt,
        );

    readings.add(lowWarningsAt(now));
    now = _emitContinuously(
      readings: readings,
      start: now,
      setNow: (DateTime value) => now = value,
      duration: SensorAlertMonitor.notificationInterval,
      readingAt: lowWarningsAt,
    );
    readings.add(
      FieldCurrentReading(
        deviceOnline: true,
        temperatureC: 25,
        humidityPercent: 70,
        soilMoisturePercent: 75,
        lightLux: 60000,
        updatedAt: now,
      ),
    );
    readings.add(highWarningsAt(now));
    now = _emitContinuously(
      readings: readings,
      start: now,
      setNow: (DateTime value) => now = value,
      duration: SensorAlertMonitor.notificationInterval,
      readingAt: highWarningsAt,
    );

    expect(
      alertsStore.liveItems.map((AlertItem item) => item.title).toSet(),
      <String>{
        'Warning: Low Temperature',
        'Warning: High Temperature',
        'Warning: Low Humidity',
        'Warning: High Humidity',
        'Warning: Low Soil Moisture',
        'Warning: High Soil Moisture',
        'Warning: Low Light Intensity',
        'Warning: High Light Intensity',
      },
    );

    await monitor.stop();
    await readings.close();
  });

  test(
    'monitor waits for sign-in and ignores stale account resolutions',
    () async {
      final Completer<String> firstResolution = Completer<String>();
      final Completer<String> secondResolution = Completer<String>();
      final StreamController<FieldCurrentReading?> readings =
          StreamController<FieldCurrentReading?>.broadcast();
      final _FakeAuthSession auth = _FakeAuthSession(
        const AppUser(uid: 'first-user'),
      );
      final List<String> watchedKeys = <String>[];
      int resolutionCalls = 0;
      final SensorAlertMonitor monitor = SensorAlertMonitor.forTesting(
        authSession: auth,
        currentUser: () => auth.user,
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

      final Future<void> start = monitor.start();
      await Future<void>.delayed(Duration.zero);
      auth.setUser(const AppUser(uid: 'second-user'));
      await Future<void>.delayed(Duration.zero);

      firstResolution.complete('stale-key');
      await start;
      secondResolution.complete('active-key');
      await Future<void>.delayed(Duration.zero);

      expect(resolutionCalls, 2);
      expect(watchedKeys, <String>['active-key']);

      await monitor.stop();
      auth.dispose();
      await readings.close();
    },
  );
}

AlertItem _findAlert(AlertsStore store, String title) {
  return store.liveItems.firstWhere((AlertItem item) => item.title == title);
}

DateTime _emitContinuously({
  required StreamController<FieldCurrentReading?> readings,
  required DateTime start,
  required void Function(DateTime now) setNow,
  required Duration duration,
  required FieldCurrentReading Function(DateTime updatedAt) readingAt,
}) {
  const Duration heartbeat = Duration(seconds: 20);
  DateTime now = start;
  Duration elapsed = Duration.zero;
  while (elapsed < duration) {
    final Duration remaining = duration - elapsed;
    final Duration step = remaining < heartbeat ? remaining : heartbeat;
    now = now.add(step);
    elapsed += step;
    setNow(now);
    readings.add(readingAt(now));
  }
  return now;
}
