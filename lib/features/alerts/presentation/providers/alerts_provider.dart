import 'package:flutter/foundation.dart';

import '../../domain/entities/alert_filter.dart';
import '../../domain/entities/alert_item.dart';
import '../../domain/entities/alert_section.dart';
import '../../domain/repositories/alerts_repository.dart';

class AlertsProvider extends ChangeNotifier {
  AlertsProvider({required this.repository});

  final AlertsRepository repository;

  List<AlertSection> _sections = [];
  bool _isLoading = false;
  String? _errorMessage;
  AlertFilterType _selectedFilter = AlertFilterType.all;
  List<AlertFilter> _filters = const [];

  List<AlertSection> get sections => _sections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AlertFilterType get selectedFilter => _selectedFilter;
  List<AlertFilter> get filters => _filters;

  List<AlertSection> get visibleSections {
    return _applyFilter(_selectedFilter);
  }

  Future<void> loadAlerts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sections = await repository.getAlertSections();
      _filters = _buildFilters(_sections);
    } catch (_) {
      _errorMessage = 'Unable to load alerts.';
    } finally {
      _isLoading = false;
      notifyListeners();
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
      AlertFilter(
        type: AlertFilterType.critical,
        label: criticalLabel,
      ),
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
}
