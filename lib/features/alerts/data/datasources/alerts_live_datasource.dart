import 'dart:async';

import '../../../../core/services/alerts/alerts_store.dart';
import '../../../../core/services/logger/logger_service.dart';
import '../../domain/entities/alert_item.dart';
import '../models/alert_item_model.dart';
import '../models/alert_section_model.dart';
import 'alerts_local_datasource.dart';

abstract class AlertsLiveDataSource {
  Stream<List<AlertSectionModel>> watchAlertSections();
}

/// Combines session alerts with the local seed data into chronological groups.
class AlertsLiveDataSourceImpl implements AlertsLiveDataSource {
  AlertsLiveDataSourceImpl({
    required this.alertsStore,
    required this.localDataSource,
  });

  final AlertsStore alertsStore;
  final AlertsLocalDataSource localDataSource;
  final LoggerService _logger = LoggerService(
    className: 'AlertsLiveDataSource',
  );

  @override
  Stream<List<AlertSectionModel>> watchAlertSections() {
    late StreamController<List<AlertSectionModel>> controller;
    List<AlertItem> seedItems = const <AlertItem>[];
    bool seedLoaded = false;
    bool isListening = false;

    void emit() {
      if (!isListening || !seedLoaded || controller.isClosed) {
        return;
      }
      controller.add(
        _groupItems(<AlertItem>[...alertsStore.liveItems, ...seedItems]),
      );
    }

    Future<void> loadSeedItems() async {
      try {
        final List<AlertSectionModel> sections = await localDataSource
            .getAlertSections();
        seedItems = sections.expand((section) => section.items).toList();
        seedLoaded = true;
        emit();
      } catch (error, stackTrace) {
        _logger.error(
          'Could not load seeded alerts; continuing with live alerts',
          error: error,
          stackTrace: stackTrace,
        );
        seedLoaded = true;
        emit();
      }
    }

    controller = StreamController<List<AlertSectionModel>>(
      onListen: () {
        isListening = true;
        alertsStore.addListener(emit);
        loadSeedItems();
      },
      onCancel: () {
        isListening = false;
        alertsStore.removeListener(emit);
      },
    );

    return controller.stream;
  }

  List<AlertSectionModel> _groupItems(List<AlertItem> items) {
    final DateTime now = DateTime.now();
    final List<AlertItem> today = <AlertItem>[];
    final List<AlertItem> earlier = <AlertItem>[];

    for (final AlertItem item in items) {
      (_isSameDate(item.timestamp, now) ? today : earlier).add(item);
    }

    int newestFirst(AlertItem a, AlertItem b) =>
        b.timestamp.compareTo(a.timestamp);
    today.sort(newestFirst);
    earlier.sort(newestFirst);

    return <AlertSectionModel>[
      if (today.isNotEmpty)
        AlertSectionModel(
          label: 'Today',
          items: today.map(AlertItemModel.fromEntity).toList(),
        ),
      if (earlier.isNotEmpty)
        AlertSectionModel(
          label: 'Earlier',
          items: earlier.map(AlertItemModel.fromEntity).toList(),
          isHistorical: true,
        ),
    ];
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
