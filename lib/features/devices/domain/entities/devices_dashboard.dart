import 'device_banner.dart';
import 'device_item.dart';

class DevicesDashboard {
  const DevicesDashboard({
    required this.banner,
    required this.pairedDevices,
    required this.availableDevices,
  });

  final DeviceBanner banner;
  final List<DeviceItem> pairedDevices;
  final List<DeviceItem> availableDevices;
}
