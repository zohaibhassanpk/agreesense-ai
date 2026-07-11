import 'dart:async';

import 'package:flutter/foundation.dart';

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
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<HomeDashboard>? _subscription;
  bool _disposed = false;

  HomeDashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _subscription?.cancel();
    final Completer<void> firstEvent = Completer<void>();

    _subscription = repository.watchDashboard().listen(
      (HomeDashboard value) {
        _dashboard = value;
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
    try {
      await repository.setPumpStatus(isOn);
      return true;
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to update pump status',
        error: error,
        stackTrace: stackTrace,
      );
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
