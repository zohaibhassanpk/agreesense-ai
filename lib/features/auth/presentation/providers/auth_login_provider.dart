import 'package:flutter/foundation.dart';

import '../../../../core/services/logger/logger_service.dart';
import '../../domain/usecases/sign_in_with_google.dart';

/// Provider for auth login screen state.
class AuthLoginProvider extends ChangeNotifier {
  AuthLoginProvider({
    required SignInWithGoogle signInWithGoogle,
  }) : _signInWithGoogle = signInWithGoogle;

  final SignInWithGoogle _signInWithGoogle;
  final LoggerService _logger = LoggerService(className: 'AuthLoginProvider');
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;


  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);

    try {
      await _signInWithGoogle();
      return true;
    } catch (error, stackTrace) {
      _logger.error(
        'Google sign-in failed.',
        error: error,
        stackTrace: stackTrace,
      );
      _setError('Unable to sign in with Google.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

}
