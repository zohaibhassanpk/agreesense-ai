import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl({required this.localDataSource});

  final HomeLocalDataSource localDataSource;

  @override
  Future<HomeDashboard> getDashboard() {
    return localDataSource.getDashboard();
  }
}
