/// Extensions for [DateTime] providing time-based utilities.
extension DateTimeExtensions on DateTime {
  /// Returns a time-of-day greeting based on the current hour.
  ///
  /// Boundaries:
  /// - Good morning: 5:00 - 11:59
  /// - Good afternoon: 12:00 - 16:59
  /// - Good evening: 17:00 - 20:59
  /// - Good night: 21:00 - 4:59
  String get timeBasedGreeting {
    if (hour >= 5 && hour < 12) return 'Good morning,';
    if (hour >= 12 && hour < 17) return 'Good afternoon,';
    if (hour >= 17 && hour < 21) return 'Good evening,';
    return 'Good night,';
  }
}
