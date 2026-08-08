import 'analytics_metric_average.dart';
import 'analytics_metric_series.dart';
import 'analytics_time_range.dart';

class AnalyticsPeriodData {
  const AnalyticsPeriodData({
    required this.range,
    required this.tabLabel,
    required this.axisLabels,
    this.yAxisLabels = const <String>['100', '75', '50', '25', '0'],
    this.lightYAxisLabels = const <String>['100', '75', '50', '25', '0'],
    required this.averagesTitle,
    required this.metricSeries,
    required this.averages,
  });

  final AnalyticsTimeRange range;
  final String tabLabel;
  final List<String> axisLabels;
  final List<String> yAxisLabels;
  final List<String> lightYAxisLabels;
  final String averagesTitle;
  final List<AnalyticsMetricSeries> metricSeries;
  final List<AnalyticsMetricAverage> averages;
}
