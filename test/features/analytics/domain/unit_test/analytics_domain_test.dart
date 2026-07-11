import 'package:agrisenseaiapp/features/analytics/data/datasources/analytics_local_datasource.dart';
import 'package:agrisenseaiapp/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_dashboard.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_time_range.dart';
import 'package:agrisenseaiapp/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:agrisenseaiapp/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingAnalyticsRepo implements AnalyticsRepository {
  @override
  Future<AnalyticsDashboard> getDashboard() async {
    throw Exception('err');
  }
}

void main() {
  group('Analytics Unit Tests', () {
    test('datasource returns all three periods', () async {
      final source = AnalyticsLocalDataSourceImpl();
      final dashboard = await source.getDashboard();
      expect(dashboard.periods.length, 3);
    });

    test('provider picks selected period', () async {
      final provider = AnalyticsProvider(
        repository: AnalyticsRepositoryImpl(
          localDataSource: AnalyticsLocalDataSourceImpl(),
        ),
      );

      await provider.loadDashboard();
      expect(provider.selectedPeriod, isNotNull);
      expect(provider.selectedPeriod!.range, AnalyticsTimeRange.day);

      provider.selectRange(AnalyticsTimeRange.week);
      expect(provider.selectedPeriod!.range, AnalyticsTimeRange.week);
    });

    test('provider handles repository error', () async {
      final provider = AnalyticsProvider(repository: _FailingAnalyticsRepo());
      await provider.loadDashboard();
      expect(provider.errorMessage, 'Unable to load analytics data.');
    });
  });
}
