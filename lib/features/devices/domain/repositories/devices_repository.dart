import '../entities/devices_dashboard.dart';

abstract class DevicesRepository {
  Future<DevicesDashboard> getDashboard();
}
