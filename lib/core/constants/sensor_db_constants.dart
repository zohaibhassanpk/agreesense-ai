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

  /// Converts an identity value into a Firebase Realtime Database-safe key.
  ///
  /// RTDB keys cannot contain `.`, `#`, `$`, `/`, `[` or `]`. Replacing each
  /// illegal character keeps email and phone-derived device paths stable and
  /// deterministic.
  static String sanitizeRtdbKey(String raw) {
    return raw.replaceAll(RegExp(r'[.#$/\[\]]'), '_');
  }

  /// Path to the field node that holds the `current` and `history` children.
  static String fieldPath({
    String userKey = defaultUserKey,
    String farmKey = defaultFarmKey,
    String fieldKey = defaultFieldKey,
  }) => 'users/$userKey/farms/$farmKey/fields/$fieldKey';

  /// Global pump control flag polled by the ESP32 node.
  static const String pumpStatusPath = 'sensor/controls/pump_status';

  /// A reading older than this counts as stale, so the device is shown as
  /// offline. Compared directly against `current.updatedAt` on every screen
  /// refresh, independent of the `deviceOnline` flag the hardware writes.
  static const Duration onlineStaleness = Duration(seconds: 30);

  /// Whether [updatedAt] is still within the inclusive online heartbeat.
  static bool isReadingFresh(DateTime updatedAt, {DateTime? now}) {
    return (now ?? DateTime.now())
            .difference(updatedAt)
            .compareTo(onlineStaleness) <=
        0;
  }
}
