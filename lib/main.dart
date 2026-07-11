import 'firebase_options.dart';
import 'app/agrisenseai_app.dart';
import 'app/injection_container.dart';
import 'core/utils/system_utils.dart';
import 'package:flutter/material.dart';
import 'core/config/responsive_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/logger/logger_service.dart';

void main() async {
  // Ensure flutter bindings are initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Log app start
  LoggerService(className: "main").info('App Starting...');

  // Firebase initialization
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize dependencies
  await initializeDependencies();

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
