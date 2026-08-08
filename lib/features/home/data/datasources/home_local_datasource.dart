import '../../../../core/constants/app_assets.dart';
import '../../domain/entities/home_dashboard.dart';
import '../models/home_dashboard_model.dart';
import '../models/sensor_reading_model.dart';
import '../models/smart_action_model.dart';

abstract class HomeLocalDataSource {
  Future<HomeDashboardModel> getDashboard();
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  @override
  Future<HomeDashboardModel> getDashboard() async {
    return const HomeDashboardModel(
      greeting: 'Welcome back',
      fieldName: 'My Tobacco Field',
      connectionStatus: 'Device Connected (Bluetooth)',
      smartAction: SmartActionModel(
        title: 'Smart Action',
        message:
            'Soil is drying faster than usual. '
            'Irrigation needed in approx ',
        highlight: '2 hours.',
      ),
      updatedLabel: 'Updated 2m ago',
      deviceStatus: DeviceStatus.online,
      sensors: [
        SensorReadingModel(
          label: 'Soil Moisture',
          value: '28',
          unit: '%',
          icon: AppAssets.drop,
          iconColorKey: 'yellow',
          statusColorKey: 'yellow',
        ),
        SensorReadingModel(
          label: 'Temperature',
          value: '24',
          unit: '\u00B0C',
          icon: AppAssets.temprature,
          iconColorKey: 'primary',
          statusColorKey: 'primary',
        ),
        SensorReadingModel(
          label: 'Humidity',
          value: '62',
          unit: '%',
          icon: AppAssets.cloud,
          iconColorKey: 'blue',
          statusColorKey: 'primary',
        ),
        SensorReadingModel(
          label: 'Light Intensity',
          value: '760',
          unit: 'lx',
          icon: AppAssets.sun,
          iconColorKey: 'yellow',
          statusColorKey: 'yellow',
        ),
      ],
    );
  }
}
