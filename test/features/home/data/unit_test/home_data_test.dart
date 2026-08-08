import 'dart:async';

import 'package:agrisenseaiapp/core/constants/sensor_db_constants.dart';
import 'package:agrisenseaiapp/core/entities/app_user.dart';
import 'package:agrisenseaiapp/core/providers/auth_session_provider.dart';
import 'package:agrisenseaiapp/core/services/realtime_db/sensor_database_service.dart';
import 'package:agrisenseaiapp/core/services/local_storage/local_storage_service.dart';
import 'package:agrisenseaiapp/core/services/settings/threshold_settings_service.dart';
import 'package:agrisenseaiapp/features/home/data/datasources/home_local_datasource.dart';
import 'package:agrisenseaiapp/features/home/data/datasources/home_remote_datasource.dart';
import 'package:agrisenseaiapp/features/home/data/models/home_dashboard_model.dart';
import 'package:agrisenseaiapp/features/home/data/repositories/home_repository_impl.dart';
import 'package:agrisenseaiapp/features/home/domain/entities/home_dashboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_local_storage_service.dart';

class _FakeAuthSession extends ChangeNotifier implements AuthSession {
  _FakeAuthSession(this._user, {bool isReady = true}) : _isReady = isReady;

  AppUser? _user;
  bool _isReady;

  @override
  AppUser? get user => _user;
  @override
  bool get isReady => _isReady;

  void setUser(AppUser? value) {
    _user = value;
    _isReady = true;
    notifyListeners();
  }

  void notifyUnchanged() => notifyListeners();
}

class _FakeLiveSensorDatabase implements LiveSensorDatabase {
  final Map<String, StreamController<FieldCurrentReading?>> currentStreams =
      <String, StreamController<FieldCurrentReading?>>{};
  final Map<String, StreamController<bool>> pumpStreams =
      <String, StreamController<bool>>{};
  final List<AppUser?> resolvedUsers = <AppUser?>[];
  final List<String> watchedUserKeys = <String>[];
  final List<String> readUserKeys = <String>[];
  final List<String> watchedPumpUserUids = <String>[];
  final List<({String userUid, bool isOn})> pumpWrites =
      <({String userUid, bool isOn})>[];
  final Map<String, FieldCurrentReading?> initialReadings =
      <String, FieldCurrentReading?>{};
  Completer<FieldCurrentReading?>? pendingInitialRead;
  Object? initialReadError;

  StreamController<FieldCurrentReading?> currentFor(String key) {
    return currentStreams.putIfAbsent(
      key,
      () => StreamController<FieldCurrentReading?>.broadcast(sync: true),
    );
  }

  StreamController<bool> pumpFor(String userUid) {
    return pumpStreams.putIfAbsent(
      userUid,
      () => StreamController<bool>.broadcast(sync: true),
    );
  }

  @override
  Future<FieldCurrentReading?> getCurrent({required String userKey}) async {
    readUserKeys.add(userKey);
    final Object? error = initialReadError;
    if (error != null) {
      throw error;
    }
    final Completer<FieldCurrentReading?>? pending = pendingInitialRead;
    if (pending != null) {
      return pending.future;
    }
    return initialReadings[userKey];
  }

  @override
  Future<String> resolveUserKey(AppUser? user) async {
    resolvedUsers.add(user);
    return SensorDbConstants.userKeyCandidates(
      uid: user!.uid,
      email: user.email,
      phoneNumber: user.phoneNumber,
    ).first;
  }

  @override
  Future<void> setPumpStatus({
    required String userUid,
    required bool isOn,
  }) async {
    pumpWrites.add((userUid: userUid, isOn: isOn));
    pumpFor(userUid).add(isOn);
  }

  @override
  Stream<FieldCurrentReading?> watchCurrent({required String userKey}) {
    watchedUserKeys.add(userKey);
    return currentFor(userKey).stream;
  }

  @override
  Stream<bool> watchPumpStatus({required String userUid}) {
    watchedPumpUserUids.add(userUid);
    return pumpFor(userUid).stream;
  }

  Future<void> close() async {
    for (final StreamController<bool> stream in pumpStreams.values) {
      await stream.close();
    }
    for (final StreamController<FieldCurrentReading?> stream
        in currentStreams.values) {
      await stream.close();
    }
  }
}

