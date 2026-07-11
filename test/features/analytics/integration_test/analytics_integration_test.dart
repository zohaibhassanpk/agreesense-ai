import 'package:agrisenseaiapp/features/analytics/data/datasources/analytics_local_datasource.dart';
import 'package:agrisenseaiapp/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_dashboard.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_time_range.dart';
import 'package:agrisenseaiapp/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:agrisenseaiapp/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<AnalyticsDashboard> getDashboard() async {
    throw Exception('analytics fail');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Analytics Integration', () {
    testWidgets('load and switch range', (tester) async {
      final provider = AnalyticsProvider(
        repository: AnalyticsRepositoryImpl(
          localDataSource: AnalyticsLocalDataSourceImpl(),
        ),
      );

      await provider.loadDashboard();
      provider.selectRange(AnalyticsTimeRange.month);

      expect(provider.selectedPeriod, isNotNull);
      expect(provider.selectedPeriod!.tabLabel, 'Month');
    });

    testWidgets('load failure sets message', (tester) async {
      final provider = AnalyticsProvider(
        repository: _FailingAnalyticsRepository(),
      );

      await provider.loadDashboard();
      expect(provider.dashboard, isNull);
      expect(provider.errorMessage, 'Unable to load analytics data.');
    });
  });
}
