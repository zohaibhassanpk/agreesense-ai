import 'package:agrisenseaiapp/core/utils/relative_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 7, 13, 12);

  test('uses readable minute and hour labels', () {
    expect(
      relativeTime(now.subtract(const Duration(seconds: 30)), now: now),
      'Just now',
    );
    expect(
      relativeTime(now.subtract(const Duration(minutes: 5)), now: now),
      '5 minutes ago',
    );
    expect(
      relativeTime(now.subtract(const Duration(hours: 1)), now: now),
      '1 hour ago',
    );
  });

  test('uses Yesterday for the previous calendar day', () {
    expect(relativeTime(DateTime(2026, 7, 12, 23, 55), now: now), 'Yesterday');
  });

  test('future timestamps are treated as Just now', () {
    expect(
      relativeTime(now.add(const Duration(minutes: 5)), now: now),
      'Just now',
    );
  });
}
