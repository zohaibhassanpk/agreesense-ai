import '../../domain/entities/devices_dashboard.dart';
import 'device_banner_model.dart';
import 'device_item_model.dart';

class DevicesDashboardModel extends DevicesDashboard {
  const DevicesDashboardModel({
    required DeviceBannerModel super.banner,
    required List<DeviceItemModel> super.pairedDevices,
    required List<DeviceItemModel> super.availableDevices,
  });
}
