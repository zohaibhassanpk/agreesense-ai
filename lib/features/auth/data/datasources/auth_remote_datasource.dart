import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/entities/app_user.dart';
import '../../../../core/services/auth/firebase_auth_service.dart';
import '../../../../core/services/auth/google_sign_in_service.dart';

abstract class AuthRemoteDataSource {
  AppUser? get currentUser;
  Stream<AppUser?> authStateChanges();
  Future<AppUser> signInWithGoogle();
  Future<void> signOut();
  Future<String?> getIdToken();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required this.firebaseAuthService,
    required this.googleSignInService,
  });

  final FirebaseAuthService firebaseAuthService;
  final GoogleSignInService googleSignInService;

  @override
  AppUser? get currentUser => firebaseAuthService.currentUser;

  @override
  Stream<AppUser?> authStateChanges() {
    return firebaseAuthService.authStateChanges();
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final account = await googleSignInService.signIn();
    final auth = account.authentication;

    if (auth.idToken == null) {
      throw StateError('Missing Google authentication token.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
    );

    return firebaseAuthService.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await googleSignInService.signOut();
    await firebaseAuthService.signOut();
  }

  @override
  Future<String?> getIdToken() {
    return firebaseAuthService.getIdToken();
  }
}
