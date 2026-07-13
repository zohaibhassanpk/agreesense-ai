import 'dart:async';

import 'package:agrisenseaiapp/core/services/alerts/alerts_store.dart';
import 'package:agrisenseaiapp/features/alerts/data/datasources/alerts_live_datasource.dart';
import 'package:agrisenseaiapp/features/alerts/data/datasources/alerts_local_datasource.dart';
import 'package:agrisenseaiapp/features/alerts/data/models/alert_item_model.dart';
import 'package:agrisenseaiapp/features/alerts/data/models/alert_section_model.dart';
import 'package:agrisenseaiapp/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:agrisenseaiapp/features/alerts/domain/entities/alert_item.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeedAlertsDataSource implements AlertsLocalDataSource {
  _SeedAlertsDataSource(this.items);

  final List<AlertItemModel> items;

  @override
  Future<List<AlertSectionModel>> getAlertSections() async {
    return <AlertSectionModel>[AlertSectionModel(label: 'Seed', items: items)];
  }
}

class _FailingSeedAlertsDataSource implements AlertsLocalDataSource {
  @override
  Future<List<AlertSectionModel>> getAlertSections() async {
    throw Exception('seed unavailable');
  }
}

AlertItem _alert(String title, DateTime timestamp) {
  return AlertItem(
    title: title,
    message: '$title message',
    timeLabel: 'just now',
    timestamp: timestamp,
    severity: AlertSeverity.warning,
    icon: 'icon.svg',
  );
}

void main() {
  test('alerts repository returns sections', () async {
    final repo = AlertsRepositoryImpl(
      localDataSource: AlertsLocalDataSourceImpl(),
    );
    final sections = await repo.getAlertSections();
    expect(sections.length, greaterThan(0));
  });

  test('alerts store keeps the 50 newest session alerts', () {
    final AlertsStore store = AlertsStore();
    final DateTime start = DateTime(2026, 7, 13);

    for (int index = 0; index <= AlertsStore.maxItems; index++) {
      store.addAlert(_alert('$index', start.add(Duration(minutes: index))));
    }

    expect(store.liveItems, hasLength(AlertsStore.maxItems));
    expect(store.liveItems.first.title, '${AlertsStore.maxItems}');
    expect(store.liveItems.last.title, '1');
  });

  test(
    'live datasource merges, groups, and sorts alerts newest-first',
    () async {
      final DateTime now = DateTime.now();
      final DateTime earlier = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(hours: 1));
      final AlertsStore store = AlertsStore();
      final AlertsLiveDataSource source = AlertsLiveDataSourceImpl(
        alertsStore: store,
        localDataSource: _SeedAlertsDataSource(<AlertItemModel>[
          AlertItemModel.fromEntity(_alert('seed', earlier)),
        ]),
      );
      final StreamIterator<List<AlertSectionModel>> iterator =
          StreamIterator<List<AlertSectionModel>>(source.watchAlertSections());

      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current.single.label, 'Earlier');
      expect(iterator.current.single.isHistorical, isTrue);

      store
        ..addAlert(
          _alert('older live', now.subtract(const Duration(minutes: 2))),
        )
        ..addAlert(
          _alert('newest live', now.subtract(const Duration(minutes: 1))),
        );

      expect(await iterator.moveNext(), isTrue);
      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current.map((section) => section.label), <String>[
        'Today',
        'Earlier',
      ]);
      expect(iterator.current.first.items.map((item) => item.title), <String>[
        'newest live',
        'older live',
      ]);

      await iterator.cancel();
    },
  );

  test(
    'repository streams the live datasource when one is configured',
    () async {
      final AlertsStore store = AlertsStore();
      final AlertsLocalDataSource local = _SeedAlertsDataSource(
        <AlertItemModel>[],
      );
      final AlertsRepositoryImpl repository = AlertsRepositoryImpl(
        localDataSource: local,
        liveDataSource: AlertsLiveDataSourceImpl(
          alertsStore: store,
          localDataSource: local,
        ),
      );
      final Future<List<AlertSectionModel>> firstSections = repository
          .watchAlertSections()
          .map((sections) => sections.cast<AlertSectionModel>())
          .first;

      expect(await firstSections, isEmpty);
    },
  );

  test('live alerts remain available when seed loading fails', () async {
    final AlertsStore store = AlertsStore();
    final AlertsLiveDataSource source = AlertsLiveDataSourceImpl(
      alertsStore: store,
      localDataSource: _FailingSeedAlertsDataSource(),
    );
    final StreamIterator<List<AlertSectionModel>> iterator =
        StreamIterator<List<AlertSectionModel>>(source.watchAlertSections());

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, isEmpty);

    store.addAlert(_alert('live after failure', DateTime.now()));
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.single.items.single.title, 'live after failure');

    await iterator.cancel();
  });
}
