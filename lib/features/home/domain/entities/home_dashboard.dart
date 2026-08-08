import 'sensor_reading.dart';
import 'smart_action.dart';

enum DeviceStatus { unknown, loading, online, offline, error }

class HomeDashboard {
  const HomeDashboard({
    required this.greeting,
    required this.fieldName,
    required this.connectionStatus,
    required this.smartAction,
    required this.updatedLabel,
    required this.sensors,
    this.deviceStatus = DeviceStatus.unknown,
    this.updatedAt,
    this.pumpOn = false,
  });

  final String greeting;
  final String fieldName;
  final String connectionStatus;
  final SmartAction smartAction;
  final String updatedLabel;
  final List<SensorReading> sensors;
  final DeviceStatus deviceStatus;
  bool get deviceOnline => deviceStatus == DeviceStatus.online;
  bool get isDeviceStatusChecking =>
      deviceStatus == DeviceStatus.unknown ||
      deviceStatus == DeviceStatus.loading;
  final DateTime? updatedAt;
  final bool pumpOn;

  HomeDashboard withPumpStatus(bool isOn) {
    return HomeDashboard(
      greeting: greeting,
      fieldName: fieldName,
      connectionStatus: connectionStatus,
      smartAction: smartAction,
      updatedLabel: updatedLabel,
      sensors: sensors,
      deviceStatus: deviceStatus,
      updatedAt: updatedAt,
      pumpOn: isOn,
    );
  }
}
