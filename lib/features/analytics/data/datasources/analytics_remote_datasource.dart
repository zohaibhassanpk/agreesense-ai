import 'dart:async';
import 'dart:math' as math;

import '../../../../core/constants/app_assets.dart';
import '../../../../core/entities/app_user.dart';
import '../../../../core/providers/auth_session_provider.dart';
import '../../../../core/services/realtime_db/sensor_database_service.dart';
import '../../domain/entities/analytics_time_range.dart';
import '../models/analytics_chart_point_model.dart';
import '../models/analytics_dashboard_model.dart';
import '../models/analytics_metric_average_model.dart';
import '../models/analytics_metric_series_model.dart';
import '../models/analytics_period_data_model.dart';

abstract class AnalyticsRemoteDataSource {
  Future<AnalyticsDashboardModel> getDashboard();
  Stream<AnalyticsDashboardModel> watchDashboard();
}

/// Builds the analytics dashboard from the field's `history` samples.
///
/// One calendar-year query feeds all three ranges. Day and Week use rolling
/// time buckets, while Month plots every available History sample at its real
/// January-through-December position. Temperature, humidity, and moisture use
/// a shared 0..100 axis; light uses a separately labelled lux axis.
class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSourceImpl({
    required this.sensorDatabase,
    required this.authSessionProvider,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final HistoricalSensorDatabase sensorDatabase;
  final AuthSession authSessionProvider;
  final DateTime Function() _now;

  static const Duration _dayWindow = Duration(hours: 24);
  static const Duration _weekWindow = Duration(days: 7);
  static const Duration _refreshInterval = Duration(minutes: 1);

  static const double _chartTopPadding = 0;
  static const double _chartBottomPadding = 1;
  static const double _primaryAxisMaximum = 100;
  static const List<String> _primaryYAxisLabels = <String>[
    '100',
    '75',
    '50',
    '25',
    '0',
  ];

  static final List<_MetricSpec> _metrics = [
    _MetricSpec(
      seriesLabel: 'Moisture',
      averageLabel: 'Soil Moisture',
      icon: AppAssets.drop,
      colorKey: 'blue',
      unit: '%',
      valueOf: (SensorSample sample) => sample.soilMoisturePercent,
    ),
    _MetricSpec(
      seriesLabel: 'Temp',
      averageLabel: 'Temperature',
      icon: AppAssets.temprature,
      colorKey: 'red',
      unit: '°C',
      valueOf: (SensorSample sample) => sample.temperatureC,
    ),
    _MetricSpec(
      seriesLabel: 'Humidity',
      averageLabel: 'Humidity',
      icon: AppAssets.cloud,
      colorKey: 'green',
      unit: '%',
      valueOf: (SensorSample sample) => sample.humidityPercent,
    ),
    _MetricSpec(
      seriesLabel: 'Light',
      averageLabel: 'Light Intensity',
      icon: AppAssets.sun,
      colorKey: 'yellow',
      unit: ' lux',
      usesLightAxis: true,
      valueOf: (SensorSample sample) => sample.lightLux,
    ),
  ];

  @override
  Future<AnalyticsDashboardModel> getDashboard() async {
    final DateTime now = _now();
    final String userKey = await sensorDatabase.resolveHistoryUserKey(
      authSessionProvider.user,
    );
    final List<SensorSample> samples = await sensorDatabase.getHistoryFrom(
      _historyQueryStart(now),
      userKey: userKey,
    );

    return _buildDashboard(samples: samples, now: now);
  }

  @override
  Stream<AnalyticsDashboardModel> watchDashboard() {
    late StreamController<AnalyticsDashboardModel> controller;
    StreamSubscription<List<SensorSample>>? historySubscription;
    Timer? refreshTimer;

    List<SensorSample> latestSamples = const [];
    bool isActive = false;
    bool hasHistorySnapshot = false;
    int bindingGeneration = 0;
    String? boundUserIdentity;

    void emit() {
      if (!isActive || !hasHistorySnapshot || controller.isClosed) {
        return;
      }
      controller.add(_buildDashboard(samples: latestSamples, now: _now()));
    }

    String? identityOf(AppUser? user) {
      if (user == null) {
        return null;
      }
      return '${user.uid}\u0000${user.email ?? ''}\u0000${user.phoneNumber ?? ''}';
    }

    Future<void> bindHistoryForCurrentUser() async {
      final int generation = ++bindingGeneration;
      final AppUser? user = authSessionProvider.user;

      try {
        final StreamSubscription<List<SensorSample>>? previousSubscription =
            historySubscription;
        historySubscription = null;
        latestSamples = const [];
        hasHistorySnapshot = false;
        await previousSubscription?.cancel();
        if (!isActive || generation != bindingGeneration || user == null) {
          return;
        }

        final String userKey = await sensorDatabase.resolveHistoryUserKey(user);
        if (!isActive || generation != bindingGeneration) {
          return;
        }

        historySubscription = sensorDatabase
            .watchHistoryFrom(_historyQueryStart(_now()), userKey: userKey)
            .listen(
              (List<SensorSample> samples) {
                if (!isActive || generation != bindingGeneration) {
                  return;
                }
                latestSamples = samples;
                hasHistorySnapshot = true;
                emit();
              },
              onError: (Object error, StackTrace stackTrace) {
                if (isActive &&
                    generation == bindingGeneration &&
                    !controller.isClosed) {
                  controller.addError(error, stackTrace);
                }
              },
            );
      } catch (error, stackTrace) {
        if (isActive &&
            generation == bindingGeneration &&
            !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    void handleAuthChange() {
      final String? identity = identityOf(authSessionProvider.user);
      if (identity == boundUserIdentity) {
        return;
      }
      boundUserIdentity = identity;
      unawaited(bindHistoryForCurrentUser());
    }

    controller = StreamController<AnalyticsDashboardModel>(
      onListen: () {
        isActive = true;
        authSessionProvider.addListener(handleAuthChange);
        refreshTimer = Timer.periodic(_refreshInterval, (_) => emit());
        handleAuthChange();
      },
      onCancel: () async {
        isActive = false;
        bindingGeneration++;
        authSessionProvider.removeListener(handleAuthChange);
        refreshTimer?.cancel();
        await historySubscription?.cancel();
      },
    );

    return controller.stream;
  }

  AnalyticsDashboardModel _buildDashboard({
    required List<SensorSample> samples,
    required DateTime now,
  }) {
    return AnalyticsDashboardModel(
      title: 'Analytics',
      chartTitle: 'Combined Metrics',
      periods: [
        _buildPeriod(
          range: AnalyticsTimeRange.day,
          tabLabel: 'Day',
          axisLabels: _dayAxisLabels(now),
          samples: samples,
          windowEnd: now,
          window: _dayWindow,
          bucketCount: 24,
        ),
        _buildPeriod(
          range: AnalyticsTimeRange.week,
          tabLabel: 'Week',
          axisLabels: _weekAxisLabels(now),
          samples: samples,
          // Anchored to the next midnight (not `now`) so the 7 rolling
          // buckets align exactly with calendar days, matching the weekday
          // letters on the axis instead of drifting by up to a day.
          windowEnd: _startOfNextDay(now),
          window: _weekWindow,
          bucketCount: 7,
        ),
        _buildMonthlyPeriod(samples: samples, now: now),
      ],
    );
  }

  DateTime _historyQueryStart(DateTime now) {
    final DateTime startOfYear = DateTime(now.year);
    final DateTime startOfWeek = now.subtract(_weekWindow);
    return startOfYear.isBefore(startOfWeek) ? startOfYear : startOfWeek;
  }

  AnalyticsPeriodDataModel _buildMonthlyPeriod({
    required List<SensorSample> samples,
    required DateTime now,
  }) {
    final List<SensorSample> yearSamples =
        samples
            .where((SensorSample sample) => sample.timestamp.year == now.year)
            .toList(growable: false)
          ..sort(
            (SensorSample first, SensorSample second) =>
                first.timestamp.compareTo(second.timestamp),
          );
    final _ChartScale scale = _chartScale(yearSamples);
    final DateTime yearStart = DateTime(now.year);
    final DateTime yearEnd = DateTime(now.year + 1);

    return AnalyticsPeriodDataModel(
      range: AnalyticsTimeRange.month,
      tabLabel: 'Month',
      axisLabels: const <String>[
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
      ],
      yAxisLabels: _primaryYAxisLabels,
      lightYAxisLabels: _lightYAxisLabels(scale.lightMaximum),
      averagesTitle: 'Averages (Month)',
      metricSeries: _metrics
          .map(
            (_MetricSpec metric) => _buildCompleteHistorySeries(
              metric: metric,
              samples: yearSamples,
              rangeStart: yearStart,
              rangeEnd: yearEnd,
              scale: scale,
            ),
          )
          .toList(),
      averages: _metrics
          .map(
            (_MetricSpec metric) =>
                _buildAverage(metric: metric, samples: yearSamples),
          )
          .toList(),
    );
  }

  AnalyticsPeriodDataModel _buildPeriod({
    required AnalyticsTimeRange range,
    required String tabLabel,
    required List<String> axisLabels,
    required List<SensorSample> samples,
    required DateTime windowEnd,
    required Duration window,
    required int bucketCount,
  }) {
    final DateTime windowStart = windowEnd.subtract(window);
    // No upper bound: a device clock running slightly ahead of the phone
    // would otherwise make the newest samples vanish from every chart while
    // Home still reports them as live. The bucket index below clamps into
    // the final bucket instead.
    final List<SensorSample> windowSamples = samples
        .where((SensorSample sample) => !sample.timestamp.isBefore(windowStart))
        .toList();
    final _ChartScale scale = _chartScale(windowSamples);

    return AnalyticsPeriodDataModel(
      range: range,
      tabLabel: tabLabel,
      axisLabels: axisLabels,
      yAxisLabels: _primaryYAxisLabels,
      lightYAxisLabels: _lightYAxisLabels(scale.lightMaximum),
      averagesTitle: 'Averages ($tabLabel)',
      metricSeries: _metrics
          .map(
            (_MetricSpec metric) => _buildSeries(
              metric: metric,
              samples: windowSamples,
              windowStart: windowStart,
              window: window,
              bucketCount: bucketCount,
              scale: scale,
            ),
          )
          .toList(),
      averages: _metrics
          .map(
            (_MetricSpec metric) =>
                _buildAverage(metric: metric, samples: windowSamples),
          )
          .toList(),
    );
  }

  AnalyticsMetricSeriesModel _buildSeries({
    required _MetricSpec metric,
    required List<SensorSample> samples,
    required DateTime windowStart,
    required Duration window,
    required int bucketCount,
    required _ChartScale scale,
  }) => _buildBucketedSeries(
    metric: metric,
    samples: samples,
    bucketCount: bucketCount,
    scale: scale,
    bucketOf: (SensorSample sample) =>
        (sample.timestamp.difference(windowStart).inMilliseconds *
                bucketCount ~/
                window.inMilliseconds)
            .clamp(0, bucketCount - 1)
            .toInt(),
  );

  AnalyticsMetricSeriesModel _buildCompleteHistorySeries({
    required _MetricSpec metric,
    required List<SensorSample> samples,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required _ChartScale scale,
  }) {
    final List<({DateTime timestamp, double value})> values = samples
        .map(
          (SensorSample sample) =>
              (timestamp: sample.timestamp, value: metric.valueOf(sample)),
        )
        .where((item) => item.value != null)
        .map((item) => (timestamp: item.timestamp, value: item.value!))
        .toList(growable: false);
    final double maximum = metric.usesLightAxis
        ? scale.lightMaximum
        : scale.primaryMaximum;
    final int rangeMilliseconds = rangeEnd
        .difference(rangeStart)
        .inMilliseconds;
    final List<AnalyticsChartPointModel> points = [];

    for (int index = 0; index < values.length; index++) {
      final current = values[index];
      final int monthGap = index == 0
          ? 0
          : (current.timestamp.year - values[index - 1].timestamp.year) * 12 +
                current.timestamp.month -
                values[index - 1].timestamp.month;
      points.add(
        AnalyticsChartPointModel(
          x:
              (current.timestamp.difference(rangeStart).inMilliseconds /
                      rangeMilliseconds)
                  .clamp(0.0, 1.0)
                  .toDouble(),
          y: _normalize(current.value, minimum: 0, maximum: maximum),
          breakBefore: monthGap > 1,
        ),
      );
    }

    return AnalyticsMetricSeriesModel(
      label: metric.seriesLabel,
      icon: metric.icon,
      colorKey: metric.colorKey,
      points: points,
    );
  }

  AnalyticsMetricSeriesModel _buildBucketedSeries({
    required _MetricSpec metric,
    required List<SensorSample> samples,
    required int bucketCount,
    required int Function(SensorSample sample) bucketOf,
    required _ChartScale scale,
  }) {
    final List<double> bucketSums = List<double>.filled(bucketCount, 0);
    final List<int> bucketCounts = List<int>.filled(bucketCount, 0);

    for (final SensorSample sample in samples) {
      final double? value = metric.valueOf(sample);
      if (value == null) {
        continue;
      }
      final int bucket = bucketOf(sample).clamp(0, bucketCount - 1).toInt();
      bucketSums[bucket] += value;
      bucketCounts[bucket] += 1;
    }

    final List<({int bucket, double value})> bucketAverages = [];
    for (int bucket = 0; bucket < bucketCount; bucket++) {
      if (bucketCounts[bucket] == 0) {
        continue;
      }
      bucketAverages.add((
        bucket: bucket,
        value: bucketSums[bucket] / bucketCounts[bucket],
      ));
    }

    if (bucketAverages.isEmpty) {
      return AnalyticsMetricSeriesModel(
        label: metric.seriesLabel,
        icon: metric.icon,
        colorKey: metric.colorKey,
        points: const [],
      );
    }

    final double maximum = metric.usesLightAxis
        ? scale.lightMaximum
        : scale.primaryMaximum;
    final List<AnalyticsChartPointModel> points = [];
    for (int index = 0; index < bucketAverages.length; index++) {
      final ({int bucket, double value}) item = bucketAverages[index];
      points.add(
        AnalyticsChartPointModel(
          x: bucketCount == 1 ? 1 : item.bucket / (bucketCount - 1),
          y: _normalize(item.value, minimum: 0, maximum: maximum),
        ),
      );
    }

    return AnalyticsMetricSeriesModel(
      label: metric.seriesLabel,
      icon: metric.icon,
      colorKey: metric.colorKey,
      points: points,
    );
  }

  _ChartScale _chartScale(List<SensorSample> samples) {
    final List<double> lightValues = samples
        .map((SensorSample sample) => sample.lightLux)
        .whereType<double>()
        .toList(growable: false);
    final double observedLightMaximum = lightValues.isEmpty
        ? _primaryAxisMaximum
        : lightValues.reduce(math.max);
    return _ChartScale(
      primaryMaximum: _primaryAxisMaximum,
      lightMaximum: _niceAxisMaximum(observedLightMaximum),
    );
  }

  double _niceAxisMaximum(double observedMaximum) {
    final double safeMaximum = math.max(observedMaximum, 100);
    final double roughInterval = safeMaximum / 4;
    final double magnitude = math
        .pow(10, (math.log(roughInterval) / math.ln10).floor())
        .toDouble();
    final double normalized = roughInterval / magnitude;
    final double factor;
    if (normalized <= 1) {
      factor = 1;
    } else if (normalized <= 2) {
      factor = 2;
    } else if (normalized <= 2.5) {
      factor = 2.5;
    } else if (normalized <= 5) {
      factor = 5;
    } else {
      factor = 10;
    }
    return factor * magnitude * 4;
  }

  List<String> _lightYAxisLabels(double maximum) => List<String>.generate(
    5,
    (int index) => _formatAxisValue(maximum * (4 - index) / 4),
    growable: false,
  );

  String _formatAxisValue(double value) {
    if (value.abs() >= 1000) {
      final double thousands = value / 1000;
      return '${_formatValue(thousands)}k';
    }
    return _formatValue(value);
  }

  /// Maps a value into the painter's top-anchored 0..1 space.
  double _normalize(
    double value, {
    required double minimum,
    required double maximum,
  }) {
    if (maximum <= minimum) {
      return (_chartTopPadding + _chartBottomPadding) / 2;
    }
    final double fraction = ((value - minimum) / (maximum - minimum)).clamp(
      0.0,
      1.0,
    );
    return _chartBottomPadding -
        fraction * (_chartBottomPadding - _chartTopPadding);
  }

  AnalyticsMetricAverageModel _buildAverage({
    required _MetricSpec metric,
    required List<SensorSample> samples,
  }) {
    final List<double> values = samples
        .map(metric.valueOf)
        .whereType<double>()
        .toList();

    final String value;
    if (values.isEmpty) {
      value = '--';
    } else {
      final double average =
          values.reduce((double a, double b) => a + b) / values.length;
      value = '${_formatValue(average)}${metric.unit}';
    }

    return AnalyticsMetricAverageModel(
      label: metric.averageLabel,
      value: value,
      icon: metric.icon,
      colorKey: metric.colorKey,
    );
  }

  List<String> _dayAxisLabels(DateTime now) {
    String hourLabel(DateTime time) =>
        '${time.hour.toString().padLeft(2, '0')}:00';
    return [
      hourLabel(now.subtract(const Duration(hours: 24))),
      hourLabel(now.subtract(const Duration(hours: 16))),
      hourLabel(now.subtract(const Duration(hours: 8))),
      'Now',
    ];
  }

  DateTime _startOfNextDay(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1);

  List<String> _weekAxisLabels(DateTime now) {
    const List<String> letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return List<String>.generate(7, (int index) {
      final DateTime day = now.subtract(Duration(days: 6 - index));
      return letters[day.weekday - 1];
    });
  }

  String _formatValue(double value) {
    final double rounded = (value * 10).roundToDouble() / 10;
    if (rounded == rounded.roundToDouble()) {
      return rounded.round().toString();
    }
    return rounded.toStringAsFixed(1);
  }
}

class _MetricSpec {
  const _MetricSpec({
    required this.seriesLabel,
    required this.averageLabel,
    required this.icon,
    required this.colorKey,
    required this.unit,
    this.usesLightAxis = false,
    required this.valueOf,
  });

  final String seriesLabel;
  final String averageLabel;
  final String icon;
  final String colorKey;
  final String unit;
  final bool usesLightAxis;
  final double? Function(SensorSample sample) valueOf;
}

class _ChartScale {
  const _ChartScale({required this.primaryMaximum, required this.lightMaximum});

  final double primaryMaximum;
  final double lightMaximum;
}
