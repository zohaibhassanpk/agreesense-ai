import '../../domain/entities/alert_item.dart';

class AlertItemModel extends AlertItem {
  const AlertItemModel({
    required super.title,
    required super.message,
    required super.timeLabel,
    required super.severity,
    required super.icon,
  });
}
