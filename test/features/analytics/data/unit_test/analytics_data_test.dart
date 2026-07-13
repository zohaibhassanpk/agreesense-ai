import 'package:agrisenseaiapp/features/analytics/data/datasources/analytics_local_datasource.dart';
import 'package:agrisenseaiapp/features/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:agrisenseaiapp/features/analytics/data/models/analytics_dashboard_model.dart';
import 'package:agrisenseaiapp/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAnalyticsRemoteDataSource implements AnalyticsRemoteDataSource {
  _FakeAnalyticsRemoteDataSource(this.dashboard);

  final AnalyticsDashboardModel dashboard;

  @override
  Future<AnalyticsDashboardModel> getDashboard() async => dashboard;

  @override
  Stream<AnalyticsDashboardModel> watchDashboard() => Stream.value(dashboard);
}

void main() {
  group('Analytics data', () {
    test('local fixture includes light series and all four stats', () async {
      final source = AnalyticsLocalDataSourceImpl();
      final dashboard = await source.getDashboard();

      expect(dashboard.periods, hasLength(3));
      for (final period in dashboard.periods) {
        expect(period.lightIntensitySeries, isNotNull);
        expect(
          period.lightIntensitySeries!.points.length,
          greaterThanOrEqualTo(2),
        );
        expect(period.lightIntensityStats!.map((stat) => stat.label), [
          'Average',
          'Minimum',
          'Maximum',
          'Latest Reading',
        ]);
      }
    });

    test('repository streams its local fallback dashboard', () async {
      final repo = AnalyticsRepositoryImpl(
        localDataSource: AnalyticsLocalDataSourceImpl(),
      );

      final dashboard = await repo.watchDashboard().first;

      expect(dashboard.periods, hasLength(3));
    });

    test('repository delegates one-shot and live reads to remote', () async {
      final local = AnalyticsLocalDataSourceImpl();
      final remoteDashboard = await local.getDashboard();
      final repo = AnalyticsRepositoryImpl(
        localDataSource: local,
        remoteDataSource: _FakeAnalyticsRemoteDataSource(remoteDashboard),
      );

      expect(await repo.getDashboard(), same(remoteDashboard));
      expect(await repo.watchDashboard().first, same(remoteDashboard));
    });
  });
}
