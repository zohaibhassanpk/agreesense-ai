import '../../domain/entities/analytics_period_data.dart';
import 'analytics_metric_average_model.dart';
import 'analytics_metric_series_model.dart';

class AnalyticsPeriodDataModel extends AnalyticsPeriodData {
  const AnalyticsPeriodDataModel({
    required super.range,
    required super.tabLabel,
    required super.axisLabels,
    required super.averagesTitle,
    required List<AnalyticsMetricSeriesModel> super.metricSeries,
    required List<AnalyticsMetricAverageModel> super.averages,
    AnalyticsMetricSeriesModel? super.lightIntensitySeries,
    List<AnalyticsMetricAverageModel>? super.lightIntensityStats,
  });
}
