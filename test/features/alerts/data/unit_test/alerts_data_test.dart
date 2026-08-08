import 'dart:async';
import 'dart:convert';

import 'package:agrisenseaiapp/core/services/alerts/alerts_store.dart';
import 'package:agrisenseaiapp/core/services/local_storage/local_storage_service.dart';
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

class _MemoryAlertStorage extends LocalStorageService {
  String? alertsJson;
  Completer<void>? nextSave;

  @override
  Future<String?> getSensorAlertsJson() async => alertsJson;

  @override
  Future<void> saveSensorAlertsJson(String json) async {
    alertsJson = json;
    nextSave?.complete();
    nextSave = null;
  }
}

AlertItem _alert(
  String title,
  DateTime timestamp, {
  AlertSeverity severity = AlertSeverity.warning,
}) {
  return AlertItem(
    title: title,
    message: '$title message',
    recommendedAction: 'Inspect the tobacco field and verify the sensor.',
    timestamp: timestamp,
    createdAt: timestamp,
    severity: severity,
    icon: 'icon.svg',
  );
}

void main() {
  test('alerts repository returns sections', () async {
    final repo = AlertsRepositoryImpl(
      localDataSource: AlertsLocalDataSourceImpl(),
    );
    final sections = await repo.getAlertSections();
    expect(sections, isEmpty);
  });

  test('alerts store keeps the 50 newest session alerts', () {
    final AlertsStore store = AlertsStore();
    final DateTime start = DateTime.now().subtract(
      Duration(minutes: AlertsStore.maxItems + 1),
    );

    for (int index = 0; index <= AlertsStore.maxItems; index++) {
      store.addAlert(_alert('$index', start.add(Duration(minutes: index))));
    }

    expect(store.liveItems, hasLength(AlertsStore.maxItems));
    expect(store.liveItems.first.title, '${AlertsStore.maxItems}');
    expect(store.liveItems.last.title, '1');
  });

  test('alerts store restores and persists Warning/Critical alerts', () async {
    final _MemoryAlertStorage storage = _MemoryAlertStorage();
    final DateTime timestamp = DateTime.now().subtract(
      const Duration(minutes: 2),
    );
    storage.alertsJson = jsonEncode(<Map<String, String>>[
      <String, String>{
        'title': 'Warning: High Temperature',
        'message': 'Temperature is high.',
        'timestamp': timestamp.toIso8601String(),
        'severity': 'warning',
        'icon': 'temperature.svg',
      },
    ]);
    final AlertsStore store = AlertsStore(storage: storage);

    await store.load();
    expect(store.liveItems.single.severity, AlertSeverity.warning);

    storage.nextSave = Completer<void>();
    store.addAlert(
      _alert(
        'Critical: High Temperature',
        timestamp.add(const Duration(minutes: 1)),
        severity: AlertSeverity.critical,
      ),
    );
    await storage.nextSave!.future;

    final List<Object?> saved =
        jsonDecode(storage.alertsJson!) as List<Object?>;
    expect(saved, hasLength(2));
    expect((saved.first as Map<String, Object?>)['severity'], 'critical');
    expect(
      (saved.first as Map<String, Object?>)['recommendedAction'],
      contains('tobacco'),
    );
  });

  test('alerts store merges history written by a background isolate', () async {
    final _MemoryAlertStorage storage = _MemoryAlertStorage();
    final DateTime now = DateTime.now().subtract(const Duration(minutes: 10));
    final AlertsStore store = AlertsStore(storage: storage);
    store.addAlert(_alert('foreground', now));
    await store.flush();

    storage.alertsJson = jsonEncode(<Map<String, String>>[
      <String, String>{
        'title': 'background',
        'message': 'background message',
        'timestamp': now.add(const Duration(minutes: 5)).toIso8601String(),
        'severity': 'critical',
        'icon': 'icon.svg',
      },
    ]);
    await store.reload();

    expect(store.liveItems.map((AlertItem item) => item.title), <String>[
      'background',
      'foreground',
    ]);
  });

  test(
    'live datasource merges, groups, and sorts alerts newest-first',
    () async {
      final DateTime now = DateTime.now();
      final DateTime earlier = now.subtract(const Duration(hours: 1));
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
      expect(iterator.current.single.label, 'Today');

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
      ]);
      expect(iterator.current.first.items.map((item) => item.title), <String>[
        'newest live',
        'older live',
        'seed',
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

  test('alerts store rejects and removes entries at least eight hours old', () {
    final DateTime now = DateTime.now();
    final AlertsStore store = AlertsStore();

    expect(
      store.addAlert(_alert('expired', now.subtract(alertRetention))),
      isFalse,
    );
    expect(
      store.addAlert(
        _alert(
          'recent',
          now.subtract(alertRetention).add(const Duration(minutes: 1)),
        ),
      ),
      isTrue,
    );
    expect(store.liveItems.map((AlertItem item) => item.title), <String>[
      'recent',
    ]);

    expect(
      _alert(
        'boundary',
        now.subtract(alertRetention),
      ).isWithinRetention(now: now),
      isFalse,
    );
  });

  test(
    'live datasource excludes stale cached alerts from sections and counts',
    () async {
      final DateTime now = DateTime.now();
      final AlertsStore store = AlertsStore();
      final AlertsLiveDataSource source = AlertsLiveDataSourceImpl(
        alertsStore: store,
        localDataSource: _SeedAlertsDataSource(<AlertItemModel>[
          AlertItemModel.fromEntity(
            _alert('expired seed', now.subtract(const Duration(hours: 9))),
          ),
          AlertItemModel.fromEntity(
            _alert('recent seed', now.subtract(const Duration(hours: 1))),
          ),
        ]),
      );
      final List<AlertSectionModel> sections = await source
          .watchAlertSections()
          .first;

      expect(
        sections
            .expand((AlertSectionModel section) => section.items)
            .map((AlertItem item) => item.title),
        <String>['recent seed'],
      );
    },
  );
}
