enum AlertSeverity { critical, warning }

const Duration alertRetention = Duration(hours: 8);

class AlertItem {
  const AlertItem({
    this.eventId,
    required this.title,
    required this.message,
    this.recommendedAction = '',
    required this.timestamp,
    this.createdAt,
    required this.severity,
    required this.icon,
  });

  /// Stable identity shared by the local popup and its history record.
  final String? eventId;
  final String title;
  final String message;
  final String recommendedAction;
  final DateTime timestamp;
  final DateTime? createdAt;
  final AlertSeverity severity;
  final String icon;

  bool isWithinRetention({DateTime? now}) {
    final DateTime retainedFrom = (now ?? DateTime.now()).subtract(
      alertRetention,
    );
    return (createdAt ?? timestamp).isAfter(retainedFrom);
  }
}
