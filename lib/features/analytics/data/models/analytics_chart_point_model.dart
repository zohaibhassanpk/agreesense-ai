import '../../domain/entities/analytics_chart_point.dart';

class AnalyticsChartPointModel extends AnalyticsChartPoint {
  const AnalyticsChartPointModel({
    required super.x,
    required super.y,
    super.breakBefore,
  });
}
