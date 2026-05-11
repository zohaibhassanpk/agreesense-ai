/// Returns a short human-readable relative time for [dateTime], relative to
/// [now] (defaults to `DateTime.now()`).
///
/// Examples:
///   just now        → < 1 minute
///   5 min ago       → < 1 hour
///   3 hours ago     → < 1 day
///   1 day ago       → < 2 days
///   3 days ago      → < 7 days
///   Apr 15          → older than a week, same year
///   Apr 15, 2024    → older than a week, different year
String relativeTime(DateTime dateTime, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(dateTime);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? '1 min ago' : '$m min ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? '1 hour ago' : '$h hours ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return d == 1 ? '1 day ago' : '$d days ago';
  }

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final monthLabel = months[dateTime.month - 1];
  if (dateTime.year == current.year) {
    return '$monthLabel ${dateTime.day}';
  }
  return '$monthLabel ${dateTime.day}, ${dateTime.year}';
}
