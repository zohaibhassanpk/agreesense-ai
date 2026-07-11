import 'package:flutter/foundation.dart';

import '../../domain/entities/analytics_dashboard.dart';
import '../../domain/entities/analytics_period_data.dart';
import '../../domain/entities/analytics_time_range.dart';
import '../../domain/repositories/analytics_repository.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider({required this.repository});

  final AnalyticsRepository repository;

  AnalyticsDashboard? _dashboard;
  AnalyticsTimeRange _selectedRange = AnalyticsTimeRange.day;
  bool _isLoading = false;
  String? _errorMessage;

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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await repository.getDashboard();
    } catch (_) {
      _errorMessage = 'Unable to load analytics data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectRange(AnalyticsTimeRange range) {
    if (_selectedRange == range) {
      return;
    }

    _selectedRange = range;
    notifyListeners();
  }
}
