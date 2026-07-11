enum AlertSeverity {
  critical,
  warning,
  info,
}

class AlertItem {
  const AlertItem({
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.severity,
    required this.icon,
  });

  final String title;
  final String message;
  final String timeLabel;
  final AlertSeverity severity;
  final String icon;
}
