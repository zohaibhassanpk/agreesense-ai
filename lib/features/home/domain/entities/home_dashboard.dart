import 'sensor_reading.dart';
import 'smart_action.dart';

class HomeDashboard {
  const HomeDashboard({
    required this.greeting,
    required this.fieldName,
    required this.connectionStatus,
    required this.smartAction,
    required this.updatedLabel,
    required this.sensors,
    this.deviceOnline = true,
    this.updatedAt,
    this.pumpOn = false,
  });

  final String greeting;
  final String fieldName;
  final String connectionStatus;
  final SmartAction smartAction;
  final String updatedLabel;
  final List<SensorReading> sensors;
  final bool deviceOnline;
  final DateTime? updatedAt;
  final bool pumpOn;
}
