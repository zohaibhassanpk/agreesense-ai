import '../../../../core/entities/app_user.dart';

abstract class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> authStateChanges();
  Future<AppUser> signInWithGoogle();
  Future<void> signOut();
}
