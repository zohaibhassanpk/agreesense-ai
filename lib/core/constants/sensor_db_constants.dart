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

  /// RTDB node names are case-sensitive. These match the exported schema.
  static const String currentNode = 'current';
  static const String historyNode = 'history';

  /// Converts an identity value into a Firebase Realtime Database-safe key.
  ///
  /// RTDB keys cannot contain `.`, `#`, `$`, `/`, `[` or `]`. Replacing each
  /// illegal character keeps email and phone-derived device paths stable and
  /// deterministic.
  static String sanitizeRtdbKey(String raw) {
    return raw.replaceAll(RegExp(r'[.#$/\[\]]'), '_');
  }

  /// Candidate RTDB account keys derived from a signed-in identity.
  ///
  /// Existing hardware uses the Google email's local part (for example,
  /// `farmer@gmail.com` maps to `users/farmer`). UID and legacy full-email or
  /// phone keys remain supported for accounts provisioned with those schemes.
  static List<String> userKeyCandidates({
    required String uid,
    String? email,
    String? phoneNumber,
  }) {
    final Set<String> candidates = <String>{};

    void add(String? raw) {
      final String value = raw?.trim() ?? '';
      if (value.isEmpty) {
        return;
      }
      final String key = sanitizeRtdbKey(value);
      if (key.isNotEmpty) {
        candidates.add(key);
      }
    }

    final String normalizedEmail = email?.trim().toLowerCase() ?? '';
    if (normalizedEmail.isNotEmpty) {
      add(normalizedEmail.split('@').first);
    }
    add(uid);
    add(normalizedEmail);
    add(phoneNumber);

    return candidates.toList(growable: false);
  }

  /// Path to the field node that holds the `current` and `history` children.
  static String fieldPath({
    String userKey = defaultUserKey,
    String farmKey = defaultFarmKey,
    String fieldKey = defaultFieldKey,
  }) => 'users/$userKey/farms/$farmKey/fields/$fieldKey';

  /// Authenticated user's pump control flag.
  ///
  /// Pump state is intentionally UID-scoped even when legacy sensor readings
  /// are resolved through an email-derived hardware key.
  static String pumpStatusPath({required String userUid}) =>
      'users/$userUid/device/controls/pumpStatus';

  /// A reading older than this counts as stale, so the device is shown as
  /// offline. Compared directly against `current.updatedAt` on every screen
  /// refresh, independent of the `deviceOnline` flag the hardware writes.
  static const int deviceOfflineTimeoutSeconds = 15;
  static const Duration onlineStaleness = Duration(
    seconds: deviceOfflineTimeoutSeconds,
  );
  static const Duration maxFutureClockSkew = Duration(minutes: 2);

  /// Normalizes Unix timestamps from either seconds (10 digits) or
  /// milliseconds (13 digits) to milliseconds before comparison.
  static int normalizeEpochMilliseconds(num value) {
    final int epoch = value.toInt();
    return epoch < 100000000000 ? epoch * 1000 : epoch;
  }

  /// Whether [updatedAt] is still within the inclusive online heartbeat.
  static bool isReadingFresh(DateTime updatedAt, {DateTime? now}) {
    final Duration delta = (now ?? DateTime.now()).difference(updatedAt);
    if (delta.isNegative) {
      return delta.abs() <= maxFutureClockSkew;
    }
    return delta <= onlineStaleness;
  }
}
