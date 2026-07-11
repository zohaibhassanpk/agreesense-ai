import 'package:agrisenseaiapp/core/entities/app_user.dart';
import 'package:agrisenseaiapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:agrisenseaiapp/features/auth/domain/usecases/sign_out.dart';
import 'package:agrisenseaiapp/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:agrisenseaiapp/features/profile/data/models/profile_dashboard_model.dart';
import 'package:agrisenseaiapp/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:agrisenseaiapp/features/profile/presentation/providers/profile_provider.dart';
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

class _Auth implements AuthRepository {
  @override
  Stream<AppUser?> authStateChanges() async* {}
  @override
  AppUser? get currentUser => const AppUser(uid: '1');
  @override
  Future<AppUser> signInWithGoogle() async => const AppUser(uid: '2');
  @override
  Future<void> signOut() async {}
}

void main() {
  test('profile provider loads and logs out', () async {
    final provider = ProfileProvider(
      repository: ProfileRepositoryImpl(localDataSource: _Local()),
      signOut: SignOut(_Auth()),
    );
    await provider.loadProfile();
    await provider.logout();
    expect(provider.profile, isNotNull);
  });
}
