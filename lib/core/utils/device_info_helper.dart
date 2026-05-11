import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Utility for retrieving device information in a formatted string.
/// Used for FCM token registration with the backend (optional device_info param).
class DeviceInfoHelper {
  DeviceInfoHelper._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Returns a formatted device info string suitable for the backend's
  /// optional `device_info` parameter.
  ///
  /// Format:
  /// - Android: "Manufacturer Model, Android Version" (e.g., "Samsung Galaxy S24, Android 14")
  /// - iOS: "Model Name, iOS Version" (e.g., "iPhone 15, iOS 18")
  /// - Other: "Unknown Device"
  static Future<String> getDeviceInfoString() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        final manufacturer = _capitalize(info.manufacturer);
        final model = info.model;
        final version = info.version.release;
        return '$manufacturer $model, Android $version';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        final model = info.modelName.isNotEmpty ? info.modelName : info.model;
        final version = info.systemVersion;
        return '$model, iOS $version';
      }
    } catch (_) {
      // Swallow errors; device_info is optional for backend
    }
    return 'Unknown Device';
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
