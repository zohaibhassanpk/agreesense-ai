import 'package:flutter/material.dart';

import '../../domain/entities/analytics_dashboard.dart';
import '../../domain/entities/analytics_period_data.dart';
import '../../domain/entities/analytics_time_range.dart';
import '../widgets/analytics_screen_content.dart';

class AnalyticsMonthScreen extends StatelessWidget {
  const AnalyticsMonthScreen({
    super.key,
    required this.dashboard,
    required this.period,
    required this.onRangeSelected,
  });

  final AnalyticsDashboard dashboard;
  final AnalyticsPeriodData period;
  final ValueChanged<AnalyticsTimeRange> onRangeSelected;

  @override
  Widget build(BuildContext context) {
    return AnalyticsScreenContent(
      dashboard: dashboard,
      period: period,
      selectedRange: AnalyticsTimeRange.month,
      onRangeSelected: onRangeSelected,
    );
  }
}
