import '../../domain/entities/home_dashboard.dart';
import 'sensor_reading_model.dart';
import 'smart_action_model.dart';

class HomeDashboardModel extends HomeDashboard {
  const HomeDashboardModel({
    required super.greeting,
    required super.fieldName,
    required super.connectionStatus,
    required SmartActionModel super.smartAction,
    required super.updatedLabel,
    required List<SensorReadingModel> super.sensors,
    super.deviceStatus,
    super.updatedAt,
    super.pumpOn,
  });
}
