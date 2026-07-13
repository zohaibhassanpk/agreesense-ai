import '../../domain/entities/alert_item.dart';

class AlertItemModel extends AlertItem {
  const AlertItemModel({
    required super.title,
    required super.message,
    required super.timeLabel,
    required super.timestamp,
    required super.severity,
    required super.icon,
  });

  factory AlertItemModel.fromEntity(AlertItem item) {
    return AlertItemModel(
      title: item.title,
      message: item.message,
      timeLabel: item.timeLabel,
      timestamp: item.timestamp,
      severity: item.severity,
      icon: item.icon,
    );
  }
}
