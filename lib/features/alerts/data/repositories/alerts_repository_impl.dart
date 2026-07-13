import '../../domain/entities/alert_section.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../datasources/alerts_live_datasource.dart';
import '../datasources/alerts_local_datasource.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  const AlertsRepositoryImpl({
    required this.localDataSource,
    this.liveDataSource,
  });

  final AlertsLocalDataSource localDataSource;
  final AlertsLiveDataSource? liveDataSource;

  @override
  Future<List<AlertSection>> getAlertSections() {
    return localDataSource.getAlertSections();
  }

  @override
  Stream<List<AlertSection>> watchAlertSections() {
    final AlertsLiveDataSource? live = liveDataSource;
    if (live != null) {
      return live.watchAlertSections();
    }
    return localDataSource.getAlertSections().asStream();
  }
}
