import 'dart:async';

import 'package:agrisenseaiapp/core/entities/app_user.dart';
import 'package:agrisenseaiapp/core/providers/auth_session_provider.dart';
import 'package:agrisenseaiapp/core/services/realtime_db/sensor_database_service.dart';
import 'package:agrisenseaiapp/features/analytics/data/datasources/analytics_local_datasource.dart';
import 'package:agrisenseaiapp/features/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:agrisenseaiapp/features/analytics/data/models/analytics_dashboard_model.dart';
import 'package:agrisenseaiapp/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_time_range.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthSession extends ChangeNotifier implements AuthSession {
  _FakeAuthSession(this._user);

  AppUser? _user;

  @override
  AppUser? get user => _user;

  @override
  bool get isReady => true;

  void setUser(AppUser? user) {
    _user = user;
    notifyListeners();
  }
}

class _FakeHistoricalSensorDatabase implements HistoricalSensorDatabase {
  final StreamController<List<SensorSample>> history =
      StreamController<List<SensorSample>>.broadcast(sync: true);
  final List<AppUser?> resolvedUsers = <AppUser?>[];
  final List<String> watchedKeys = <String>[];
  final List<DateTime> watchedStarts = <DateTime>[];
  List<SensorSample> samples = const <SensorSample>[];

  @override
  Future<List<SensorSample>> getHistoryFrom(
    DateTime start, {
    required String userKey,
  }) async {
    watchedKeys.add(userKey);
    watchedStarts.add(start);
    return samples;
  }

  @override
  Future<String> resolveHistoryUserKey(AppUser? user) async {
    resolvedUsers.add(user);
    return 'farmer';
  }

  @override
  Stream<List<SensorSample>> watchHistoryFrom(
    DateTime start, {
    required String userKey,
  }) {
    watchedKeys.add(userKey);
    watchedStarts.add(start);
    return history.stream;
  }
}

class _FakeAnalyticsRemoteDataSource implements AnalyticsRemoteDataSource {
  _FakeAnalyticsRemoteDataSource(this.dashboard);

  final AnalyticsDashboardModel dashboard;

  @override
  Future<AnalyticsDashboardModel> getDashboard() async => dashboard;

  @override
  Stream<AnalyticsDashboardModel> watchDashboard() => Stream.value(dashboard);
}

