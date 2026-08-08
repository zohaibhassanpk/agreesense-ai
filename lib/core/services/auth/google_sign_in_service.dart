import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  GoogleSignInService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await _googleSignIn.initialize();
    _isInitialized = true;
  }

  Future<GoogleSignInAccount> signIn() async {
    await _ensureInitialized();
    return _googleSignIn.authenticate();
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }
}
