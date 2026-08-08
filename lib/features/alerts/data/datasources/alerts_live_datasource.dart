import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/providers/auth_session_provider.dart';
import '../../../../core/services/alerts/alerts_store.dart';
import '../../../../core/services/logger/logger_service.dart';
import '../../domain/entities/alert_item.dart';
import '../models/alert_item_model.dart';
import '../models/alert_section_model.dart';
import 'alerts_local_datasource.dart';

abstract class AlertsLiveDataSource {
  Stream<List<AlertSectionModel>> watchAlertSections();
}

/// Combines server-persisted notification alerts, local FCM alerts, and local
/// seed data into chronological groups.
class AlertsLiveDataSourceImpl implements AlertsLiveDataSource {
  AlertsLiveDataSourceImpl({
    required this.alertsStore,
    required this.localDataSource,
    this.database,
    this.authSession,
  });

  final AlertsStore alertsStore;
  final AlertsLocalDataSource localDataSource;
  final FirebaseDatabase? database;
  final AuthSession? authSession;
  final LoggerService _logger = LoggerService(
    className: 'AlertsLiveDataSource',
  );

  @override
  Stream<List<AlertSectionModel>> watchAlertSections() {
    late StreamController<List<AlertSectionModel>> controller;
    List<AlertItem> seedItems = const <AlertItem>[];
    List<AlertItem> remoteItems = const <AlertItem>[];
    StreamSubscription<DatabaseEvent>? remoteSubscription;
    Timer? retentionRefreshTimer;
    bool seedLoaded = false;
    bool isListening = false;
    String? boundUserUid;
    int bindingGeneration = 0;

    void emit() {
      if (!isListening || !seedLoaded || controller.isClosed) {
        return;
      }
      controller.add(
        _groupItems(
          _deduplicate(
            <AlertItem>[
              ...remoteItems,
              ...alertsStore.liveItems,
              ...seedItems,
            ].where((AlertItem item) => item.isWithinRetention()).toList(),
          ),
        ),
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

    Future<void> bindRemoteAlerts() async {
      final int generation = ++bindingGeneration;
      final String? uid = authSession?.user?.uid;
      final StreamSubscription<DatabaseEvent>? previous = remoteSubscription;
      remoteSubscription = null;
      remoteItems = const <AlertItem>[];
      await previous?.cancel();
      emit();

      final FirebaseDatabase? remoteDatabase = database;
      if (!isListening ||
          generation != bindingGeneration ||
          uid == null ||
          remoteDatabase == null) {
        return;
      }

      remoteSubscription = remoteDatabase
          .ref('notificationAlerts/$uid')
          .orderByChild('timestamp')
          .startAt(
            DateTime.now().subtract(alertRetention).millisecondsSinceEpoch,
          )
          .onValue
          .listen(
            (DatabaseEvent event) {
              if (!isListening || generation != bindingGeneration) {
                return;
              }
              remoteItems = _parseRemoteAlerts(event.snapshot.value);
              emit();
            },
            onError: (Object error, StackTrace stackTrace) {
              _logger.error(
                'Could not stream server notification alerts',
                error: error,
                stackTrace: stackTrace,
              );
            },
          );
    }

    void handleAuthChange() {
      final String? uid = authSession?.user?.uid;
      if (uid == boundUserUid) {
        return;
      }
      boundUserUid = uid;
      unawaited(bindRemoteAlerts());
    }

    controller = StreamController<List<AlertSectionModel>>(
      onListen: () {
        isListening = true;
        alertsStore.addListener(emit);
        authSession?.addListener(handleAuthChange);
        retentionRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
          if (!alertsStore.pruneExpired()) {
            emit();
          }
        });
        loadSeedItems();
        handleAuthChange();
      },
      onCancel: () async {
        isListening = false;
        bindingGeneration++;
        alertsStore.removeListener(emit);
        authSession?.removeListener(handleAuthChange);
        retentionRefreshTimer?.cancel();
        await remoteSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  List<AlertItem> _parseRemoteAlerts(Object? raw) {
    final Iterable<Object?> values = switch (raw) {
      Map<Object?, Object?> map => map.values,
      List<Object?> list => list,
      _ => const <Object?>[],
    };

    return values
        .map(_parseRemoteAlert)
        .whereType<AlertItem>()
        .toList(growable: false);
  }

  AlertItem? _parseRemoteAlert(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final String title = '${raw['title'] ?? ''}'.trim();
    final String message = '${raw['message'] ?? ''}'.trim();
    final String recommendedAction = '${raw['recommendedAction'] ?? ''}'.trim();
    final String metric = '${raw['metric'] ?? ''}';
    final AlertSeverity? severity = switch (raw['severity']) {
      'critical' => AlertSeverity.critical,
      'warning' => AlertSeverity.warning,
      _ => null,
    };
    final DateTime? timestamp = _toDateTime(raw['timestamp']);
    final DateTime? createdAt = _toDateTime(raw['createdAt']);
    if (title.isEmpty ||
        message.isEmpty ||
        severity == null ||
        timestamp == null) {
      return null;
    }

    return AlertItem(
      eventId: '${raw['eventId'] ?? ''}',
      title: title,
      message: message,
      recommendedAction: recommendedAction,
      timestamp: timestamp,
      createdAt: createdAt,
      severity: severity,
      icon: switch (metric) {
        'temperature' => AppAssets.temprature,
        'humidity' => AppAssets.cloud,
        'soilMoisture' => AppAssets.drop,
        'lightIntensity' => AppAssets.sun,
        _ => AppAssets.alert,
      },
    );
  }

  DateTime? _toDateTime(Object? raw) {
    final num? numeric = switch (raw) {
      num value => value,
      String value => num.tryParse(value),
      _ => null,
    };
    if (numeric == null || numeric <= 0) {
      return null;
    }
    final int milliseconds = numeric < 100000000000
        ? (numeric * 1000).round()
        : numeric.round();
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  List<AlertItem> _deduplicate(List<AlertItem> items) {
    final Set<String> seen = <String>{};
    return items
        .where((AlertItem item) {
          final String key = <Object>[
            item.timestamp.millisecondsSinceEpoch,
            item.severity.name,
            item.title,
            item.message,
          ].join('\u0000');
          return seen.add(key);
        })
        .toList(growable: false);
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
