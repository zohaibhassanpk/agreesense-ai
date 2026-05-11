import 'package:flutter/foundation.dart';

import '../../domain/entities/settings_dashboard.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({required this.repository});

  final SettingsRepository repository;

  SettingsDashboard? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;
  double _minMoisture = 0;
  double _maxTemperature = 0;
  bool _pushNotificationsEnabled = false;

  SettingsDashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get minMoisture => _minMoisture;
  double get maxTemperature => _maxTemperature;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await repository.getDashboard();
      if (_dashboard != null) {
        _minMoisture = _dashboard!.minMoisture;
        _maxTemperature = _dashboard!.maxTemperature;
        _pushNotificationsEnabled =
            _dashboard!.pushNotificationsEnabled;
      }
    } catch (_) {
      _errorMessage = 'Unable to load settings.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateMinMoisture(double value) {
    _minMoisture = value;
    notifyListeners();
  }

  void updateMaxTemperature(double value) {
    _maxTemperature = value;
    notifyListeners();
  }

  void togglePushNotifications(bool value) {
    _pushNotificationsEnabled = value;
    notifyListeners();
  }
}
