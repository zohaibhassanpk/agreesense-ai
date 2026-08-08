import '../../domain/entities/alert_item.dart';

class AlertItemModel extends AlertItem {
  const AlertItemModel({
    super.eventId,
    required super.title,
    required super.message,
    super.recommendedAction,
    required super.timestamp,
    super.createdAt,
    required super.severity,
    required super.icon,
  });

  factory AlertItemModel.fromEntity(AlertItem item) {
    return AlertItemModel(
      eventId: item.eventId,
      title: item.title,
      message: item.message,
      recommendedAction: item.recommendedAction,
      timestamp: item.timestamp,
      createdAt: item.createdAt,
      severity: item.severity,
      icon: item.icon,
    );
  }
}