void main() {
  group('Analytics data', () {
    test(
      'local fixture includes light in the combined series and summaries',
      () async {
        final source = AnalyticsLocalDataSourceImpl();
        final dashboard = await source.getDashboard();

        expect(dashboard.periods, hasLength(3));
        for (final period in dashboard.periods) {
          expect(period.metricSeries.map((series) => series.label), <String>[
            'Moisture',
            'Temp',
            'Humidity',
            'Light',
          ]);
          expect(period.averages.map((average) => average.label), <String>[
            'Soil Moisture',
            'Temperature',
            'Humidity',
            'Light Intensity',
          ]);
        }
      },
    );

    test(
      'remote analytics streams history into day week and month views',
      () async {
        final DateTime now = DateTime(2026, 7, 14, 12);
        final _FakeHistoricalSensorDatabase database =
            _FakeHistoricalSensorDatabase();
        final _FakeAuthSession auth = _FakeAuthSession(
          const AppUser(uid: 'uid-1', email: 'farmer@example.com'),
        );
        final AnalyticsRemoteDataSourceImpl source =
            AnalyticsRemoteDataSourceImpl(
              sensorDatabase: database,
              authSessionProvider: auth,
              now: () => now,
            );
        final List<AnalyticsDashboardModel> dashboards =
            <AnalyticsDashboardModel>[];
        final StreamSubscription<AnalyticsDashboardModel> subscription = source
            .watchDashboard()
            .listen(dashboards.add);

        await Future<void>.delayed(Duration.zero);
        expect(database.resolvedUsers.single?.uid, 'uid-1');
        expect(database.watchedKeys, <String>['farmer']);
        expect(database.watchedStarts, <DateTime>[DateTime(2026)]);

        final List<SensorSample> samples = <SensorSample>[
          SensorSample(
            timestamp: now.subtract(const Duration(hours: 1)),
            soilMoisturePercent: 10,
            temperatureC: 20,
            humidityPercent: 30,
            lightLux: 1000,
          ),
          SensorSample(
            timestamp: now.subtract(const Duration(days: 3)),
            soilMoisturePercent: 30,
            temperatureC: 30,
            humidityPercent: 50,
            lightLux: 3000,
          ),
          SensorSample(
            timestamp: DateTime(2026, 3, 15),
            soilMoisturePercent: 50,
            temperatureC: 40,
            humidityPercent: 70,
            lightLux: 5000,
          ),
          SensorSample(
            timestamp: DateTime(2026, 1, 15),
            soilMoisturePercent: 70,
            temperatureC: 35,
            humidityPercent: 60,
            lightLux: 4000,
          ),
        ];
        database.history.add(samples);
        await Future<void>.delayed(Duration.zero);

        expect(dashboards, hasLength(1));
        for (final period in dashboards.single.periods) {
          expect(period.metricSeries, hasLength(4));
          expect(period.averages, hasLength(4));
          expect(period.metricSeries.last.label, 'Light');
          expect(period.averages.last.label, 'Light Intensity');
        }

        final day = dashboards.single.periods.singleWhere(
          (period) => period.range == AnalyticsTimeRange.day,
        );
        final week = dashboards.single.periods.singleWhere(
          (period) => period.range == AnalyticsTimeRange.week,
        );
        final month = dashboards.single.periods.singleWhere(
          (period) => period.range == AnalyticsTimeRange.month,
        );
        expect(day.averages.first.value, '10%');
        expect(week.averages.first.value, '20%');
        expect(month.averages.first.value, '40%');
        expect(month.axisLabels, <String>[
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ]);
        expect(month.yAxisLabels, <String>['100', '75', '50', '25', '0']);
        expect(month.lightYAxisLabels, <String>['8k', '6k', '4k', '2k', '0']);
        expect(month.metricSeries.first.points, hasLength(4));
        expect(month.metricSeries.first.points[0].x, lessThan(1 / 12));
        expect(
          month.metricSeries.first.points[1].x,
          inInclusiveRange(2 / 12, 3 / 12),
        );
        expect(
          month.metricSeries.first.points[2].x,
          inInclusiveRange(6 / 12, 7 / 12),
        );
        expect(
          month.metricSeries.first.points[3].x,
          inInclusiveRange(6 / 12, 7 / 12),
        );
        expect(
          month.metricSeries.first.points
              .map((point) => point.breakBefore)
              .toList(),
          <bool>[false, true, true, false],
          reason: 'Missing months must split the visible line segments.',
        );
        expect(
          month.metricSeries.first.points
              .map((point) => point.y)
              .toSet()
              .length,
          greaterThan(1),
          reason: 'Monthly history with changing values must not be flat.',
        );

        database.history.add(<SensorSample>[...samples, samples.first]);
        await Future<void>.delayed(Duration.zero);
        expect(dashboards, hasLength(2));

        auth.setUser(
          const AppUser(uid: 'uid-2', email: 'second-farmer@example.com'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 1));
        expect(
          database.resolvedUsers.map((AppUser? user) => user?.uid),
          <String?>['uid-1', 'uid-2'],
        );
        expect(database.watchedKeys, <String>['farmer', 'farmer']);

        await subscription.cancel();
        auth.dispose();
        await database.history.close();
      },
    );

    test('repository streams its local fallback dashboard', () async {
      final repo = AnalyticsRepositoryImpl(
        localDataSource: AnalyticsLocalDataSourceImpl(),
      );

      final dashboard = await repo.watchDashboard().first;

      expect(dashboard.periods, hasLength(3));
    });

    test('repository delegates one-shot and live reads to remote', () async {
      final local = AnalyticsLocalDataSourceImpl();
      final remoteDashboard = await local.getDashboard();
      final repo = AnalyticsRepositoryImpl(
        localDataSource: local,
        remoteDataSource: _FakeAnalyticsRemoteDataSource(remoteDashboard),
      );

      expect(await repo.getDashboard(), same(remoteDashboard));
      expect(await repo.watchDashboard().first, same(remoteDashboard));
    });
  });
}
