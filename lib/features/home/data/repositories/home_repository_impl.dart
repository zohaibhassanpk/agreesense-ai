import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
  });

  final HomeLocalDataSource localDataSource;

  /// Firebase-backed source; when absent (e.g. in unit tests) the repository
  /// serves the bundled local dashboard instead.
  final HomeRemoteDataSource? remoteDataSource;

  @override
  Future<HomeDashboard> getDashboard() {
    final HomeRemoteDataSource? remote = remoteDataSource;
    if (remote != null) {
      return remote.watchDashboard().first;
    }
    return localDataSource.getDashboard();
  }

  @override
  Stream<HomeDashboard> watchDashboard() {
    final HomeRemoteDataSource? remote = remoteDataSource;
    if (remote != null) {
      return remote.watchDashboard();
    }
    return localDataSource.getDashboard().asStream();
  }

  @override
  Future<void> setPumpStatus(bool isOn) async {
    await remoteDataSource?.setPumpStatus(isOn);
  }
}
