import 'dart:async';

import 'package:agrisenseaiapp/core/services/alerts/alerts_store.dart';
import 'package:agrisenseaiapp/features/alerts/data/datasources/alerts_live_datasource.dart';
import 'package:agrisenseaiapp/features/alerts/data/datasources/alerts_local_datasource.dart';
import 'package:agrisenseaiapp/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:agrisenseaiapp/features/alerts/domain/entities/alert_item.dart';
import 'package:agrisenseaiapp/features/alerts/domain/entities/alert_section.dart';
import 'package:agrisenseaiapp/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:agrisenseaiapp/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _PendingAlertsRepository implements AlertsRepository {
  final StreamController<List<AlertSection>> controller =
      StreamController<List<AlertSection>>();

  @override
  Future<List<AlertSection>> getAlertSections() async => <AlertSection>[];

  @override
  Stream<List<AlertSection>> watchAlertSections() => controller.stream;
}

class _DelayedCancelAlertsRepository implements AlertsRepository {
  _DelayedCancelAlertsRepository() {
    controller = StreamController<List<AlertSection>>(
      onCancel: () => cancellation.future,
    );
  }

  late final StreamController<List<AlertSection>> controller;
  final Completer<void> cancellation = Completer<void>();
  int watchCalls = 0;

  @override
  Future<List<AlertSection>> getAlertSections() async => <AlertSection>[];

  @override
  Stream<List<AlertSection>> watchAlertSections() {
    watchCalls++;
    return controller.stream;
  }
}

void main() {
  test('alerts provider loads filters', () async {
    final provider = AlertsProvider(
      repository: AlertsRepositoryImpl(
        localDataSource: AlertsLocalDataSourceImpl(),
      ),
    );
    await provider.loadAlerts();
    expect(provider.filters, isNotEmpty);
  });

  test('alerts provider reacts to live store updates', () async {
    final AlertsStore store = AlertsStore();
    final AlertsLocalDataSource local = AlertsLocalDataSourceImpl();
    final AlertsProvider provider = AlertsProvider(
      repository: AlertsRepositoryImpl(
        localDataSource: local,
        liveDataSource: AlertsLiveDataSourceImpl(
          alertsStore: store,
          localDataSource: local,
        ),
      ),
    );
    await provider.loadAlerts();

    store.addAlert(
      AlertItem(
        title: 'Critical: High Temperature',
        message: 'Temperature crossed its critical threshold.',
        timeLabel: 'just now',
        timestamp: DateTime.now(),
        severity: AlertSeverity.critical,
        icon: 'assets/svgs/temprature.svg',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(provider.sections.first.items.first.title, contains('Temperature'));
    expect(provider.filters[1].label, 'Critical (2)');

    provider.dispose();
  });

  test(
    'disposing completes an in-flight first load without notifying',
    () async {
      final _PendingAlertsRepository repository = _PendingAlertsRepository();
      final AlertsProvider provider = AlertsProvider(repository: repository);

      final Future<void> load = provider.loadAlerts();
      await Future<void>.delayed(Duration.zero);
      provider.dispose();

      await expectLater(load, completes);
      await repository.controller.close();
    },
  );

  test('dispose during cancellation prevents a replacement stream', () async {
    final _DelayedCancelAlertsRepository repository =
        _DelayedCancelAlertsRepository();
    final AlertsProvider provider = AlertsProvider(repository: repository);

    final Future<void> firstLoad = provider.loadAlerts();
    await Future<void>.delayed(Duration.zero);
    repository.controller.add(<AlertSection>[]);
    await firstLoad;

    final Future<void> reload = provider.loadAlerts();
    await Future<void>.delayed(Duration.zero);
    provider.dispose();
    repository.cancellation.complete();
    await reload;

    expect(repository.watchCalls, 1);
    await repository.controller.close();
  });
}
