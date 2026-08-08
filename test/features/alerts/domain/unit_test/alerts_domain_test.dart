import 'package:agrisenseaiapp/features/alerts/data/datasources/alerts_local_datasource.dart';
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

class _StaticAlertsRepo implements AlertsRepository {
  _StaticAlertsRepo(this.sections);

  final List<AlertSection> sections;

  @override
  Future<List<AlertSection>> getAlertSections() async => sections;

  @override
  Stream<List<AlertSection>> watchAlertSections() => Stream.value(sections);
}

List<AlertSection> _warningAndCriticalSections() {
  final DateTime now = DateTime.now();
  return <AlertSection>[
    AlertSection(
      label: 'Today',
      items: <AlertItem>[
        AlertItem(
          title: 'Warning: High Temperature',
          message: 'Temperature is above its configured warning threshold.',
          timestamp: now,
          severity: AlertSeverity.warning,
          icon: 'warning.svg',
        ),
        AlertItem(
          title: 'Critical: High Temperature',
          message: 'Temperature is above its critical threshold.',
          timestamp: now,
          severity: AlertSeverity.critical,
          icon: 'critical.svg',
        ),
      ],
    ),
  ];
}

void main() {
  group('Alerts Unit Tests', () {
    test(
      'local datasource does not inject demo or info notifications',
      () async {
        final source = AlertsLocalDataSourceImpl();
        final sections = await source.getAlertSections();

        expect(sections, isEmpty);
      },
    );

    test('provider loads and builds filter labels', () async {
      final provider = AlertsProvider(
        repository: _StaticAlertsRepo(_warningAndCriticalSections()),
      );

      await provider.loadAlerts();
      expect(provider.filters.length, 3);
      expect(provider.filters.map((filter) => filter.label), <String>[
        'All (2)',
        'Warning (1)',
        'Critical (1)',
      ]);
    });

    test('provider filter selection narrows sections', () async {
      final provider = AlertsProvider(
        repository: _StaticAlertsRepo(_warningAndCriticalSections()),
      );
      await provider.loadAlerts();

      expect(provider.visibleSections.single.items, hasLength(2));
      provider.selectFilter(AlertFilterType.critical);
      expect(provider.visibleSections.length, 1);
      expect(
        provider.visibleSections.first.items.first.severity,
        AlertSeverity.critical,
      );
      provider.selectFilter(AlertFilterType.warnings);
      expect(
        provider.visibleSections.single.items.single.severity,
        AlertSeverity.warning,
      );
    });

    test('provider reports load error', () async {
      final provider = AlertsProvider(repository: _FailingAlertsRepo());
      await provider.loadAlerts();
      expect(provider.errorMessage, 'Unable to load alerts.');
    });
  });
}
