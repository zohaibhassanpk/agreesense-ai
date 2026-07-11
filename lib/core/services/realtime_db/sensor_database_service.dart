import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../constants/sensor_db_constants.dart';
import '../logger/logger_service.dart';

/// A point-in-time reading from the field's `current` node.
class FieldCurrentReading {
  const FieldCurrentReading({
    required this.deviceOnline,
    this.soilMoisturePercent,
    this.temperatureC,
    this.humidityPercent,
    this.lightLux,
    this.updatedAt,
  });

  final bool deviceOnline;
  final double? soilMoisturePercent;
  final double? temperatureC;
  final double? humidityPercent;
  final double? lightLux;
  final DateTime? updatedAt;
}

/// One historical sample from the field's `history/{epochMs}` node.
class SensorSample {
  const SensorSample({
    required this.timestamp,
    this.soilMoisturePercent,
    this.temperatureC,
    this.humidityPercent,
    this.lightLux,
  });

  final DateTime timestamp;
  final double? soilMoisturePercent;
  final double? temperatureC;
  final double? humidityPercent;
  final double? lightLux;
}

/// Thin wrapper around the Firebase Realtime Database that exposes typed
/// reads/streams for the sensor data written by the hardware node.
class SensorDatabaseService {
  SensorDatabaseService({FirebaseDatabase? database})
    : _database =
          database ??
          FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: SensorDbConstants.databaseUrl,
          ) {
    // On Android, a failure here (e.g. the native instance was already used
    // before a hot restart) is delivered on an unawaited platform-channel
    // Future rather than thrown synchronously, so a plain try/catch cannot
    // see it — run inside a guarded zone instead.
    runZonedGuarded(
      () => _database.setPersistenceEnabled(true),
      (error, stackTrace) => _logger.debug(
        'setPersistenceEnabled failed (expected after hot restart)',
        data: error,
      ),
    );
  }

  final FirebaseDatabase _database;
  final LoggerService _logger = LoggerService(
    className: 'SensorDatabaseService',
  );

  DatabaseReference get _fieldRef =>
      _database.ref(SensorDbConstants.fieldPath());

  DatabaseReference get _pumpRef =>
      _database.ref(SensorDbConstants.pumpStatusPath);

  /// Live stream of the field's `current` node. Emits null when the node is
  /// missing or malformed.
  Stream<FieldCurrentReading?> watchCurrent() {
    return _fieldRef
        .child('current')
        .onValue
        .map((DatabaseEvent event) => _parseCurrent(event.snapshot.value));
  }

  /// Live stream of the global pump control flag.
  Stream<bool> watchPumpStatus() {
    return _pumpRef.onValue.map(
      (DatabaseEvent event) => event.snapshot.value == true,
    );
  }

  /// Writes the pump control flag the ESP32 polls.
  Future<void> setPumpStatus(bool isOn) async {
    try {
      await _pumpRef.set(isOn);
      _logger.info('Pump status set to $isOn');
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to write pump status',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Returns history samples taken at or after [start], sorted by timestamp.
  ///
  /// History node keys are epoch-ms strings (13 digits until year 2286), so
  /// ordering by key prunes server-side without needing a `.indexOn` rule.
  /// Falls back to a full read only on a genuine failure (e.g. offline with
  /// an empty local cache, or a rules denial) — an unindexed `orderByChild`
  /// query would silently download the whole node instead of throwing, so
  /// that approach is intentionally avoided here.
  Future<List<SensorSample>> getHistoryFrom(DateTime start) async {
    final int startMs = start.millisecondsSinceEpoch;
    DataSnapshot snapshot;

    try {
      snapshot = await _fieldRef
          .child('history')
          .orderByKey()
          .startAt(startMs.toString())
          .get();
    } catch (error) {
      _logger.warning(
        'Range query on history failed, falling back to full read',
        data: error,
      );
      try {
        snapshot = await _fieldRef.child('history').get();
      } catch (fallbackError, fallbackStackTrace) {
        _logger.error(
          'Failed to read sensor history',
          error: fallbackError,
          stackTrace: fallbackStackTrace,
        );
        rethrow;
      }
    }

    final List<SensorSample> samples = _parseHistory(snapshot.value)
        .where(
          (SensorSample sample) =>
              sample.timestamp.millisecondsSinceEpoch >= startMs,
        )
        .toList();
    samples.sort(
      (SensorSample a, SensorSample b) => a.timestamp.compareTo(b.timestamp),
    );
    return samples;
  }

  FieldCurrentReading? _parseCurrent(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    return FieldCurrentReading(
      deviceOnline: raw['deviceOnline'] == true,
      soilMoisturePercent: _toDouble(raw['soilMoisturePercent']),
      temperatureC: _toDouble(raw['temperatureC']),
      humidityPercent: _toDouble(raw['humidityPercent']),
      lightLux: _toDouble(raw['lightLux']),
      updatedAt: _toDateTime(raw['updatedAt']),
    );
  }

  List<SensorSample> _parseHistory(Object? raw) {
    final List<SensorSample> samples = [];

    if (raw is Map) {
      raw.forEach((Object? key, Object? value) {
        final SensorSample? sample = _parseSample(key, value);
        if (sample != null) {
          samples.add(sample);
        }
      });
    } else if (raw is List) {
      // The RTDB coerces maps with dense integer-like keys into lists.
      for (int index = 0; index < raw.length; index++) {
        final SensorSample? sample = _parseSample(index, raw[index]);
        if (sample != null) {
          samples.add(sample);
        }
      }
    }

    return samples;
  }

  SensorSample? _parseSample(Object? key, Object? value) {
    if (value is! Map) {
      return null;
    }

    final DateTime? timestamp =
        _toDateTime(value['timestamp']) ?? _toDateTime(num.tryParse('$key'));
    if (timestamp == null) {
      return null;
    }

    return SensorSample(
      timestamp: timestamp,
      soilMoisturePercent: _toDouble(value['soilMoisturePercent']),
      temperatureC: _toDouble(value['temperatureC']),
      humidityPercent: _toDouble(value['humidityPercent']),
      lightLux: _toDouble(value['lightLux']),
    );
  }

  static double? _toDouble(Object? value) =>
      value is num ? value.toDouble() : null;

  static DateTime? _toDateTime(Object? value) {
    if (value is num && value > 0) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }
}
