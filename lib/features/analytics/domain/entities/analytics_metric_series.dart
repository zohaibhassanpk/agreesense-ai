import 'analytics_chart_point.dart';

class AnalyticsMetricSeries {
  const AnalyticsMetricSeries({
    required this.label,
    required this.icon,
    required this.colorKey,
    required this.points,
  });

  final String label;
  final String icon;
  final String colorKey;
  final List<AnalyticsChartPoint> points;
}
