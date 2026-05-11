import '../../../../core/constants/app_assets.dart';
import '../../domain/entities/device_item.dart';
import '../models/device_banner_model.dart';
import '../models/device_item_model.dart';
import '../models/devices_dashboard_model.dart';

abstract class DevicesLocalDataSource {
  Future<DevicesDashboardModel> getDashboard();
}

class DevicesLocalDataSourceImpl implements DevicesLocalDataSource {
  @override
  Future<DevicesDashboardModel> getDashboard() async {
    return const DevicesDashboardModel(
      banner: DeviceBannerModel(
        title: 'Offline Mode Active',
        subtitle: 'Connecting via Bluetooth directly to sensor.',
        icon: AppAssets.bluetooth,
      ),
      pairedDevices: [
        DeviceItemModel(
          name: 'Node_Alpha_ESP32',
          statusText: 'Connected (Battery 85%)',
          icon: AppAssets.node,
          type: DeviceItemType.paired,
          isConnected: true,
        ),
      ],
      availableDevices: [
        DeviceItemModel(
          name: 'AgriSensor_B2',
          statusText: 'Ready to pair',
          icon: AppAssets.squareBluetooth,
          type: DeviceItemType.available,
          isConnected: false,
        ),
      ],
    );
  }
}
