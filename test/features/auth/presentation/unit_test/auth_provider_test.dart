import 'package:agrisenseaiapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:agrisenseaiapp/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:agrisenseaiapp/features/auth/presentation/providers/auth_login_provider.dart';
import 'package:agrisenseaiapp/core/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements AuthRepository {
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
  test('auth provider success state', () async {
    final provider = AuthLoginProvider(
      signInWithGoogle: SignInWithGoogle(_Repo()),
    );
    expect(await provider.signInWithGoogle(), isTrue);
  });
}
