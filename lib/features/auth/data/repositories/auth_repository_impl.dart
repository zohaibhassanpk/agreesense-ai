import '../../../../core/entities/app_user.dart';
import '../../../../core/services/local_storage/local_storage_service.dart';
import '../../../../core/services/logger/logger_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorageService,
  });

  final AuthRemoteDataSource remoteDataSource;
  final LocalStorageService localStorageService;
  final LoggerService _logger = LoggerService(className: 'AuthRepository');

  @override
  AppUser? get currentUser => remoteDataSource.currentUser;

  @override
  Stream<AppUser?> authStateChanges() {
    return remoteDataSource.authStateChanges();
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      await _cacheIdToken();
      await localStorageService.saveAuthState('signed');
      return user;
    } catch (error, stackTrace) {
      _logger.error(
        'Google sign-in failed.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
    } finally {
      await localStorageService.clearAuthData();
    }
  }

  Future<void> _cacheIdToken() async {
    final token = await remoteDataSource.getIdToken();
    if (token != null && token.isNotEmpty) {
      await localStorageService.saveAccessToken(token);
    }
  }
}
