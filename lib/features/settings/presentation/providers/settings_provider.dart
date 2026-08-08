import 'package:flutter/foundation.dart';

import '../../../../core/services/alerts/alerts_store.dart';
import '../../../../core/services/local_storage/local_storage_service.dart';
import '../../../../core/services/notifications/notification_push_service.dart';
import '../../../../core/services/settings/threshold_settings_service.dart';
import '../../domain/entities/settings_dashboard.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required this.repository,
    required this.thresholdSettings,
    this.localStorageService,
    this.alertsStore,
    this.notificationPushService,
  });

  final SettingsRepository repository;
  final ThresholdSettingsService thresholdSettings;
  final LocalStorageService? localStorageService;
  final AlertsStore? alertsStore;
  final NotificationPushService? notificationPushService;

  SettingsDashboard? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;
  bool _pushNotificationsEnabled = false;
  bool _isListeningToThresholds = false;
  bool _isClearingLocalData = false;

  SettingsDashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get minTemperature => thresholdSettings.minTemperature;
  double get maxTemperature => thresholdSettings.maxTemperature;
  double get minHumidity => thresholdSettings.minHumidity;
  double get maxHumidity => thresholdSettings.maxHumidity;
  double get minMoisture => thresholdSettings.minMoisture;
  double get maxMoisture => thresholdSettings.maxMoisture;
  double get minLight => thresholdSettings.minLight;
  double get maxLight => thresholdSettings.maxLight;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get isClearingLocalData => _isClearingLocalData;

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

  Future<void> updateTemperatureRange(double minimum, double maximum) {
    return thresholdSettings.setTemperatureRange(
      minimum: minimum,
      maximum: maximum,
      persist: false,
    );
  }

  Future<void> commitTemperatureRange(double minimum, double maximum) {
    return thresholdSettings.setTemperatureRange(
      minimum: minimum,
      maximum: maximum,
    );
  }

  Future<void> updateHumidityRange(double minimum, double maximum) {
    return thresholdSettings.setHumidityRange(
      minimum: minimum,
      maximum: maximum,
      persist: false,
    );
  }

  Future<void> commitHumidityRange(double minimum, double maximum) {
    return thresholdSettings.setHumidityRange(
      minimum: minimum,
      maximum: maximum,
    );
  }

  Future<void> updateMoistureRange(double minimum, double maximum) {
    return thresholdSettings.setMoistureRange(
      minimum: minimum,
      maximum: maximum,
      persist: false,
    );
  }

  Future<void> commitMoistureRange(double minimum, double maximum) {
    return thresholdSettings.setMoistureRange(
      minimum: minimum,
      maximum: maximum,
    );
  }

  Future<void> updateLightRange(double minimum, double maximum) {
    return thresholdSettings.setLightRange(
      minimum: minimum,
      maximum: maximum,
      persist: false,
    );
  }

  Future<void> commitLightRange(double minimum, double maximum) {
    return thresholdSettings.setLightRange(minimum: minimum, maximum: maximum);
  }

  Future<void> togglePushNotifications(bool value) async {
    _pushNotificationsEnabled = value;
    notifyListeners();
    await localStorageService?.saveNotificationsEnabled(value);
    await notificationPushService?.setEnabled(value);
  }

  Future<bool> clearLocalData() async {
    if (_isClearingLocalData) {
      return false;
    }
    _isClearingLocalData = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await alertsStore?.clear();
      await localStorageService?.clearSettingsAndPreferences();
      await thresholdSettings.resetToDefaults(
        clearPersisted: localStorageService == null,
      );
      _dashboard = await repository.getDashboard();
      _pushNotificationsEnabled = _dashboard?.pushNotificationsEnabled ?? true;
      await notificationPushService?.setEnabled(_pushNotificationsEnabled);
      return true;
    } catch (_) {
      _errorMessage = 'Unable to clear local data.';
      return false;
    } finally {
      _isClearingLocalData = false;
      notifyListeners();
    }
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