void main() {
  test('home repository returns dashboard', () async {
    final repo = HomeRepositoryImpl(localDataSource: HomeLocalDataSourceImpl());
    final dash = await repo.getDashboard();
    expect(dash.sensors, isNotEmpty);
  });

  test(
    'remote dashboard follows the signed-in user current node live',
    () async {
      final _FakeLiveSensorDatabase database = _FakeLiveSensorDatabase();
      final _FakeAuthSession auth = _FakeAuthSession(
        const AppUser(uid: 'uid-a', email: 'ZohaibHassanPK2@gmail.com'),
      );
      final HomeRemoteDataSourceImpl source = HomeRemoteDataSourceImpl(
        sensorDatabase: database,
        authSessionProvider: auth,
        thresholdSettings: ThresholdSettingsService(
          storage: FakeLocalStorageService(),
        ),
      );
      final List<HomeDashboardModel> dashboards = <HomeDashboardModel>[];
      final StreamSubscription<HomeDashboardModel> subscription = source
          .watchDashboard()
          .listen(dashboards.add);

      await Future<void>.delayed(Duration.zero);
      expect(database.watchedUserKeys, <String>['zohaibhassanpk2']);
      expect(database.readUserKeys, <String>['zohaibhassanpk2']);
      expect(database.watchedPumpUserUids, <String>['uid-a']);

      database
          .currentFor('zohaibhassanpk2')
          .add(
            FieldCurrentReading(
              deviceOnline: true,
              soilMoisturePercent: 44.2,
              temperatureC: 27.5,
              humidityPercent: 63,
              lightLux: 51000,
              updatedAt: DateTime.now(),
            ),
          );
      await Future<void>.delayed(Duration.zero);
      expect(dashboards.last.sensors.map((sensor) => sensor.value), <String>[
        '44.2',
        '27.5',
        '63',
        '51000',
      ]);

      database
          .currentFor('zohaibhassanpk2')
          .add(
            FieldCurrentReading(
              deviceOnline: true,
              soilMoisturePercent: 52,
              temperatureC: 29,
              humidityPercent: 70,
              lightLux: 62000,
              updatedAt: DateTime.now(),
            ),
          );
      await Future<void>.delayed(Duration.zero);
      expect(dashboards.last.sensors.first.value, '52');

      await subscription.cancel();
      auth.dispose();
      await database.close();
    },
  );

  test(
    'remote dashboard rebinds when the authenticated user changes',
    () async {
      final _FakeLiveSensorDatabase database = _FakeLiveSensorDatabase();
      final _FakeAuthSession auth = _FakeAuthSession(
        const AppUser(uid: 'uid-a', email: 'first@example.com'),
      );
      final HomeRemoteDataSourceImpl source = HomeRemoteDataSourceImpl(
        sensorDatabase: database,
        authSessionProvider: auth,
        thresholdSettings: ThresholdSettingsService(
          storage: FakeLocalStorageService(),
        ),
      );
      final StreamSubscription<HomeDashboardModel> subscription = source
          .watchDashboard()
          .listen((_) {});

      await Future<void>.delayed(Duration.zero);
      auth.setUser(const AppUser(uid: 'uid-b', email: 'second@example.com'));
      await Future<void>.delayed(Duration.zero);

      expect(database.watchedUserKeys, <String>['first', 'second']);
      expect(database.watchedPumpUserUids, <String>['uid-a', 'uid-b']);
      expect(database.resolvedUsers.last?.uid, 'uid-b');

      await subscription.cancel();
      auth.dispose();
      await database.close();
    },
  );

  test(
    'unchanged auth notifications do not create duplicate listeners',
    () async {
      final _FakeLiveSensorDatabase database = _FakeLiveSensorDatabase();
      final _FakeAuthSession auth = _FakeAuthSession(
        const AppUser(uid: 'uid-a', email: 'farmer@example.com'),
      );
      final HomeRemoteDataSourceImpl source = HomeRemoteDataSourceImpl(
        sensorDatabase: database,
        authSessionProvider: auth,
        thresholdSettings: ThresholdSettingsService(
          storage: FakeLocalStorageService(),
        ),
      );
      final StreamSubscription<HomeDashboardModel> subscription = source
          .watchDashboard()
          .listen((_) {});

      await Future<void>.delayed(Duration.zero);
      auth.notifyUnchanged();
      await Future<void>.delayed(Duration.zero);

      expect(database.readUserKeys, <String>['farmer']);
      expect(database.watchedUserKeys, <String>['farmer']);
      expect(database.watchedPumpUserUids, <String>['uid-a']);

      await subscription.cancel();
      auth.dispose();
      await database.close();
    },
  );

  test('pump writes are echoed by the Firebase pump stream', () async {
    final _FakeLiveSensorDatabase database = _FakeLiveSensorDatabase();
    final _FakeAuthSession auth = _FakeAuthSession(
      const AppUser(uid: 'uid-a', email: 'farmer@example.com'),
    );
    final HomeRemoteDataSourceImpl source = HomeRemoteDataSourceImpl(
      sensorDatabase: database,
      authSessionProvider: auth,
      thresholdSettings: ThresholdSettingsService(
        storage: FakeLocalStorageService(),
      ),
    );
    final List<HomeDashboardModel> dashboards = <HomeDashboardModel>[];
    final StreamSubscription<HomeDashboardModel> subscription = source
        .watchDashboard()
        .listen(dashboards.add);

    await Future<void>.delayed(Duration.zero);
    database
        .currentFor('farmer')
        .add(
          FieldCurrentReading(deviceOnline: true, updatedAt: DateTime.now()),
        );
    await Future<void>.delayed(Duration.zero);
    await source.setPumpStatus(true);
    await Future<void>.delayed(Duration.zero);

    expect(database.pumpWrites, <({String userUid, bool isOn})>[
      (userUid: 'uid-a', isOn: true),
    ]);
    expect(dashboards.last.pumpOn, isTrue);

    database.pumpFor('uid-a').add(false);
    await Future<void>.delayed(Duration.zero);
    expect(dashboards.last.pumpOn, isFalse);

    await subscription.cancel();
    auth.dispose();
    await database.close();
  });

  test('waits for authentication before reading a user path', () async {
    final _FakeLiveSensorDatabase database = _FakeLiveSensorDatabase();
    final _FakeAuthSession auth = _FakeAuthSession(null, isReady: false);
    final HomeRemoteDataSourceImpl source = HomeRemoteDataSourceImpl(
      sensorDatabase: database,
      authSessionProvider: auth,
      thresholdSettings: ThresholdSettingsService(
        storage: FakeLocalStorageService(),
      ),
    );
    final List<HomeDashboardModel> dashboards = <HomeDashboardModel>[];
    final StreamSubscription<HomeDashboardModel> subscription = source
        .watchDashboard()
        .listen(dashboards.add);

    await Future<void>.delayed(Duration.zero);
    expect(dashboards.last.deviceStatus, DeviceStatus.loading);
    expect(dashboards.last.connectionStatus, 'Checking status...');
    expect(database.readUserKeys, isEmpty);
    expect(database.watchedUserKeys, isEmpty);

    auth.setUser(const AppUser(uid: 'uid-a', email: 'farmer@example.com'));
    await Future<void>.delayed(Duration.zero);
    expect(database.readUserKeys, <String>['farmer']);
    expect(database.watchedUserKeys, <String>['farmer']);

    await subscription.cancel();
    auth.dispose();
    await database.close();
  });

  test('one-time read establishes Online before live updates', () async {
    final _FakeLiveSensorDatabase database = _FakeLiveSensorDatabase();
    database.initialReadings['farmer'] = FieldCurrentReading(
      deviceOnline: true,
      updatedAt: DateTime.now(),
    );
    final _FakeAuthSession auth = _FakeAuthSession(
      const AppUser(uid: 'uid-a', email: 'farmer@example.com'),
    );
    final HomeRemoteDataSourceImpl source = HomeRemoteDataSourceImpl(
      sensorDatabase: database,
      authSessionProvider: auth,
      thresholdSettings: ThresholdSettingsService(
        storage: FakeLocalStorageService(),
      ),
    );
    final List<HomeDashboardModel> dashboards = <HomeDashboardModel>[];
    final StreamSubscription<HomeDashboardModel> subscription = source
        .watchDashboard()
        .listen(dashboards.add);

    await Future<void>.delayed(Duration.zero);
    expect(
      dashboards.map((HomeDashboardModel item) => item.deviceStatus),
      containsAllInOrder(<DeviceStatus>[
        DeviceStatus.loading,
        DeviceStatus.online,
      ]),
    );
    expect(database.readUserKeys, <String>['farmer']);
    expect(database.watchedUserKeys, <String>['farmer']);

    await subscription.cancel();
    auth.dispose();
    await database.close();
  });

  test('null initial and live snapshots never become Offline', () async {
    final _FakeLiveSensorDatabase database = _FakeLiveSensorDatabase();
    final _FakeAuthSession auth = _FakeAuthSession(
      const AppUser(uid: 'uid-a', email: 'farmer@example.com'),
    );
    final HomeRemoteDataSourceImpl source = HomeRemoteDataSourceImpl(
      sensorDatabase: database,
      authSessionProvider: auth,
      thresholdSettings: ThresholdSettingsService(
        storage: FakeLocalStorageService(),
      ),
    );
    final List<HomeDashboardModel> dashboards = <HomeDashboardModel>[];
    final StreamSubscription<HomeDashboardModel> subscription = source
        .watchDashboard()
        .listen(dashboards.add);

    await Future<void>.delayed(Duration.zero);
    database.currentFor('farmer').add(null);
    await Future<void>.delayed(Duration.zero);
    expect(dashboards, isNotEmpty);
    expect(
      dashboards.map((HomeDashboardModel item) => item.deviceStatus),
      isNot(contains(DeviceStatus.offline)),
    );
    expect(dashboards.last.connectionStatus, 'Checking status...');

    await subscription.cancel();
    auth.dispose();
    await database.close();
  });

  test('Firebase read errors show Unable to check status', () async {
    final _FakeLiveSensorDatabase database = _FakeLiveSensorDatabase()
      ..initialReadError = StateError('network unavailable');
    final _FakeAuthSession auth = _FakeAuthSession(
      const AppUser(uid: 'uid-a', email: 'farmer@example.com'),
    );
    final HomeRemoteDataSourceImpl source = HomeRemoteDataSourceImpl(
      sensorDatabase: database,
      authSessionProvider: auth,
      thresholdSettings: ThresholdSettingsService(
        storage: FakeLocalStorageService(),
      ),
    );
    final List<HomeDashboardModel> dashboards = <HomeDashboardModel>[];
    final StreamSubscription<HomeDashboardModel> subscription = source
        .watchDashboard()
        .listen(dashboards.add);

    await Future<void>.delayed(Duration.zero);
    expect(dashboards.last.deviceStatus, DeviceStatus.error);
    expect(dashboards.last.connectionStatus, 'Unable to check status');

    await subscription.cancel();
    auth.dispose();
    await database.close();
  });

  test(
    'fresh cached status is restored while the one-time read is pending',
    () async {
      final _FakeLiveSensorDatabase database = _FakeLiveSensorDatabase()
        ..pendingInitialRead = Completer<FieldCurrentReading?>();
      final _FakeAuthSession auth = _FakeAuthSession(
        const AppUser(uid: 'uid-a', email: 'farmer@example.com'),
      );
      final FakeLocalStorageService storage = FakeLocalStorageService();
      storage.sensorStatuses['uid-a'] = CachedSensorStatus(
        isOnline: true,
        updatedAt: DateTime.now(),
      );
      final HomeRemoteDataSourceImpl source = HomeRemoteDataSourceImpl(
        sensorDatabase: database,
        authSessionProvider: auth,
        thresholdSettings: ThresholdSettingsService(storage: storage),
        storage: storage,
      );
      final List<HomeDashboardModel> dashboards = <HomeDashboardModel>[];
      final StreamSubscription<HomeDashboardModel> subscription = source
          .watchDashboard()
          .listen(dashboards.add);

      await Future<void>.delayed(Duration.zero);
      expect(dashboards.last.deviceStatus, DeviceStatus.online);
      expect(database.watchedUserKeys, isEmpty);

      database.pendingInitialRead!.complete(null);
      await Future<void>.delayed(Duration.zero);
      expect(database.watchedUserKeys, <String>['farmer']);
      expect(dashboards.last.deviceStatus, DeviceStatus.online);

      await subscription.cancel();
      auth.dispose();
      await database.close();
    },
  );

  test(
    'stale cache waits for the one-time read instead of flickering Offline',
    () async {
      final _FakeLiveSensorDatabase database = _FakeLiveSensorDatabase();
      database.initialReadings['farmer'] = FieldCurrentReading(
        deviceOnline: true,
        updatedAt: DateTime.now(),
      );
      final _FakeAuthSession auth = _FakeAuthSession(
        const AppUser(uid: 'uid-a', email: 'farmer@example.com'),
      );
      final FakeLocalStorageService storage = FakeLocalStorageService();
      storage.sensorStatuses['uid-a'] = CachedSensorStatus(
        isOnline: false,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final HomeRemoteDataSourceImpl source = HomeRemoteDataSourceImpl(
        sensorDatabase: database,
        authSessionProvider: auth,
        thresholdSettings: ThresholdSettingsService(storage: storage),
        storage: storage,
      );
      final List<HomeDashboardModel> dashboards = <HomeDashboardModel>[];
      final StreamSubscription<HomeDashboardModel> subscription = source
          .watchDashboard()
          .listen(dashboards.add);

      await Future<void>.delayed(Duration.zero);
      expect(
        dashboards.map((HomeDashboardModel item) => item.deviceStatus),
        isNot(contains(DeviceStatus.offline)),
      );
      expect(dashboards.last.deviceStatus, DeviceStatus.online);

      await subscription.cancel();
      auth.dispose();
      await database.close();
    },
  );
}
