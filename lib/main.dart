import 'firebase_options.dart';
import 'app/agrisenseai_app.dart';
import 'app/injection_container.dart';
import 'core/utils/system_utils.dart';
import 'package:flutter/material.dart';
import 'core/config/responsive_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/services/logger/logger_service.dart';
import 'core/services/alerts/alerts_store.dart';
import 'core/services/notifications/notification_local_handler.dart';
import 'core/services/notifications/notification_background_handler.dart';
import 'core/services/notifications/notification_push_service.dart';
import 'core/services/settings/threshold_settings_service.dart';

void main() async {
  // Ensure flutter bindings are initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Log app start
  LoggerService(className: "main").info('App Starting...');

  // Firebase initialization
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize dependencies
  await initializeDependencies();

  // Load persisted sensor thresholds before evaluating the first reading.
  try {
    await di<ThresholdSettingsService>().load();
  } catch (error, stackTrace) {
    LoggerService(className: 'main').error(
      'Could not load saved sensor thresholds; using defaults.',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Cloud Functions own threshold evaluation and FCM owns background and
  // terminated delivery. The local plugin only presents foreground messages.
  await di<NotificationLocalHandler>().initialize();
  await Permission.notification.request();
  await di<AlertsStore>().load();
  await di<NotificationPushService>().start();

  // Set system styles
  SystemUtils.setDefaultSystemUI();

  // Lock orientation
  await SystemUtils.lockOrientation();

  /// For development, you can use DevicePreview to test responsiveness on different devices.
  // runApp(
  //   DevicePreview(
  //     enabled: true,
  //     builder: (context) => ResponsiveProvider(
  //       mobileSize: Size(380, 812),
  //       tabletSize: Size(800, 1280),
  //       isDebugPrint: true,
  //       child: const AgriSenseAIApp(),
  //     ),
  //   ),
  // );

  runApp(
    ResponsiveProvider(
      mobileSize: Size(380, 812),
      tabletSize: Size(800, 1280),
      isDebugPrint: true,
      child: AgriSenseAIApp(),
    ),
  );
}
