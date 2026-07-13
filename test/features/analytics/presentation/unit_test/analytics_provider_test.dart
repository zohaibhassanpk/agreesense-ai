import 'dart:async';

import 'package:agrisenseaiapp/features/analytics/data/datasources/analytics_local_datasource.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_dashboard.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_time_range.dart';
import 'package:agrisenseaiapp/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:agrisenseaiapp/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _StreamingAnalyticsRepository implements AnalyticsRepository {
  final StreamController<AnalyticsDashboard> controller =
      StreamController<AnalyticsDashboard>();

  @override
  Future<AnalyticsDashboard> getDashboard() {
    throw UnimplementedError();
  }

  @override
  Stream<AnalyticsDashboard> watchDashboard() => controller.stream;
}

void main() {
  test(
    'provider consumes live updates and preserves last good data on error',
    () async {
      final repository = _StreamingAnalyticsRepository();
      final provider = AnalyticsProvider(repository: repository);
      final fixture = await AnalyticsLocalDataSourceImpl().getDashboard();

      final firstLoad = provider.loadDashboard();
      repository.controller.add(fixture);
      await firstLoad;

      expect(provider.dashboard, same(fixture));
      expect(provider.isLoading, isFalse);

      final updated = AnalyticsDashboard(
        title: 'Live Analytics',
        chartTitle: fixture.chartTitle,
        periods: fixture.periods,
      );
      repository.controller.add(updated);
      await pumpEventQueue();

      expect(provider.dashboard, same(updated));

      repository.controller.addError(Exception('temporary stream failure'));
      await pumpEventQueue();

      expect(provider.dashboard, same(updated));
      expect(provider.errorMessage, isNull);

      provider.selectRange(AnalyticsTimeRange.week);
      expect(provider.selectedRange, AnalyticsTimeRange.week);

      provider.dispose();
      await repository.controller.close();
    },
  );

  test(
    'disposing completes an in-flight first load without notifying',
    () async {
      final repository = _StreamingAnalyticsRepository();
      final provider = AnalyticsProvider(repository: repository);

      final Future<void> load = provider.loadDashboard();
      await pumpEventQueue();
      provider.dispose();

      await load.timeout(const Duration(seconds: 1));
      await repository.controller.close();
    },
  );
}
