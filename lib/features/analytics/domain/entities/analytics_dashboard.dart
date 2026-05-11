import 'analytics_period_data.dart';

class AnalyticsDashboard {
  const AnalyticsDashboard({
    required this.title,
    required this.chartTitle,
    required this.periods,
  });

  final String title;
  final String chartTitle;
  final List<AnalyticsPeriodData> periods;
}
