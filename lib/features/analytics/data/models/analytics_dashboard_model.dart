import '../../domain/entities/analytics_dashboard.dart';
import 'analytics_period_data_model.dart';

class AnalyticsDashboardModel extends AnalyticsDashboard {
  const AnalyticsDashboardModel({
    required super.title,
    required super.chartTitle,
    required List<AnalyticsPeriodDataModel> super.periods,
  });
}
