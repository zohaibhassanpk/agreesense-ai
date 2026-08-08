import 'package:firebase_auth/firebase_auth.dart';

import '../../entities/app_user.dart';
import '../logger/logger_service.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  final LoggerService _logger = LoggerService(className: 'FirebaseAuthService');

  AppUser? get currentUser => _mapUser(_auth.currentUser);

  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(_mapUser);
  }

  Future<AppUser> signInWithCredential(AuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final user = _mapUser(userCredential.user);
      if (user == null) {
        throw StateError('Missing authenticated user.');
      }
      return user;
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to sign in with credential.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to sign out.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      return await user.getIdToken();
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to fetch ID token.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      phoneNumber: user.phoneNumber,
      photoUrl: user.photoURL,
    );
  }
}
