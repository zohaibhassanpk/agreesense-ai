import 'firebase_options.dart';
import 'app/agrisenseai_app.dart';
import 'app/injection_container.dart';
import 'core/utils/system_utils.dart';
import 'package:flutter/material.dart';
import 'core/config/responsive_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/services/logger/logger_service.dart';
import 'core/services/notifications/notification_local_handler.dart';
import 'core/services/notifications/sensor_alert_monitor.dart';
import 'core/services/settings/threshold_settings_service.dart';

void main() async {
  // Ensure flutter bindings are initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Log app start
  LoggerService(className: "main").info('App Starting...');

  // Firebase initialization
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  // Local threshold-crossing notifications
  await di<NotificationLocalHandler>().initialize();
  await Permission.notification.request();
  await di<SensorAlertMonitor>().start();

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
