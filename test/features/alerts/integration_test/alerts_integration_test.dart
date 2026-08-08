import 'package:agrisenseaiapp/features/alerts/domain/entities/alert_filter.dart';
import 'package:agrisenseaiapp/features/alerts/domain/entities/alert_item.dart';
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

  @override
  Stream<List<AlertSection>> watchAlertSections() =>
      Stream<List<AlertSection>>.error(Exception('alerts fail'));
}

class _CategorizedAlertsRepository implements AlertsRepository {
  _CategorizedAlertsRepository() {
    final DateTime now = DateTime.now();
    sections = <AlertSection>[
      AlertSection(
        label: 'Today',
        items: <AlertItem>[
          AlertItem(
            title: 'Warning: High Temperature',
            message: 'Temperature crossed its warning threshold.',
            timestamp: now,
            severity: AlertSeverity.warning,
            icon: 'warning.svg',
          ),
          AlertItem(
            title: 'Critical: High Temperature',
            message: 'Temperature crossed its critical threshold.',
            timestamp: now,
            severity: AlertSeverity.critical,
            icon: 'critical.svg',
          ),
        ],
      ),
    ];
  }

  late final List<AlertSection> sections;

  @override
  Future<List<AlertSection>> getAlertSections() async => sections;

  @override
  Stream<List<AlertSection>> watchAlertSections() => Stream.value(sections);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Alerts Integration', () {
    testWidgets('load and filter alerts', (tester) async {
      final provider = AlertsProvider(
        repository: _CategorizedAlertsRepository(),
      );

      await provider.loadAlerts();
      provider.selectFilter(AlertFilterType.warnings);

      expect(provider.visibleSections.length, 1);
      expect(provider.visibleSections.first.items.length, 1);
      expect(
        provider.visibleSections.first.items.single.severity,
        AlertSeverity.warning,
      );
      provider.dispose();
    });

    testWidgets('load failure sets user-facing error', (tester) async {
      final provider = AlertsProvider(repository: _FailingAlertsRepository());

      await provider.loadAlerts();
      expect(provider.sections, isEmpty);
      expect(provider.errorMessage, 'Unable to load alerts.');
      provider.dispose();
    });
  });
}
