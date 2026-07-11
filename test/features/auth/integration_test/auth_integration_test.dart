import 'package:agrisenseaiapp/core/entities/app_user.dart';
import 'package:agrisenseaiapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:agrisenseaiapp/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:agrisenseaiapp/features/auth/presentation/providers/auth_login_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements AuthRepository {
  _Repo({this.shouldFail = false});

  final bool shouldFail;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield currentUser;
  }

  @override
  AppUser? get currentUser => const AppUser(uid: 'i1');

  @override
  Future<AppUser> signInWithGoogle() async {
    if (shouldFail) throw Exception('integration sign-in fail');
    return const AppUser(uid: 'i2', displayName: 'Integration');
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Integration', () {
    testWidgets('sign in success flow', (tester) async {
      final provider = AuthLoginProvider(
        signInWithGoogle: SignInWithGoogle(_Repo()),
      );

      final ok = await provider.signInWithGoogle();
      expect(ok, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
    });

    testWidgets('sign in failure flow sets error', (tester) async {
      final provider = AuthLoginProvider(
        signInWithGoogle: SignInWithGoogle(_Repo(shouldFail: true)),
      );

      final ok = await provider.signInWithGoogle();
      expect(ok, isFalse);
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, isFalse);
    });
  });
}
