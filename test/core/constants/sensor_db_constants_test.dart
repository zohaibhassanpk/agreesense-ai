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

  group('SensorDbConstants.isReadingFresh', () {
    final DateTime now = DateTime(2026, 7, 13, 12);

    test('treats a reading exactly 30 seconds old as online', () {
      expect(
        SensorDbConstants.isReadingFresh(
          now.subtract(const Duration(seconds: 30)),
          now: now,
        ),
        isTrue,
      );
    });

    test('treats a reading older than 30 seconds as offline', () {
      expect(
        SensorDbConstants.isReadingFresh(
          now.subtract(const Duration(seconds: 30, milliseconds: 1)),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
