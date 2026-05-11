import 'analytics_metric_average.dart';
import 'analytics_metric_series.dart';
import 'analytics_time_range.dart';

class AnalyticsPeriodData {
  const AnalyticsPeriodData({
    required this.range,
    required this.tabLabel,
    required this.axisLabels,
    required this.averagesTitle,
    required this.metricSeries,
    required this.averages,
  });

  final AnalyticsTimeRange range;
  final String tabLabel;
  final List<String> axisLabels;
  final String averagesTitle;
  final List<AnalyticsMetricSeries> metricSeries;
  final List<AnalyticsMetricAverage> averages;
}
