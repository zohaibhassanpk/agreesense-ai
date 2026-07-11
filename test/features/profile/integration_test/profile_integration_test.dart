import 'package:agrisenseaiapp/core/entities/app_user.dart';
import 'package:agrisenseaiapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:agrisenseaiapp/features/auth/domain/usecases/sign_out.dart';
import 'package:agrisenseaiapp/features/profile/domain/entities/profile_dashboard.dart';
import 'package:agrisenseaiapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:agrisenseaiapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements ProfileRepository {
  @override
  Future<ProfileDashboard> getProfile() async {
    return const ProfileDashboard(
      title: 'Profile',
      displayName: 'Integration User',
      subtitle: 'Welcome back',
      photoUrl: null,
      selectedCrop: 'Tobacco',
      language: 'English',
      logoutLabel: 'Log Out',
    );
  }
}

class _FailingRepo implements ProfileRepository {
  @override
  Future<ProfileDashboard> getProfile() async {
    throw Exception('profile fail');
  }
}

class _AuthRepo implements AuthRepository {
  _AuthRepo({this.failSignOut = false});

  final bool failSignOut;

  @override
  Stream<AppUser?> authStateChanges() async* {}

  @override
  AppUser? get currentUser => const AppUser(uid: 'u');

  @override
  Future<AppUser> signInWithGoogle() async => const AppUser(uid: 'u2');

  @override
  Future<void> signOut() async {
    if (failSignOut) throw Exception('logout fail');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Integration', () {
    testWidgets('load and logout success flow', (tester) async {
      final provider = ProfileProvider(
        repository: _Repo(),
        signOut: SignOut(_AuthRepo()),
      );

      await provider.loadProfile();
      await provider.logout();

      expect(provider.profile?.displayName, 'Integration User');
      expect(provider.errorMessage, isNull);
    });

    testWidgets('load failure and logout failure handling', (tester) async {
      final provider = ProfileProvider(
        repository: _FailingRepo(),
        signOut: SignOut(_AuthRepo(failSignOut: true)),
      );

      await provider.loadProfile();
      expect(provider.errorMessage, 'Unable to load profile.');

      await provider.logout();
      expect(provider.errorMessage, 'Unable to log out.');
    });
  });
}
