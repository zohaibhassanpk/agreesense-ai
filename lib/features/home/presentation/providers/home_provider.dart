import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/services/logger/logger_service.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/home_repository.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider({required this.repository});

  final HomeRepository repository;
  final LoggerService _logger = LoggerService(className: 'HomeProvider');

  /// How long the first load may take before the error state is shown. Later
  /// stream events still recover the dashboard if the connection returns.
  static const Duration _firstLoadTimeout = Duration(seconds: 20);

  HomeDashboard? _dashboard;
  HomeDashboard? _firebaseDashboard;
  bool _isLoading = false;
  bool _isPumpUpdating = false;
  bool? _pendingPumpStatus;
  int _pumpOperation = 0;
  String? _errorMessage;
  StreamSubscription<HomeDashboard>? _subscription;
  bool _disposed = false;

  HomeDashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  bool get isPumpUpdating => _isPumpUpdating;
  bool get canControlPump => _dashboard?.deviceOnline ?? false;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _subscription?.cancel();
    final Completer<void> firstEvent = Completer<void>();

    _subscription = repository.watchDashboard().listen(
      (HomeDashboard value) {
        _firebaseDashboard = value;
        final bool? pendingPumpStatus = _pendingPumpStatus;
        _dashboard = pendingPumpStatus == null
            ? value
            : value.withPumpStatus(pendingPumpStatus);
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        if (!firstEvent.isCompleted) {
          firstEvent.complete();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _logger.error(
          'Dashboard stream failed',
          error: error,
          stackTrace: stackTrace,
        );
        if (_dashboard == null) {
          _errorMessage = 'Unable to load dashboard data.';
        }
        _isLoading = false;
        notifyListeners();
        if (!firstEvent.isCompleted) {
          firstEvent.complete();
        }
      },
    );

    try {
      await firstEvent.future.timeout(_firstLoadTimeout);
    } on TimeoutException {
      if (_disposed) {
        return;
      }
      if (_dashboard == null) {
        _errorMessage = 'Unable to load dashboard data.';
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setPumpStatus(bool isOn) async {
    if (!canControlPump) {
      return false;
    }
    final int operation = ++_pumpOperation;
    _pendingPumpStatus = isOn;
    _isPumpUpdating = true;
    _dashboard = _dashboard?.withPumpStatus(isOn);
    notifyListeners();

    try {
      await repository.setPumpStatus(isOn);
      if (!_disposed && operation == _pumpOperation) {
        _pendingPumpStatus = null;
        _isPumpUpdating = false;
        _dashboard = (_firebaseDashboard ?? _dashboard)?.withPumpStatus(isOn);
        notifyListeners();
      }
      return true;
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to update pump status',
        error: error,
        stackTrace: stackTrace,
      );
      if (!_disposed && operation == _pumpOperation) {
        _pendingPumpStatus = null;
        _isPumpUpdating = false;
        _dashboard = _firebaseDashboard;
        notifyListeners();
      }
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
