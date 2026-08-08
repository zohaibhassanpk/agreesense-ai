import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../features/alerts/domain/entities/alert_item.dart';
import '../local_storage/local_storage_service.dart';
import '../logger/logger_service.dart';

/// Holds and persists the bounded list of sensor alerts generated on-device.
class AlertsStore extends ChangeNotifier {
  AlertsStore({LocalStorageService? storage}) : _storage = storage;

  static const int maxItems = 50;

  final LocalStorageService? _storage;
  final LoggerService _logger = LoggerService(className: 'AlertsStore');
  final List<AlertItem> _liveItems = <AlertItem>[];
  Future<void>? _loadFuture;
  Future<void> _writeQueue = Future<void>.value();

  /// Returns an immutable snapshot of the current live alerts.
  List<AlertItem> get liveItems => List<AlertItem>.unmodifiable(_liveItems);

  /// Restores locally persisted alerts once during application startup.
  Future<void> load() => _loadFuture ??= _loadPersistedAlerts();

  /// Merges alerts written by a background isolate into this process's live
  /// store. Secure storage has no cross-isolate change stream, so the UI calls
  /// this when the application resumes after a background notification.
  Future<void> reload() async {
    final LocalStorageService? storage = _storage;
    if (storage == null) {
      return;
    }

    await _writeQueue;
    try {
      final List<AlertItem> persisted = await _readPersistedAlerts(storage);
      final Map<String, AlertItem> merged = <String, AlertItem>{
        for (final AlertItem item in _liveItems) _identityOf(item): item,
        for (final AlertItem item in persisted) _identityOf(item): item,
      };
      final List<AlertItem> next = merged.values.toList()
        ..removeWhere((AlertItem item) => !item.isWithinRetention())
        ..sort(
          (AlertItem first, AlertItem second) =>
              second.timestamp.compareTo(first.timestamp),
        );
      if (_hasSameItems(next.take(maxItems).toList(growable: false))) {
        return;
      }
      _liveItems
        ..clear()
        ..addAll(next.take(maxItems));
      notifyListeners();
    } catch (error, stackTrace) {
      _logger.error(
        'Could not refresh persisted sensor alerts',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Waits until all queued local-history writes have completed. Background
  /// workers call this before their isolate exits.
  Future<void> flush() => _writeQueue;

  /// Adds [item] newest-first and evicts the oldest item when at capacity.
  /// Inserts an event once. Returns false when the same notification event was
  /// already recorded by another callback or background isolate.
  bool addAlert(AlertItem item) {
    if (!item.isWithinRetention()) {
      return false;
    }
    if (_liveItems.any(
      (AlertItem existing) => _identityOf(existing) == _identityOf(item),
    )) {
      return false;
    }
    _liveItems.insert(0, item);
    if (_liveItems.length > maxItems) {
      _liveItems.removeLast();
    }
    _schedulePersist();
    notifyListeners();
    return true;
  }

  /// Removes expired local cache entries. Firebase remains the source of
  /// truth; this only prevents a deleted server alert surviving in cache.
  bool pruneExpired({DateTime? now}) {
    final int previousLength = _liveItems.length;
    _liveItems.removeWhere(
      (AlertItem item) => !item.isWithinRetention(now: now),
    );
    if (_liveItems.length == previousLength) {
      return false;
    }
    _schedulePersist();
    notifyListeners();
    return true;
  }

  /// Rolls back a history entry when the matching local popup could not be
  /// submitted to the operating system.
  void removeEvent(String eventId) {
    final int index = _liveItems.indexWhere(
      (AlertItem item) => item.eventId == eventId,
    );
    if (index == -1) {
      return;
    }
    _liveItems.removeAt(index);
    _schedulePersist();
    notifyListeners();
  }

  Future<void> clear() async {
    await _writeQueue;
    _liveItems.clear();
    _loadFuture = null;
    await _storage?.clearSensorAlerts();
    notifyListeners();
  }

  Future<void> _loadPersistedAlerts() async {
    final LocalStorageService? storage = _storage;
    if (storage == null) {
      return;
    }

    try {
      final List<AlertItem> restored = await _readPersistedAlerts(storage);
      _liveItems
        ..clear()
        ..addAll(
          restored
              .where((AlertItem item) => item.isWithinRetention())
              .take(maxItems),
        );
      notifyListeners();
    } catch (error, stackTrace) {
      _logger.error(
        'Could not restore sensor alerts',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<AlertItem>> _readPersistedAlerts(
    LocalStorageService storage,
  ) async {
    final String? encoded = await storage.getSensorAlertsJson();
    if (encoded == null || encoded.isEmpty) {
      return const <AlertItem>[];
    }
    final Object? decoded = jsonDecode(encoded);
    if (decoded is! List) {
      return const <AlertItem>[];
    }
    final List<AlertItem> restored =
        decoded.map(_decodeAlert).whereType<AlertItem>().toList()..sort(
          (AlertItem first, AlertItem second) =>
              second.timestamp.compareTo(first.timestamp),
        );
    return restored;
  }

  bool _hasSameItems(List<AlertItem> other) {
    if (_liveItems.length != other.length) {
      return false;
    }
    for (int index = 0; index < other.length; index++) {
      if (_identityOf(_liveItems[index]) != _identityOf(other[index])) {
        return false;
      }
    }
    return true;
  }

  String _identityOf(AlertItem item) {
    final String? eventId = item.eventId;
    if (eventId != null && eventId.isNotEmpty) {
      return eventId;
    }
    return <Object>[
      item.timestamp.microsecondsSinceEpoch,
      item.severity.name,
      item.title,
      item.message,
    ].join('\u0000');
  }

  AlertItem? _decodeAlert(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final DateTime? timestamp = DateTime.tryParse('${raw['timestamp'] ?? ''}');
    final AlertSeverity? severity = switch (raw['severity']) {
      'critical' => AlertSeverity.critical,
      'warning' => AlertSeverity.warning,
      _ => null,
    };
    if (timestamp == null || severity == null) {
      return null;
    }

    return AlertItem(
      eventId: '${raw['eventId'] ?? ''}',
      title: '${raw['title'] ?? ''}',
      message: '${raw['message'] ?? ''}',
      recommendedAction: '${raw['recommendedAction'] ?? ''}',
      timestamp: timestamp,
      createdAt: DateTime.tryParse('${raw['createdAt'] ?? ''}'),
      severity: severity,
      icon: '${raw['icon'] ?? ''}',
    );
  }

  void _schedulePersist() {
    final LocalStorageService? storage = _storage;
    if (storage == null) {
      return;
    }
    final String encoded = jsonEncode(
      _liveItems
          .map(
            (AlertItem item) => <String, String>{
              'eventId': item.eventId ?? '',
              'title': item.title,
              'message': item.message,
              'recommendedAction': item.recommendedAction,
              'timestamp': item.timestamp.toIso8601String(),
              'createdAt': item.createdAt?.toIso8601String() ?? '',
              'severity': item.severity.name,
              'icon': item.icon,
            },
          )
          .toList(),
    );

    _writeQueue = _writeQueue.then((_) async {
      try {
        await storage.saveSensorAlertsJson(encoded);
      } catch (error, stackTrace) {
        _logger.error(
          'Could not persist sensor alerts',
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
  }
}
