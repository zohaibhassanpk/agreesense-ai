import '../../domain/entities/analytics_dashboard.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_local_datasource.dart';
import '../datasources/analytics_remote_datasource.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  const AnalyticsRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
  });

  final AnalyticsLocalDataSource localDataSource;

  /// Firebase-backed source; when absent (e.g. in unit tests) the repository
  /// serves the bundled local dashboard instead.
  final AnalyticsRemoteDataSource? remoteDataSource;

  @override
  Future<AnalyticsDashboard> getDashboard() {
    final AnalyticsRemoteDataSource? remote = remoteDataSource;
    if (remote != null) {
      return remote.getDashboard();
    }
    return localDataSource.getDashboard();
  }

  @override
  Stream<AnalyticsDashboard> watchDashboard() {
    final AnalyticsRemoteDataSource? remote = remoteDataSource;
    if (remote != null) {
      return remote.watchDashboard();
    }
    return localDataSource.getDashboard().asStream();
  }
}
