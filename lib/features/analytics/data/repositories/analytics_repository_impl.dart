import '../../domain/entities/analytics_dashboard.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_local_datasource.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  const AnalyticsRepositoryImpl({required this.localDataSource});

  final AnalyticsLocalDataSource localDataSource;

  @override
  Future<AnalyticsDashboard> getDashboard() {
    return localDataSource.getDashboard();
  }
}
