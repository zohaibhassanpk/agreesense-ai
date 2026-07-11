import 'package:agrisenseaiapp/features/alerts/data/datasources/alerts_local_datasource.dart';
import 'package:agrisenseaiapp/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:agrisenseaiapp/features/alerts/domain/entities/alert_filter.dart';
import 'package:agrisenseaiapp/features/alerts/domain/entities/alert_section.dart';
import 'package:agrisenseaiapp/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:agrisenseaiapp/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingAlertsRepository implements AlertsRepository {
  @override
  Future<List<AlertSection>> getAlertSections() async {
    throw Exception('alerts fail');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Alerts Integration', () {
    testWidgets('load and filter alerts', (tester) async {
      final provider = AlertsProvider(
        repository: AlertsRepositoryImpl(
          localDataSource: AlertsLocalDataSourceImpl(),
        ),
      );

      await provider.loadAlerts();
      provider.selectFilter(AlertFilterType.warnings);

      expect(provider.visibleSections.length, 1);
      expect(provider.visibleSections.first.items.length, 1);
    });

    testWidgets('load failure sets user-facing error', (tester) async {
      final provider = AlertsProvider(repository: _FailingAlertsRepository());

      await provider.loadAlerts();
      expect(provider.sections, isEmpty);
      expect(provider.errorMessage, 'Unable to load alerts.');
    });
  });
}
