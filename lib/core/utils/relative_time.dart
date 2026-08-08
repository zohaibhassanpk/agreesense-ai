/// Returns a short human-readable relative time for [dateTime], relative to
/// [now] (defaults to `DateTime.now()`).
///
/// Examples: `Just now`, `5 minutes ago`, `1 hour ago`, and `Yesterday`.
String relativeTime(DateTime dateTime, {DateTime? now}) {
  final DateTime current = now ?? DateTime.now();
  final Duration rawDifference = current.difference(dateTime);
  final Duration difference = rawDifference.isNegative
      ? Duration.zero
      : rawDifference;

  if (difference.inSeconds < 60) return 'Just now';
  if (difference.inMinutes < 60) {
    final int minutes = difference.inMinutes;
    return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
  }
  if (_isYesterday(dateTime, current)) {
    return 'Yesterday';
  }
  if (difference.inHours < 24) {
    final int hours = difference.inHours;
    return hours == 1 ? '1 hour ago' : '$hours hours ago';
  }
  if (difference.inDays < 7) {
    final int days = difference.inDays;
    return days == 1 ? 'Yesterday' : '$days days ago';
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final monthLabel = months[dateTime.month - 1];
  if (dateTime.year == current.year) {
    return '$monthLabel ${dateTime.day}';
  }
  return '$monthLabel ${dateTime.day}, ${dateTime.year}';
}

bool _isYesterday(DateTime dateTime, DateTime current) {
  final DateTime today = DateTime(current.year, current.month, current.day);
  final DateTime alertDate = DateTime(
    dateTime.year,
    dateTime.month,
    dateTime.day,
  );
  return alertDate == today.subtract(const Duration(days: 1));
}
