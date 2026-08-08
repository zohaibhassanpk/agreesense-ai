import 'dart:async';

import 'package:flutter/foundation.dart';

import '../entities/app_user.dart';
import '../services/auth/firebase_auth_service.dart';

/// Read-only authentication state used by Firebase-backed features.
///
/// Keeping this as a small interface lets data sources react to account
/// changes without depending on the Firebase Auth implementation itself.
abstract interface class AuthSession {
  AppUser? get user;
  bool get isReady;
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
}

class AuthSessionProvider extends ChangeNotifier implements AuthSession {
  AuthSessionProvider({required FirebaseAuthService authService})
    : _authService = authService {
    _user = _authService.currentUser;
    _isReady = _user != null;
    _subscription = _authService.authStateChanges().listen(_handleAuthChange);
  }

  final FirebaseAuthService _authService;
  late final StreamSubscription<AppUser?> _subscription;

  AppUser? _user;
  bool _isReady = false;

  @override
  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  @override
  bool get isReady => _isReady;

  void _handleAuthChange(AppUser? user) {
    _user = user;
    if (!_isReady) {
      _isReady = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
