import '../../domain/entities/analytics_metric_series.dart';
import 'analytics_chart_point_model.dart';

class AnalyticsMetricSeriesModel extends AnalyticsMetricSeries {
  const AnalyticsMetricSeriesModel({
    required super.label,
    required super.icon,
    required super.colorKey,
    required List<AnalyticsChartPointModel> super.points,
  });
}
