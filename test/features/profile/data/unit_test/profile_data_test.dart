import 'package:agrisenseaiapp/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:agrisenseaiapp/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:agrisenseaiapp/features/profile/data/models/profile_dashboard_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _Local implements ProfileLocalDataSource {
  @override
  Future<ProfileDashboardModel> getProfile() async {
    return const ProfileDashboardModel(
      title: 'Profile',
      displayName: 'Test',
      subtitle: 'Welcome back',
      photoUrl: null,
      selectedCrop: 'Tobacco',
      language: 'English',
      logoutLabel: 'Log Out',
    );
  }
}

void main() {
  test('profile repository returns profile', () async {
    final repo = ProfileRepositoryImpl(localDataSource: _Local());
    final profile = await repo.getProfile();
    expect(profile.displayName, 'Test');
  });
}
