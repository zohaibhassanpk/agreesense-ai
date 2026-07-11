import 'package:agrisenseaiapp/core/entities/app_user.dart';
import 'package:agrisenseaiapp/core/services/local_storage/local_storage_service.dart';
import 'package:agrisenseaiapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:agrisenseaiapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:agrisenseaiapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:agrisenseaiapp/features/auth/domain/usecases/get_current_user.dart';
import 'package:agrisenseaiapp/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:agrisenseaiapp/features/auth/domain/usecases/sign_out.dart';
import 'package:agrisenseaiapp/features/auth/presentation/providers/auth_login_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({this.token = 'tkn'});

  final String? token;

  @override
  AppUser? get currentUser => const AppUser(uid: 'u1', displayName: 'Z');

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield currentUser;
  }

  @override
  Future<String?> getIdToken() async => token;

  @override
  Future<AppUser> signInWithGoogle() async {
    return const AppUser(uid: 'u1', displayName: 'Zohaib');
  }

  @override
  Future<void> signOut() async {}
}

class _FakeStorage extends LocalStorageService {
  bool savedAuth = false;
  bool savedToken = false;
  bool cleared = false;

  @override
  Future<void> saveAuthState(String state) async {
    savedAuth = state == 'signed';
  }

  @override
  Future<void> saveAccessToken(String token) async {
    savedToken = token.isNotEmpty;
  }

  @override
  Future<void> clearAuthData() async {
    cleared = true;
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.throwOnSignIn = false});

  final bool throwOnSignIn;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield currentUser;
  }

  @override
  AppUser? get currentUser => const AppUser(uid: 'x1', displayName: 'A');

  @override
  Future<AppUser> signInWithGoogle() async {
    if (throwOnSignIn) throw Exception('err');
    return const AppUser(uid: 'x2', displayName: 'B');
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  group('Auth Unit Tests', () {
    test('repository signIn caches token and auth state', () async {
      final storage = _FakeStorage();
      final repo = AuthRepositoryImpl(
        remoteDataSource: _FakeAuthRemoteDataSource(token: 'id-token'),
        localStorageService: storage,
      );

      final user = await repo.signInWithGoogle();

      expect(user.uid, 'u1');
      expect(storage.savedAuth, isTrue);
      expect(storage.savedToken, isTrue);
    });

    test('repository signOut clears auth data', () async {
      final storage = _FakeStorage();
      final repo = AuthRepositoryImpl(
        remoteDataSource: _FakeAuthRemoteDataSource(),
        localStorageService: storage,
      );

      await repo.signOut();
      expect(storage.cleared, isTrue);
    });

    test('usecases delegate correctly', () async {
      final repo = _FakeAuthRepository();
      final current = GetCurrentUser(repo)();
      final signed = await SignInWithGoogle(repo)();
      await SignOut(repo)();

      expect(current?.uid, 'x1');
      expect(signed.displayName, 'B');
    });

    test('auth provider sets error on sign-in failure', () async {
      final provider = AuthLoginProvider(
        signInWithGoogle: SignInWithGoogle(
          _FakeAuthRepository(throwOnSignIn: true),
        ),
      );

      final result = await provider.signInWithGoogle();

      expect(result, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, 'Unable to sign in with Google.');
    });
  });
}
