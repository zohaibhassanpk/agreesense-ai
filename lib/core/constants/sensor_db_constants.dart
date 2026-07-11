/// Firebase Realtime Database configuration for the AgriSense sensor data.
class SensorDbConstants {
  SensorDbConstants._();

  /// Exact URL of the RTDB instance. The generated firebase_options.dart
  /// carries no databaseURL, so the app must pass this explicitly when
  /// creating the [FirebaseDatabase] instance.
  static const String databaseUrl =
      'https://agrisenseai-app-default-rtdb.asia-southeast1.firebasedatabase.app';

  /// Account key the hardware node writes under. This is chosen on the
  /// hardware side and is independent of the Firebase Auth UID; replace with
  /// a per-account device link once device pairing exists (SRS REQ-DB-4).
  static const String defaultUserKey = 'zohaibhassanpk2';
  static const String defaultFarmKey = 'farm_01';
  static const String defaultFieldKey = 'field_01';

  /// Path to the field node that holds the `current` and `history` children.
  static String fieldPath({
    String userKey = defaultUserKey,
    String farmKey = defaultFarmKey,
    String fieldKey = defaultFieldKey,
  }) => 'users/$userKey/farms/$farmKey/fields/$fieldKey';

  /// Global pump control flag polled by the ESP32 node.
  static const String pumpStatusPath = 'sensor/controls/pump_status';

  /// A reading older than this counts as stale, so the device is shown as
  /// offline even when the hardware never flipped `deviceOnline` off
  /// (e.g. it lost power). The sensor cadence is 10-15 minutes.
  static const Duration onlineStaleness = Duration(minutes: 30);
}

/// Default crop-condition thresholds used for status indicators and
/// rule-based advice. The SRS leaves exact tobacco ranges TBD (TBD-2), so
/// these follow the values shown in the app design (min moisture 30%,
/// max temperature 35°C) until they become editable in Settings.
class SensorThresholds {
  SensorThresholds._();

  static const double minSoilMoisturePercent = 30;
  static const double maxTemperatureC = 35;
  static const double minHumidityPercent = 30;
  static const double maxHumidityPercent = 85;
}
