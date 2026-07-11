import '../../../../core/constants/app_assets.dart';
import '../../../../core/services/realtime_db/sensor_database_service.dart';
import '../../domain/entities/analytics_time_range.dart';
import '../models/analytics_chart_point_model.dart';
import '../models/analytics_dashboard_model.dart';
import '../models/analytics_metric_average_model.dart';
import '../models/analytics_metric_series_model.dart';
import '../models/analytics_period_data_model.dart';

abstract class AnalyticsRemoteDataSource {
  Future<AnalyticsDashboardModel> getDashboard();
}

/// Builds the analytics dashboard from the field's `history` samples.
///
/// One month-wide query feeds all three ranges; each range buckets its
/// window, averages the samples per bucket and normalizes them into the
/// 0..1 chart space the painter expects (y is top-anchored, so higher
/// values map to smaller y).
class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSourceImpl({required this.sensorDatabase});

  final SensorDatabaseService sensorDatabase;

  static const Duration _dayWindow = Duration(hours: 24);
  static const Duration _weekWindow = Duration(days: 7);
  static const Duration _monthWindow = Duration(days: 28);

  /// Vertical padding of the normalized chart space, so curves stay clear of
  /// the card edges like the design mocks.
  static const double _chartTopPadding = 0.08;
  static const double _chartBottomPadding = 0.92;

  /// Charted metrics. The design's third "Soil pH" series is replaced by
  /// humidity: the hardware has no pH probe, and the SRS asks for moisture,
  /// temperature and humidity trends.
  static final List<_MetricSpec> _metrics = [
    _MetricSpec(
      seriesLabel: 'Moisture',
      averageLabel: 'Soil Moisture',
      icon: AppAssets.drop,
      colorKey: 'blue',
      unit: '%',
      minValue: 0,
      maxValue: 100,
      valueOf: (SensorSample sample) => sample.soilMoisturePercent,
    ),
    _MetricSpec(
      seriesLabel: 'Temp',
      averageLabel: 'Temperature',
      icon: AppAssets.temprature,
      colorKey: 'red',
      unit: '°C',
      minValue: 0,
      maxValue: 50,
      valueOf: (SensorSample sample) => sample.temperatureC,
    ),
    _MetricSpec(
      seriesLabel: 'Humidity',
      averageLabel: 'Humidity',
      icon: AppAssets.cloud,
      colorKey: 'green',
      unit: '%',
      minValue: 0,
      maxValue: 100,
      valueOf: (SensorSample sample) => sample.humidityPercent,
    ),
  ];

  @override
  Future<AnalyticsDashboardModel> getDashboard() async {
    final DateTime now = DateTime.now();
    final List<SensorSample> samples = await sensorDatabase.getHistoryFrom(
      now.subtract(_monthWindow),
    );

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
        _buildPeriod(
          range: AnalyticsTimeRange.month,
          tabLabel: 'Month',
          axisLabels: const ['W1', 'W2', 'W3', 'W4'],
          samples: samples,
          windowEnd: now,
          window: _monthWindow,
          bucketCount: 4,
        ),
      ],
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

    return AnalyticsPeriodDataModel(
      range: range,
      tabLabel: tabLabel,
      axisLabels: axisLabels,
      averagesTitle: 'Averages ($tabLabel)',
      metricSeries: _metrics
          .map(
            (_MetricSpec metric) => _buildSeries(
              metric: metric,
              samples: windowSamples,
              windowStart: windowStart,
              window: window,
              bucketCount: bucketCount,
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
  }) {
    final List<double> bucketSums = List<double>.filled(bucketCount, 0);
    final List<int> bucketCounts = List<int>.filled(bucketCount, 0);

    for (final SensorSample sample in samples) {
      final double? value = metric.valueOf(sample);
      if (value == null) {
        continue;
      }
      final int bucket =
          (sample.timestamp.difference(windowStart).inMilliseconds *
                  bucketCount ~/
                  window.inMilliseconds)
              .clamp(0, bucketCount - 1)
              .toInt();
      bucketSums[bucket] += value;
      bucketCounts[bucket] += 1;
    }

    final List<AnalyticsChartPointModel> points = [];
    for (int bucket = 0; bucket < bucketCount; bucket++) {
      if (bucketCounts[bucket] == 0) {
        continue;
      }
      final double average = bucketSums[bucket] / bucketCounts[bucket];
      points.add(
        AnalyticsChartPointModel(
          x: bucketCount == 1 ? 1 : bucket / (bucketCount - 1),
          y: _normalize(average, metric),
        ),
      );
    }

    // The painter draws a curve plus an end marker, so guarantee at least
    // two points: duplicate a lone reading and flat-line an empty window.
    if (points.length == 1) {
      final AnalyticsChartPointModel only = points.first;
      points
        ..clear()
        ..add(AnalyticsChartPointModel(x: 0, y: only.y))
        ..add(AnalyticsChartPointModel(x: 1, y: only.y));
    } else if (points.isEmpty) {
      points
        ..add(const AnalyticsChartPointModel(x: 0, y: _chartBottomPadding))
        ..add(const AnalyticsChartPointModel(x: 1, y: _chartBottomPadding));
    }

    return AnalyticsMetricSeriesModel(
      label: metric.seriesLabel,
      icon: metric.icon,
      colorKey: metric.colorKey,
      points: points,
    );
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

  /// Maps a metric value into the painter's top-anchored 0..1 space.
  double _normalize(double value, _MetricSpec metric) {
    final double fraction =
        ((value - metric.minValue) / (metric.maxValue - metric.minValue)).clamp(
          0.0,
          1.0,
        );
    return _chartBottomPadding -
        fraction * (_chartBottomPadding - _chartTopPadding);
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
    required this.minValue,
    required this.maxValue,
    required this.valueOf,
  });

  final String seriesLabel;
  final String averageLabel;
  final String icon;
  final String colorKey;
  final String unit;
  final double minValue;
  final double maxValue;
  final double? Function(SensorSample sample) valueOf;
}
