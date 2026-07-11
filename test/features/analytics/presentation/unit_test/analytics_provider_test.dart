import 'package:agrisenseaiapp/features/analytics/data/datasources/analytics_local_datasource.dart';
import 'package:agrisenseaiapp/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_time_range.dart';
import 'package:agrisenseaiapp/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('analytics provider range selection works', () async {
    final provider = AnalyticsProvider(
      repository: AnalyticsRepositoryImpl(
        localDataSource: AnalyticsLocalDataSourceImpl(),
      ),
    );
    await provider.loadDashboard();
    provider.selectRange(AnalyticsTimeRange.week);
    expect(provider.selectedRange, AnalyticsTimeRange.week);
  });
}
