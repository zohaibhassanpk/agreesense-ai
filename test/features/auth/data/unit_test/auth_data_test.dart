import 'package:agrisenseaiapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:agrisenseaiapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:agrisenseaiapp/core/entities/app_user.dart';
import 'package:agrisenseaiapp/core/services/local_storage/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _Remote implements AuthRemoteDataSource {
  @override
  Stream<AppUser?> authStateChanges() async* {}
  @override
  AppUser? get currentUser => const AppUser(uid: '1');
  @override
  Future<String?> getIdToken() async => 'tok';
  @override
  Future<AppUser> signInWithGoogle() async => const AppUser(uid: '2');
  @override
  Future<void> signOut() async {}
}

class _Storage extends LocalStorageService {
  @override
  Future<void> saveAccessToken(String token) async {}

  @override
  Future<void> saveAuthState(String state) async {}

  @override
  Future<void> clearAuthData() async {}
}

void main() {
  test('auth repository sign in returns user', () async {
    final repo = AuthRepositoryImpl(
      remoteDataSource: _Remote(),
      localStorageService: _Storage(),
    );
    final user = await repo.signInWithGoogle();
    expect(user.uid, '2');
  });
}
