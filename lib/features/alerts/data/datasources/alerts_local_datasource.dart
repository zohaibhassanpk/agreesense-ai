import '../../../../core/constants/app_assets.dart';
import '../../../../core/utils/relative_time.dart';
import '../../domain/entities/alert_item.dart';
import '../models/alert_item_model.dart';
import '../models/alert_section_model.dart';

abstract class AlertsLocalDataSource {
  Future<List<AlertSectionModel>> getAlertSections();
}

class AlertsLocalDataSourceImpl implements AlertsLocalDataSource {
  @override
  Future<List<AlertSectionModel>> getAlertSections() async {
    final DateTime now = DateTime.now();
    final DateTime pumpTimestamp = now.subtract(const Duration(minutes: 10));
    final DateTime moistureTimestamp = now.subtract(const Duration(hours: 1));
    final DateTime syncTimestamp = now.subtract(const Duration(days: 1));

    return [
      AlertSectionModel(
        label: 'Today',
        items: [
          AlertItemModel(
            title: 'Pump Malfunction',
            message: 'Water pump failed to start during scheduled irrigation.',
            timeLabel: relativeTime(pumpTimestamp, now: now),
            timestamp: pumpTimestamp,
            severity: AlertSeverity.critical,
            icon: AppAssets.alert,
          ),
          AlertItemModel(
            title: 'Low Soil Moisture',
            message: 'Moisture dropped below 60% threshold in Sector A.',
            timeLabel: relativeTime(moistureTimestamp, now: now),
            timestamp: moistureTimestamp,
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
            timeLabel: relativeTime(syncTimestamp, now: now),
            timestamp: syncTimestamp,
            severity: AlertSeverity.info,
            icon: AppAssets.refresh,
          ),
        ],
      ),
    ];
  }
}
