import '../../domain/entities/profile_dashboard.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required this.localDataSource});

  final ProfileLocalDataSource localDataSource;

  @override
  Future<ProfileDashboard> getProfile() {
    return localDataSource.getProfile();
  }
}
