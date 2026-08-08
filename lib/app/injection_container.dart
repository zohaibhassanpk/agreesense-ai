import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/services/alerts/alerts_store.dart';
import '../core/services/auth/firebase_auth_service.dart';
import '../core/services/auth/google_sign_in_service.dart';
import '../core/services/image_picker/image_picker_service.dart';
import '../core/services/local_storage/local_storage_service.dart';
import '../core/services/network/network_service.dart';
import '../core/services/notifications/notification_local_handler.dart';
import '../core/services/notifications/notification_push_service.dart';
import '../core/services/notifications/sensor_alert_monitor.dart';
import '../core/services/realtime_db/sensor_database_service.dart';
import '../core/services/settings/threshold_settings_service.dart';
import '../core/providers/auth_session_provider.dart';
import '../features/alerts/alert_di.dart';
import '../features/analytics/analytics_di.dart';
import '../features/auth/auth_di.dart';
import '../features/home/home_di.dart';
import '../features/profile/profile_di.dart';
import '../features/settings/settings_di.dart';
import '../features/splash_onboarding/splash_onboarding_di.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/constants/sensor_db_constants.dart';

final di = GetIt.instance;

Future<void> initializeDependencies() async {
  // -- CORE --
  // Local storage service
  di.registerLazySingleton<LocalStorageService>(() => LocalStorageService());

  // Canonical, persisted sensor threshold settings
  di.registerLazySingleton<ThresholdSettingsService>(
    () => ThresholdSettingsService(storage: di<LocalStorageService>()),
  );

  // Local notifications
  di.registerLazySingleton<NotificationLocalHandler>(
    () => NotificationLocalHandler(),
  );

  // Image picker service
  di.registerLazySingleton<ImagePickerService>(
    () => ImagePickerService(picker: ImagePicker()),
  );

  // Auth services
  di.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  di.registerLazySingleton<GoogleSignInService>(() => GoogleSignInService());

  // Auth session provider
  di.registerLazySingleton<AuthSessionProvider>(
    () => AuthSessionProvider(authService: di<FirebaseAuthService>()),
  );

  // Connectivity service
  di.registerLazySingleton(() => Connectivity());

  // Network service
  di.registerLazySingleton<NetworkService>(() => NetworkService(di()));

  // Sensor realtime database service
  di.registerLazySingleton<SensorDatabaseService>(
    () => SensorDatabaseService(),
  );

  // Remote push registration and foreground FCM presentation. Alert
  // evaluation itself is performed by the Firebase Cloud Function.
  di.registerLazySingleton<NotificationPushService>(
    () => NotificationPushService(
      messaging: FirebaseMessaging.instance,
      database: FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: SensorDbConstants.databaseUrl,
      ),
      authSession: di<AuthSessionProvider>(),
      sensorDatabase: di<SensorDatabaseService>(),
      thresholdSettings: di<ThresholdSettingsService>(),
      localNotifications: di<NotificationLocalHandler>(),
      localStorage: di<LocalStorageService>(),
      alertsStore: di<AlertsStore>(),
    ),
  );

  // Threshold-crossing local notifications
  di.registerLazySingleton<SensorAlertMonitor>(
    () => SensorAlertMonitor(
      sensorDatabase: di<SensorDatabaseService>(),
      notificationHandler: di<NotificationLocalHandler>(),
      authSessionProvider: di<AuthSessionProvider>(),
      thresholdSettings: di<ThresholdSettingsService>(),
      alertsStore: di<AlertsStore>(),
      storage: di<LocalStorageService>(),
    ),
  );

  // -- FEATURES --
  // Onboarding
  SplashOnboardingDI().init(di);

  // Auth
  AuthDI().init(di);

  // Home
  HomeDI().init(di);

  // Alerts
  AlertsDI().init(di);

  // Analytics
  AnalyticsDI().init(di);

  // Profile
  ProfileDI().init(di);

  // Settings
  SettingsDI().init(di);
}
