import '../entities/analytics_dashboard.dart';

abstract class AnalyticsRepository {
  Future<AnalyticsDashboard> getDashboard();
}
