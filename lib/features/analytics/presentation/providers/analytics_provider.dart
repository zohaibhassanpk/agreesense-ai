import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/logger/logger_service.dart';
import '../../domain/entities/analytics_dashboard.dart';
import '../../domain/entities/analytics_period_data.dart';
import '../../domain/entities/analytics_time_range.dart';
import '../../domain/repositories/analytics_repository.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider({required this.repository});

  final AnalyticsRepository repository;
  final LoggerService _logger = LoggerService(className: 'AnalyticsProvider');

  static const Duration _firstLoadTimeout = Duration(seconds: 20);

  AnalyticsDashboard? _dashboard;
  AnalyticsTimeRange _selectedRange = AnalyticsTimeRange.day;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AnalyticsDashboard>? _subscription;
  Completer<void>? _firstEventCompleter;
  bool _disposed = false;

  AnalyticsDashboard? get dashboard => _dashboard;
  AnalyticsTimeRange get selectedRange => _selectedRange;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AnalyticsPeriodData? get selectedPeriod {
    final AnalyticsDashboard? currentDashboard = _dashboard;
    if (currentDashboard == null) {
      return null;
    }

    for (final AnalyticsPeriodData period in currentDashboard.periods) {
      if (period.range == _selectedRange) {
        return period;
      }
    }
    return null;
  }

  Future<void> loadDashboard() async {
    if (_disposed) {
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _completePendingLoad();
    await _subscription?.cancel();
    if (_disposed) {
      return;
    }
    final Completer<void> firstEvent = Completer<void>();
    _firstEventCompleter = firstEvent;

    _subscription = repository.watchDashboard().listen(
      (AnalyticsDashboard value) {
        if (_disposed) {
          return;
        }
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
          'Analytics dashboard stream failed',
          error: error,
          stackTrace: stackTrace,
        );
        if (_disposed) {
          if (!firstEvent.isCompleted) {
            firstEvent.complete();
          }
          return;
        }
        if (_dashboard == null) {
          _errorMessage = 'Unable to load analytics data.';
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
        _errorMessage = 'Unable to load analytics data.';
      }
      _isLoading = false;
      notifyListeners();
    } finally {
      if (identical(_firstEventCompleter, firstEvent)) {
        _firstEventCompleter = null;
      }
    }
  }

  void selectRange(AnalyticsTimeRange range) {
    if (_selectedRange == range) {
      return;
    }

    _selectedRange = range;
    notifyListeners();
  }

  void _completePendingLoad() {
    final Completer<void>? pending = _firstEventCompleter;
    if (pending != null && !pending.isCompleted) {
      pending.complete();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _completePendingLoad();
    _subscription?.cancel();
    super.dispose();
  }
}
