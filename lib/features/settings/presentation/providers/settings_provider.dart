import 'package:flutter/foundation.dart';

import '../../../../core/services/settings/threshold_settings_service.dart';
import '../../domain/entities/settings_dashboard.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({required this.repository, required this.thresholdSettings});

  final SettingsRepository repository;
  final ThresholdSettingsService thresholdSettings;

  SettingsDashboard? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;
  bool _pushNotificationsEnabled = false;
  bool _isListeningToThresholds = false;

  SettingsDashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get minMoisture => thresholdSettings.minMoisture;
  double get maxTemperature => thresholdSettings.maxTemperature;
  double get maxHumidity => thresholdSettings.maxHumidity;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await repository.getDashboard();
      if (_dashboard != null) {
        _pushNotificationsEnabled = _dashboard!.pushNotificationsEnabled;
      }
      _listenToThresholdSettings();
      await thresholdSettings.load();
    } catch (_) {
      _errorMessage = 'Unable to load settings.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMinMoisture(double value) {
    return thresholdSettings.setMinMoisture(value, persist: false);
  }

  Future<void> commitMinMoisture(double value) {
    return thresholdSettings.setMinMoisture(value);
  }

  Future<void> updateMaxTemperature(double value) {
    return thresholdSettings.setMaxTemperature(value, persist: false);
  }

  Future<void> commitMaxTemperature(double value) {
    return thresholdSettings.setMaxTemperature(value);
  }

  Future<void> updateMaxHumidity(double value) {
    return thresholdSettings.setMaxHumidity(value, persist: false);
  }

  Future<void> commitMaxHumidity(double value) {
    return thresholdSettings.setMaxHumidity(value);
  }

  void togglePushNotifications(bool value) {
    _pushNotificationsEnabled = value;
    notifyListeners();
  }

  void _listenToThresholdSettings() {
    if (_isListeningToThresholds) {
      return;
    }
    thresholdSettings.addListener(_notifyThresholdChange);
    _isListeningToThresholds = true;
  }

  void _notifyThresholdChange() {
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isListeningToThresholds) {
      thresholdSettings.removeListener(_notifyThresholdChange);
    }
    super.dispose();
  }
}
