import 'package:flutter/foundation.dart';

import '../../domain/entities/devices_dashboard.dart';
import '../../domain/repositories/devices_repository.dart';

class DevicesProvider extends ChangeNotifier {
  DevicesProvider({required this.repository});

  final DevicesRepository repository;

  DevicesDashboard? _dashboard;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  DevicesDashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  Future<void> loadDevices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await repository.getDashboard();
    } catch (_) {
      _errorMessage = 'Unable to load devices.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAvailableDevices() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await repository.getDashboard();
    } catch (_) {
      _errorMessage = 'Unable to refresh devices.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
}
