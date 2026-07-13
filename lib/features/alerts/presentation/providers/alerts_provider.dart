import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/logger/logger_service.dart';
import '../../domain/entities/alert_filter.dart';
import '../../domain/entities/alert_item.dart';
import '../../domain/entities/alert_section.dart';
import '../../domain/repositories/alerts_repository.dart';

class AlertsProvider extends ChangeNotifier {
  AlertsProvider({required this.repository});

  final AlertsRepository repository;
  final LoggerService _logger = LoggerService(className: 'AlertsProvider');

  static const Duration _firstLoadTimeout = Duration(seconds: 20);

  List<AlertSection> _sections = [];
  bool _isLoading = false;
  String? _errorMessage;
  AlertFilterType _selectedFilter = AlertFilterType.all;
  List<AlertFilter> _filters = const [];
  StreamSubscription<List<AlertSection>>? _subscription;
  Completer<void>? _firstEventCompleter;
  bool _disposed = false;

  List<AlertSection> get sections => _sections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AlertFilterType get selectedFilter => _selectedFilter;
  List<AlertFilter> get filters => _filters;

  List<AlertSection> get visibleSections {
    return _applyFilter(_selectedFilter);
  }

  Future<void> loadAlerts() async {
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

    _subscription = repository.watchAlertSections().listen(
      (List<AlertSection> sections) {
        if (_disposed) {
          if (!firstEvent.isCompleted) {
            firstEvent.complete();
          }
          return;
        }
        _sections = sections;
        _filters = _buildFilters(sections);
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        if (!firstEvent.isCompleted) {
          firstEvent.complete();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _logger.error(
          'Alerts stream failed',
          error: error,
          stackTrace: stackTrace,
        );
        if (_disposed) {
          if (!firstEvent.isCompleted) {
            firstEvent.complete();
          }
          return;
        }
        if (_sections.isEmpty) {
          _errorMessage = 'Unable to load alerts.';
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
      if (_sections.isEmpty) {
        _errorMessage = 'Unable to load alerts.';
      }
      _isLoading = false;
      notifyListeners();
    } finally {
      if (identical(_firstEventCompleter, firstEvent)) {
        _firstEventCompleter = null;
      }
    }
  }

  void selectFilter(AlertFilterType filterType) {
    if (_selectedFilter == filterType) return;
    _selectedFilter = filterType;
    notifyListeners();
  }

  List<AlertSection> _applyFilter(AlertFilterType filterType) {
    if (filterType == AlertFilterType.all) {
      return _sections;
    }

    final AlertSeverity severity = switch (filterType) {
      AlertFilterType.critical => AlertSeverity.critical,
      AlertFilterType.warnings => AlertSeverity.warning,
      AlertFilterType.all => AlertSeverity.info,
    };

    return _sections
        .map((section) {
          final filteredItems = section.items
              .where((item) => item.severity == severity)
              .toList();
          return AlertSection(
            label: section.label,
            items: filteredItems,
            isHistorical: section.isHistorical,
          );
        })
        .where((section) => section.items.isNotEmpty)
        .toList();
  }

  List<AlertFilter> _buildFilters(List<AlertSection> sections) {
    final counts = _countBySeverity(sections);
    final int criticalCount = counts[AlertSeverity.critical] ?? 0;
    final String criticalLabel = criticalCount > 0
        ? 'Critical ($criticalCount)'
        : 'Critical';

    return [
      const AlertFilter(type: AlertFilterType.all, label: 'All'),
      AlertFilter(type: AlertFilterType.critical, label: criticalLabel),
      const AlertFilter(type: AlertFilterType.warnings, label: 'Warnings'),
    ];
  }

  Map<AlertSeverity, int> _countBySeverity(List<AlertSection> sections) {
    final Map<AlertSeverity, int> counts = {
      AlertSeverity.critical: 0,
      AlertSeverity.warning: 0,
      AlertSeverity.info: 0,
    };

    for (final section in sections) {
      for (final item in section.items) {
        counts[item.severity] = (counts[item.severity] ?? 0) + 1;
      }
    }

    return counts;
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
