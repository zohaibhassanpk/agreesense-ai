import 'package:agrisenseaiapp/core/constants/sensor_db_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SensorDbConstants.sanitizeRtdbKey', () {
    test('replaces every RTDB-illegal key character', () {
      expect(
        SensorDbConstants.sanitizeRtdbKey(r'user.name#$field/[primary]'),
        'user_name__field__primary_',
      );
    });

    test('preserves legal identity characters', () {
      expect(
        SensorDbConstants.sanitizeRtdbKey('farmer+demo@example_com'),
        'farmer+demo@example_com',
      );
    });
  });

  group('SensorDbConstants.userKeyCandidates', () {
    test('maps a Google email to the existing hardware account key first', () {
      expect(
        SensorDbConstants.userKeyCandidates(
          uid: 'firebase-uid',
          email: 'ZohaibHassanPK2@gmail.com',
        ),
        <String>[
          'zohaibhassanpk2',
          'firebase-uid',
          'zohaibhassanpk2@gmail_com',
        ],
      );
    });

    test('deduplicates equivalent identity-derived keys', () {
      expect(
        SensorDbConstants.userKeyCandidates(
          uid: 'farmer',
          email: 'farmer@example.com',
          phoneNumber: 'farmer',
        ),
        <String>['farmer', 'farmer@example_com'],
      );
    });
  });

  test('pumpStatusPath is scoped to the authenticated Firebase UID', () {
    expect(
      SensorDbConstants.pumpStatusPath(userUid: 'firebase-uid-123'),
      'users/firebase-uid-123/device/controls/pumpStatus',
    );
  });

  group('normalizeEpochMilliseconds', () {
    test('keeps the ESP32 13-digit Unix millisecond timestamp unchanged', () {
      expect(
        SensorDbConstants.normalizeEpochMilliseconds(1783771022000),
        1783771022000,
      );
    });

    test('converts a 10-digit Unix second timestamp to milliseconds', () {
      expect(
        SensorDbConstants.normalizeEpochMilliseconds(1783771022),
        1783771022000,
      );
    });
  });

  group('SensorDbConstants.isReadingFresh', () {
    final DateTime now = DateTime(2026, 7, 13, 12);

    test('treats a reading exactly 15 seconds old as online', () {
      expect(
        SensorDbConstants.isReadingFresh(
          now.subtract(const Duration(seconds: 15)),
          now: now,
        ),
        isTrue,
      );
    });

    test('treats a reading older than 15 seconds as offline', () {
      expect(
        SensorDbConstants.isReadingFresh(
          now.subtract(const Duration(seconds: 15, milliseconds: 1)),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
