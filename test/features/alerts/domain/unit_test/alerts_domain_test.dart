import 'package:agrisenseaiapp/features/alerts/data/datasources/alerts_local_datasource.dart';
import 'package:agrisenseaiapp/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:agrisenseaiapp/features/alerts/domain/entities/alert_filter.dart';
import 'package:agrisenseaiapp/features/alerts/domain/entities/alert_item.dart';
import 'package:agrisenseaiapp/features/alerts/domain/entities/alert_section.dart';
import 'package:agrisenseaiapp/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:agrisenseaiapp/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingAlertsRepo implements AlertsRepository {
  @override
  Future<List<AlertSection>> getAlertSections() async {
    throw Exception('x');
  }

  @override
  Stream<List<AlertSection>> watchAlertSections() =>
      Stream<List<AlertSection>>.error(Exception('x'));
}

void main() {
  group('Alerts Unit Tests', () {
    test('datasource returns sections and severities', () async {
      final source = AlertsLocalDataSourceImpl();
      final sections = await source.getAlertSections();

      expect(sections.length, 2);
      expect(sections.first.items.first.severity, AlertSeverity.critical);
    });

    test('provider loads and builds filter labels', () async {
      final provider = AlertsProvider(
        repository: AlertsRepositoryImpl(
          localDataSource: AlertsLocalDataSourceImpl(),
        ),
      );

      await provider.loadAlerts();
      expect(provider.filters.length, 3);
      expect(provider.filters[1].label, contains('Critical'));
    });

    test('provider filter selection narrows sections', () async {
      final provider = AlertsProvider(
        repository: AlertsRepositoryImpl(
          localDataSource: AlertsLocalDataSourceImpl(),
        ),
      );
      await provider.loadAlerts();

      provider.selectFilter(AlertFilterType.critical);
      expect(provider.visibleSections.length, 1);
      expect(
        provider.visibleSections.first.items.first.severity,
        AlertSeverity.critical,
      );
    });

    test('provider reports load error', () async {
      final provider = AlertsProvider(repository: _FailingAlertsRepo());
      await provider.loadAlerts();
      expect(provider.errorMessage, 'Unable to load alerts.');
    });
  });
}
