import '../models/alert_section_model.dart';

abstract class AlertsLocalDataSource {
  Future<List<AlertSectionModel>> getAlertSections();
}

class AlertsLocalDataSourceImpl implements AlertsLocalDataSource {
  @override
  Future<List<AlertSectionModel>> getAlertSections() async {
    // Runtime alerts are restored and streamed by AlertsStore. Keeping this
    // source empty prevents demo/info records from appearing as notifications.
    return const <AlertSectionModel>[];
  }
}
