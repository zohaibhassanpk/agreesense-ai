import '../entities/alert_section.dart';

abstract class AlertsRepository {
  Future<List<AlertSection>> getAlertSections();
}
