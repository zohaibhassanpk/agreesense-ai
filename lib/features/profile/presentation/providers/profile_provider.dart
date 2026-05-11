import 'package:flutter/foundation.dart';

import '../../domain/entities/profile_dashboard.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../auth/domain/usecases/sign_out.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    required this.repository,
    required this.signOut,
  });

  final ProfileRepository repository;
  final SignOut signOut;

  ProfileDashboard? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileDashboard? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await repository.getProfile();
    } catch (_) {
      _errorMessage = 'Unable to load profile.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _setError(null);

    try {
      await signOut();
    } catch (_) {
      _setError('Unable to log out.');
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
