import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';

import '../../../firebase_options.dart';
import '../../entities/app_user.dart';
import '../alerts/alerts_store.dart';
import '../local_storage/local_storage_service.dart';
import '../logger/logger_service.dart';
import '../realtime_db/sensor_database_service.dart';
import '../settings/threshold_settings_service.dart';
import 'notification_local_handler.dart';
import 'sensor_alert_monitor.dart';

/// Schedules the app-controlled Android fallback used after the Flutter UI
/// process has been reclaimed. WorkManager is deliberately best-effort: Android
/// may defer work in Doze or when the app is force-stopped.
class SensorAlertBackgroundScheduler {
  static const String _uniqueWorkName = 'agrisense_sensor_alert_check';
  static const String _taskName = 'agrisense.sensorAlertCheck';
  static const Duration checkInterval = Duration(minutes: 5);

  static Future<void> initialize() {
    return Workmanager().initialize(sensorAlertBackgroundDispatcher);
  }

  static Future<void> schedule() => _scheduleNext();

  static Future<void> _scheduleNext() {
    return Workmanager().registerOneOffTask(
      _uniqueWorkName,
      _taskName,
      initialDelay: checkInterval,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}

/// Must remain a top-level entry point so Android can start a Flutter isolate.
@pragma('vm:entry-point')
void sensorAlertBackgroundDispatcher() {
  Workmanager().executeTask((
    String taskName,
    Map<String, dynamic>? input,
  ) async {
    if (taskName != 'agrisense.sensorAlertCheck') {
      return true;
    }

    final LoggerService logger = LoggerService(
      className: 'SensorAlertBackgroundWorker',
    );
    try {
      DartPluginRegistrant.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final LocalStorageService storage = LocalStorageService();
      if (!await storage.getNotificationsEnabled()) {
        return true;
      }

      final ThresholdSettingsService thresholds = ThresholdSettingsService(
        storage: storage,
      );
      await thresholds.load();
      final AlertsStore alertsStore = AlertsStore(storage: storage);
      await alertsStore.load();
      final NotificationLocalHandler notifications = NotificationLocalHandler();
      await notifications.initialize();

      final SensorDatabaseService database = SensorDatabaseService();
      final ({String userId, String userKey})? savedTarget = await storage
          .getSensorMonitorTarget();
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (savedTarget == null && firebaseUser == null) {
        return true;
      }
      final AppUser user = savedTarget == null
          ? AppUser(
              uid: firebaseUser!.uid,
              email: firebaseUser.email,
              phoneNumber: firebaseUser.phoneNumber,
            )
          : AppUser(uid: savedTarget.userId);
      final String userKey =
          savedTarget?.userKey ?? await database.resolveUserKey(user);
      if (savedTarget == null) {
        await storage.saveSensorMonitorTarget(
          userId: user.uid,
          userKey: userKey,
        );
      }
      final FieldCurrentReading? reading = await database.getCurrent(
        userKey: userKey,
      );

      final SensorAlertMonitor monitor = SensorAlertMonitor.forBackground(
        user: user,
        resolveUserKey: (_) async => userKey,
        watchCurrent: ({required String userKey}) => const Stream.empty(),
        showNotification: notifications.show,
        thresholdSettings: thresholds,
        alertsStore: alertsStore,
      );
      await monitor.evaluateBackgroundReading(reading);
    } catch (error, stackTrace) {
      logger.error(
        'Android background sensor alert check failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      // Re-enqueue only after this task finishes. One-off work allows the
      // requested five-minute cadence; Android still controls exact timing.
      try {
        await SensorAlertBackgroundScheduler.schedule();
      } catch (error, stackTrace) {
        logger.error(
          'Could not schedule the next sensor alert check',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return true;
  });
}
