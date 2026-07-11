import '../../../../core/constants/app_assets.dart';
import '../../domain/entities/alert_item.dart';
import '../models/alert_item_model.dart';
import '../models/alert_section_model.dart';

abstract class AlertsLocalDataSource {
  Future<List<AlertSectionModel>> getAlertSections();
}

class AlertsLocalDataSourceImpl implements AlertsLocalDataSource {
  @override
  Future<List<AlertSectionModel>> getAlertSections() async {
    return const [
      AlertSectionModel(
        label: 'Today',
        items: [
          AlertItemModel(
            title: 'Pump Malfunction',
            message:
                'Water pump failed to start during scheduled irrigation.',
            timeLabel: '10m ago',
            severity: AlertSeverity.critical,
            icon: AppAssets.alert,
          ),
          AlertItemModel(
            title: 'Low Soil Moisture',
            message: 'Moisture dropped below 30% threshold in Sector A.',
            timeLabel: '1h ago',
            severity: AlertSeverity.warning,
            icon: AppAssets.drop,
          ),
        ],
      ),
      AlertSectionModel(
        label: 'Yesterday',
        isHistorical: true,
        items: [
          AlertItemModel(
            title: 'Cloud Sync Successful',
            message: 'All offline data has been successfully uploaded.',
            timeLabel: 'Yesterday',
            severity: AlertSeverity.info,
            icon: AppAssets.refresh,
          ),
        ],
      ),
    ];
  }
}
