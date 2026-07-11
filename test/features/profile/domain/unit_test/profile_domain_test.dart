import 'package:agrisenseaiapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:agrisenseaiapp/features/auth/domain/usecases/sign_out.dart';
import 'package:agrisenseaiapp/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:agrisenseaiapp/features/profile/domain/entities/profile_dashboard.dart';
import 'package:agrisenseaiapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:agrisenseaiapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:agrisenseaiapp/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:agrisenseaiapp/features/profile/data/models/profile_dashboard_model.dart';
import 'package:agrisenseaiapp/core/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfileDataSource implements ProfileLocalDataSource {
  @override
  Future<ProfileDashboardModel> getProfile() async {
    return const ProfileDashboardModel(
      title: 'Profile',
      displayName: 'Zohaib Hassan',
      subtitle: 'Welcome back',
      photoUrl: null,
      selectedCrop: 'Tobacco',
      language: 'English',
      logoutLabel: 'Log Out',
    );
  }
}

class _FailingProfileRepo implements ProfileRepository {
  @override
  Future<ProfileDashboard> getProfile() async {
    throw Exception('e');
  }
}

class _FakeAuthRepo implements AuthRepository {
  _FakeAuthRepo({this.throwOnSignOut = false});

  final bool throwOnSignOut;

  @override
  Stream<AppUser?> authStateChanges() async* {}

  @override
  AppUser? get currentUser => const AppUser(uid: 'p1');

  @override
  Future<AppUser> signInWithGoogle() async => const AppUser(uid: 'p2');

  @override
  Future<void> signOut() async {
    if (throwOnSignOut) throw Exception('logout fail');
  }
}

void main() {
  group('Profile Unit Tests', () {
    test('repository returns profile model from datasource', () async {
      final repo = ProfileRepositoryImpl(
        localDataSource: _FakeProfileDataSource(),
      );
      final data = await repo.getProfile();
      expect(data.displayName, 'Zohaib Hassan');
    });

    test('provider loads profile', () async {
      final provider = ProfileProvider(
        repository: ProfileRepositoryImpl(
          localDataSource: _FakeProfileDataSource(),
        ),
        signOut: SignOut(_FakeAuthRepo()),
      );

      await provider.loadProfile();
      expect(provider.profile, isNotNull);
      expect(provider.errorMessage, isNull);
    });

    test('provider handles load error', () async {
      final provider = ProfileProvider(
        repository: _FailingProfileRepo(),
        signOut: SignOut(_FakeAuthRepo()),
      );

      await provider.loadProfile();
      expect(provider.errorMessage, 'Unable to load profile.');
    });

    test('provider handles logout failure', () async {
      final provider = ProfileProvider(
        repository: ProfileRepositoryImpl(
          localDataSource: _FakeProfileDataSource(),
        ),
        signOut: SignOut(_FakeAuthRepo(throwOnSignOut: true)),
      );

      await provider.logout();
      expect(provider.errorMessage, 'Unable to log out.');
      expect(provider.isLoading, isFalse);
    });
  });
}
