import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUtils {
  /// Set transparent status bar with dark icons (default)
  static void setDefaultSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Set custom status bar and navigation bar colors
  static void setCustomSystemUI({
    Color statusBarColor = Colors.transparent,
    Brightness statusBarIconBrightness = Brightness.dark,
    Brightness statusBarBrightness = Brightness.light,
    Color navigationBarColor = Colors.white,
    Brightness navigationBarIconBrightness = Brightness.dark,
  }) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarIconBrightness: statusBarIconBrightness,
        statusBarBrightness: statusBarBrightness,
        systemNavigationBarColor: navigationBarColor,
        systemNavigationBarIconBrightness: navigationBarIconBrightness,
      ),
    );
  }

  /// Lock app orientation (portrait only by default)
  static Future<void> lockOrientation({
    List<DeviceOrientation> orientations = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  }) async {
    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// Enable full-screen mode (hide system bars)
  static void enableFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Disable full-screen mode (show system bars)
  static void disableFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Reset everything to default
  static Future<void> resetSystemSettings() async {
    setDefaultSystemUI();
    await lockOrientation();
    disableFullScreen();
  }
}
