import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../constants/sensor_db_constants.dart';
import '../../entities/app_user.dart';
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

/// Live sensor operations consumed by the Home feature.
abstract interface class LiveSensorDatabase {
  Future<String> resolveUserKey(AppUser? user);
  Future<FieldCurrentReading?> getCurrent({required String userKey});
  Stream<FieldCurrentReading?> watchCurrent({required String userKey});
  Stream<bool> watchPumpStatus({required String userUid});
  Future<void> setPumpStatus({required String userUid, required bool isOn});
}

/// Historical sensor operations consumed by the Analytics feature.
abstract interface class HistoricalSensorDatabase {
  Future<String> resolveHistoryUserKey(AppUser? user);
  Future<List<SensorSample>> getHistoryFrom(
    DateTime start, {
    required String userKey,
  });
  Stream<List<SensorSample>> watchHistoryFrom(
    DateTime start, {
    required String userKey,
  });
}

/// Thin wrapper around the Firebase Realtime Database that exposes typed
/// reads/streams for the sensor data written by the hardware node.
class SensorDatabaseService
    implements LiveSensorDatabase, HistoricalSensorDatabase {
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

  DatabaseReference _fieldRef(String userKey) =>
      _database.ref(SensorDbConstants.fieldPath(userKey: userKey));

  DatabaseReference _pumpRef(String userUid) =>
      _database.ref(SensorDbConstants.pumpStatusPath(userUid: userUid));

  /// Live stream of the field's `current` node. Emits null when the node is
  /// missing or malformed.
  @override
  Stream<FieldCurrentReading?> watchCurrent({required String userKey}) {
    _database.goOnline();
    return _fieldRef(userKey)
        .child(SensorDbConstants.currentNode)
        .onValue
        .map((DatabaseEvent event) => _parseCurrent(event.snapshot.value));
  }

  /// Reads the latest value once. Used by the Android background worker so it
  /// does not keep a Realtime Database listener alive after the task exits.
  @override
  Future<FieldCurrentReading?> getCurrent({required String userKey}) async {
    _database.goOnline();
    final DataSnapshot snapshot = await _fieldRef(
      userKey,
    ).child(SensorDbConstants.currentNode).get();
    return _parseCurrent(snapshot.value);
  }

  /// Resolves the authenticated user's linked field key when one exists.
  ///
  /// The checked-in RTDB schema keys the hardware field by the Google email's
  /// local part. UID, sanitized full-email, and phone keys are also checked so
  /// already-provisioned accounts using those schemes continue to work.
  ///
  /// This deliberately does not fall back to another account's field. If no
  /// candidate currently exists, the stream is attached to the primary
  /// identity-derived path so it will receive data when that field is created.
  @override
  Future<String> resolveUserKey(AppUser? user) {
    return _resolveUserKeyForNode(
      user,
      nodeName: SensorDbConstants.currentNode,
    );
  }

  /// Resolves an account using only its `history` node. Analytics uses this
  /// method so it never needs to read or probe `current`.
  @override
  Future<String> resolveHistoryUserKey(AppUser? user) {
    return _resolveUserKeyForNode(
      user,
      nodeName: SensorDbConstants.historyNode,
    );
  }

  Future<String> _resolveUserKeyForNode(
    AppUser? user, {
    required String nodeName,
  }) async {
    if (user == null) {
      throw StateError('An authenticated user is required for sensor data.');
    }

    final List<String> candidates = SensorDbConstants.userKeyCandidates(
      uid: user.uid,
      email: user.email,
      phoneNumber: user.phoneNumber,
    );
    if (candidates.isEmpty) {
      throw StateError('The authenticated user has no usable database key.');
    }

    for (final String key in candidates) {
      try {
        if (await _hasNodeData(userKey: key, nodeName: nodeName)) {
          return key;
        }
      } catch (error) {
        _logger.debug(
          'Could not resolve sensor data for user key candidate',
          data: error,
        );
      }
    }

    _logger.warning(
      'No existing $nodeName node matched the authenticated user; '
      'watching ${candidates.first}',
    );
    return candidates.first;
  }

  Future<bool> _hasNodeData({
    required String userKey,
    required String nodeName,
  }) async {
    Query query = _fieldRef(userKey).child(nodeName);
    if (nodeName == SensorDbConstants.historyNode) {
      query = query.limitToLast(1);
    }
    final DataSnapshot snapshot = await query.get();
    return snapshot.exists && snapshot.value != null;
  }

  /// Live stream of the authenticated user's pump control flag.
  @override
  Stream<bool> watchPumpStatus({required String userUid}) {
    return _pumpRef(userUid).onValue.map(
      (DatabaseEvent event) => _toOptionalBool(event.snapshot.value) ?? false,
    );
  }

  /// Writes the authenticated user's pump control flag.
  @override
  Future<void> setPumpStatus({
    required String userUid,
    required bool isOn,
  }) async {
    try {
      await _pumpRef(userUid).set(isOn);
      _logger.info('Pump status for user $userUid set to $isOn');
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
  @override
  Future<List<SensorSample>> getHistoryFrom(
    DateTime start, {
    required String userKey,
  }) async {
    final int startMs = start.millisecondsSinceEpoch;
    DataSnapshot snapshot;

    try {
      snapshot = await _fieldRef(userKey)
          .child(SensorDbConstants.historyNode)
          .orderByKey()
          .startAt(startMs.toString())
          .get();
    } catch (error) {
      _logger.warning(
        'Range query on history failed, falling back to full read',
        data: error,
      );
      try {
        snapshot = await _fieldRef(
          userKey,
        ).child(SensorDbConstants.historyNode).get();
      } catch (fallbackError, fallbackStackTrace) {
        _logger.warning('Failed to read sensor history', data: fallbackError);
        _logger.debug(
          'Sensor history read stack trace',
          data: fallbackStackTrace,
        );
        return const [];
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

  /// Streams history samples at or after [start], sorted by timestamp.
  @override
  Stream<List<SensorSample>> watchHistoryFrom(
    DateTime start, {
    required String userKey,
  }) {
    final int startMs = start.millisecondsSinceEpoch;

    return _fieldRef(userKey)
        .child(SensorDbConstants.historyNode)
        .orderByKey()
        .startAt(startMs.toString())
        .onValue
        .map((DatabaseEvent event) => _parseHistory(event.snapshot.value))
        .map((List<SensorSample> samples) {
          final List<SensorSample> filtered = samples
              .where(
                (SensorSample sample) =>
                    sample.timestamp.millisecondsSinceEpoch >= startMs,
              )
              .toList();
          filtered.sort(
            (SensorSample a, SensorSample b) =>
                a.timestamp.compareTo(b.timestamp),
          );
          return filtered;
        });
  }

  FieldCurrentReading? _parseCurrent(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final double? soilMoisture = _firstDouble(raw, const [
      'soilMoisturePercent',
      'soilMoisture',
      'soil_moisture',
      'SoilMoisture',
      'moisturePercent',
      'moisture',
      'Moisture',
    ]);
    final double? temperature = _firstDouble(raw, const [
      'temperatureC',
      'temperature',
      'Temperature',
      'tempC',
      'temp',
      'Temp',
    ]);
    final double? humidity = _firstDouble(raw, const [
      'humidityPercent',
      'humidity',
      'Humidity',
      'humidity_percent',
    ]);
    final double? light = _firstDouble(raw, const [
      'lightLux',
      'lightIntensity',
      'LightIntensity',
      'light_intensity',
      'lux',
      'Lux',
      'light',
      'Light',
    ]);

    return FieldCurrentReading(
      deviceOnline: _firstBool(raw, const [
        'deviceOnline',
        'online',
        'isOnline',
      ]),
      soilMoisturePercent: soilMoisture,
      temperatureC: temperature,
      humidityPercent: humidity,
      lightLux: light,
      updatedAt: _firstDateTime(raw, const [
        'updatedAt',
        'timestamp',
        'Timestamp',
        'time',
        'Time',
        'ts',
      ]),
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
        _firstDateTime(value, const [
          'timestamp',
          'updatedAt',
          'Timestamp',
          'time',
          'Time',
          'ts',
        ]) ??
        _toDateTime(num.tryParse('$key'));
    if (timestamp == null) {
      return null;
    }

    return SensorSample(
      timestamp: timestamp,
      soilMoisturePercent: _firstDouble(value, const [
        'soilMoisturePercent',
        'soilMoisture',
        'soil_moisture',
        'SoilMoisture',
        'moisturePercent',
        'moisture',
        'Moisture',
      ]),
      temperatureC: _firstDouble(value, const [
        'temperatureC',
        'temperature',
        'Temperature',
        'tempC',
        'temp',
        'Temp',
      ]),
      humidityPercent: _firstDouble(value, const [
        'humidityPercent',
        'humidity',
        'Humidity',
        'humidity_percent',
      ]),
      lightLux: _firstDouble(value, const [
        'lightLux',
        'lightIntensity',
        'LightIntensity',
        'light_intensity',
        'lux',
        'Lux',
        'light',
        'Light',
      ]),
    );
  }

  static double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  static double? _firstDouble(Map raw, List<String> keys) {
    for (final String key in keys) {
      final double? value = _toDouble(raw[key]);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static bool _firstBool(Map raw, List<String> keys) {
    for (final String key in keys) {
      final bool? value = _toOptionalBool(raw[key]);
      if (value != null) {
        return value;
      }
    }
    return false;
  }

  static bool? _toOptionalBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      if (normalized == 'true' ||
          normalized == '1' ||
          normalized == 'on' ||
          normalized == 'online') {
        return true;
      }
      if (normalized == 'false' ||
          normalized == '0' ||
          normalized == 'off' ||
          normalized == 'offline') {
        return false;
      }
    }
    return null;
  }

  static DateTime? _firstDateTime(Map raw, List<String> keys) {
    for (final String key in keys) {
      final DateTime? value = _toDateTime(raw[key]);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static DateTime? _toDateTime(Object? value) {
    if (value is num && value > 0) {
      return DateTime.fromMillisecondsSinceEpoch(
        SensorDbConstants.normalizeEpochMilliseconds(value),
      );
    }
    if (value is String) {
      final num? numeric = num.tryParse(value.trim());
      if (numeric != null && numeric > 0) {
        return DateTime.fromMillisecondsSinceEpoch(
          SensorDbConstants.normalizeEpochMilliseconds(numeric),
        );
      }
      return DateTime.tryParse(value);
    }
    return null;
  }
}
