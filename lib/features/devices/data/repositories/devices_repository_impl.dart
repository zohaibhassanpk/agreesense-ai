import '../../domain/entities/devices_dashboard.dart';
import '../../domain/repositories/devices_repository.dart';
import '../datasources/devices_local_datasource.dart';

class DevicesRepositoryImpl implements DevicesRepository {
  const DevicesRepositoryImpl({required this.localDataSource});

  final DevicesLocalDataSource localDataSource;

  @override
  Future<DevicesDashboard> getDashboard() {
    return localDataSource.getDashboard();
  }
}
