import 'package:flutter/foundation.dart';

import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/home_repository.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider({required this.repository});

  final HomeRepository repository;

  HomeDashboard? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;

  HomeDashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await repository.getDashboard();
    } catch (_) {
      _errorMessage = 'Unable to load dashboard data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
