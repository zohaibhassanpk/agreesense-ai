import '../../domain/entities/alert_section.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../datasources/alerts_local_datasource.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  const AlertsRepositoryImpl({required this.localDataSource});

  final AlertsLocalDataSource localDataSource;

  @override
  Future<List<AlertSection>> getAlertSections() {
    return localDataSource.getAlertSections();
  }
}
