import '../../../../core/constants/app_assets.dart';
import '../../domain/entities/analytics_time_range.dart';
import '../models/analytics_chart_point_model.dart';
import '../models/analytics_dashboard_model.dart';
import '../models/analytics_metric_average_model.dart';
import '../models/analytics_metric_series_model.dart';
import '../models/analytics_period_data_model.dart';

abstract class AnalyticsLocalDataSource {
  Future<AnalyticsDashboardModel> getDashboard();
}

class AnalyticsLocalDataSourceImpl implements AnalyticsLocalDataSource {
  @override
  Future<AnalyticsDashboardModel> getDashboard() async {
    return AnalyticsDashboardModel(
      title: 'Analytics',
      chartTitle: 'Combined Metrics',
      periods: [
        AnalyticsPeriodDataModel(
          range: AnalyticsTimeRange.day,
          tabLabel: 'Day',
          axisLabels: const ['08:00', '12:00', '16:00', 'Now'],
          averagesTitle: 'Averages (Day)',
          metricSeries: _buildDaySeries(),
          averages: _buildAverages(),
        ),
        AnalyticsPeriodDataModel(
          range: AnalyticsTimeRange.week,
          tabLabel: 'Week',
          axisLabels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
          averagesTitle: 'Averages (Week)',
          metricSeries: _buildWeekSeries(),
          averages: _buildAverages(),
        ),
        AnalyticsPeriodDataModel(
          range: AnalyticsTimeRange.month,
          tabLabel: 'Month',
          axisLabels: const ['W1', 'W2', 'W3', 'W4'],
          averagesTitle: 'Averages (Month)',
          metricSeries: _buildMonthSeries(),
          averages: _buildAverages(),
        ),
      ],
    );
  }

  List<AnalyticsMetricAverageModel> _buildAverages() {
    return const [
      AnalyticsMetricAverageModel(
        label: 'Soil Moisture',
        value: '42%',
        icon: AppAssets.drop,
        colorKey: 'blue',
      ),
      AnalyticsMetricAverageModel(
        label: 'Temperature',
        value: '26°C',
        icon: AppAssets.temprature,
        colorKey: 'red',
      ),
      AnalyticsMetricAverageModel(
        label: 'Soil pH',
        value: '6.8 (Optimal)',
        icon: AppAssets.jar,
        colorKey: 'green',
      ),
    ];
  }

  List<AnalyticsMetricSeriesModel> _buildDaySeries() {
    return const [
      AnalyticsMetricSeriesModel(
        label: 'Moisture',
        icon: AppAssets.drop,
        colorKey: 'blue',
        points: [
          AnalyticsChartPointModel(x: 0.00, y: 0.60),
          AnalyticsChartPointModel(x: 0.20, y: 0.59),
          AnalyticsChartPointModel(x: 0.32, y: 0.61),
          AnalyticsChartPointModel(x: 0.43, y: 0.44),
          AnalyticsChartPointModel(x: 0.57, y: 0.38),
          AnalyticsChartPointModel(x: 0.72, y: 0.30),
          AnalyticsChartPointModel(x: 0.85, y: 0.26),
          AnalyticsChartPointModel(x: 1.00, y: 0.12),
        ],
      ),
      AnalyticsMetricSeriesModel(
        label: 'Temp',
        icon: AppAssets.temprature,
        colorKey: 'red',
        points: [
          AnalyticsChartPointModel(x: 0.00, y: 0.33),
          AnalyticsChartPointModel(x: 0.18, y: 0.31),
          AnalyticsChartPointModel(x: 0.32, y: 0.32),
          AnalyticsChartPointModel(x: 0.45, y: 0.24),
          AnalyticsChartPointModel(x: 0.63, y: 0.18),
          AnalyticsChartPointModel(x: 0.72, y: 0.11),
          AnalyticsChartPointModel(x: 0.90, y: 0.12),
          AnalyticsChartPointModel(x: 1.00, y: 0.16),
        ],
      ),
      AnalyticsMetricSeriesModel(
        label: 'Soil pH',
        icon: AppAssets.jar,
        colorKey: 'green',
        points: [
          AnalyticsChartPointModel(x: 0.00, y: 0.86),
          AnalyticsChartPointModel(x: 0.18, y: 0.85),
          AnalyticsChartPointModel(x: 0.34, y: 0.85),
          AnalyticsChartPointModel(x: 0.48, y: 0.81),
          AnalyticsChartPointModel(x: 0.64, y: 0.78),
          AnalyticsChartPointModel(x: 0.76, y: 0.73),
          AnalyticsChartPointModel(x: 0.88, y: 0.74),
          AnalyticsChartPointModel(x: 1.00, y: 0.73),
        ],
      ),
    ];
  }

  List<AnalyticsMetricSeriesModel> _buildWeekSeries() {
    return const [
      AnalyticsMetricSeriesModel(
        label: 'Moisture',
        icon: AppAssets.drop,
        colorKey: 'blue',
        points: [
          AnalyticsChartPointModel(x: 0.00, y: 0.60),
          AnalyticsChartPointModel(x: 0.16, y: 0.59),
          AnalyticsChartPointModel(x: 0.32, y: 0.61),
          AnalyticsChartPointModel(x: 0.48, y: 0.43),
          AnalyticsChartPointModel(x: 0.64, y: 0.39),
          AnalyticsChartPointModel(x: 0.80, y: 0.30),
          AnalyticsChartPointModel(x: 1.00, y: 0.12),
        ],
      ),
      AnalyticsMetricSeriesModel(
        label: 'Temp',
        icon: AppAssets.temprature,
        colorKey: 'red',
        points: [
          AnalyticsChartPointModel(x: 0.00, y: 0.33),
          AnalyticsChartPointModel(x: 0.16, y: 0.31),
          AnalyticsChartPointModel(x: 0.32, y: 0.32),
          AnalyticsChartPointModel(x: 0.48, y: 0.24),
          AnalyticsChartPointModel(x: 0.64, y: 0.19),
          AnalyticsChartPointModel(x: 0.80, y: 0.11),
          AnalyticsChartPointModel(x: 1.00, y: 0.16),
        ],
      ),
      AnalyticsMetricSeriesModel(
        label: 'Soil pH',
        icon: AppAssets.jar,
        colorKey: 'green',
        points: [
          AnalyticsChartPointModel(x: 0.00, y: 0.86),
          AnalyticsChartPointModel(x: 0.16, y: 0.85),
          AnalyticsChartPointModel(x: 0.32, y: 0.85),
          AnalyticsChartPointModel(x: 0.48, y: 0.81),
          AnalyticsChartPointModel(x: 0.64, y: 0.78),
          AnalyticsChartPointModel(x: 0.80, y: 0.73),
          AnalyticsChartPointModel(x: 1.00, y: 0.73),
        ],
      ),
    ];
  }

  List<AnalyticsMetricSeriesModel> _buildMonthSeries() {
    return const [
      AnalyticsMetricSeriesModel(
        label: 'Moisture',
        icon: AppAssets.drop,
        colorKey: 'blue',
        points: [
          AnalyticsChartPointModel(x: 0.00, y: 0.60),
          AnalyticsChartPointModel(x: 0.34, y: 0.59),
          AnalyticsChartPointModel(x: 0.67, y: 0.30),
          AnalyticsChartPointModel(x: 1.00, y: 0.12),
        ],
      ),
      AnalyticsMetricSeriesModel(
        label: 'Temp',
        icon: AppAssets.temprature,
        colorKey: 'red',
        points: [
          AnalyticsChartPointModel(x: 0.00, y: 0.33),
          AnalyticsChartPointModel(x: 0.34, y: 0.32),
          AnalyticsChartPointModel(x: 0.67, y: 0.11),
          AnalyticsChartPointModel(x: 1.00, y: 0.16),
        ],
      ),
      AnalyticsMetricSeriesModel(
        label: 'Soil pH',
        icon: AppAssets.jar,
        colorKey: 'green',
        points: [
          AnalyticsChartPointModel(x: 0.00, y: 0.86),
          AnalyticsChartPointModel(x: 0.34, y: 0.85),
          AnalyticsChartPointModel(x: 0.67, y: 0.73),
          AnalyticsChartPointModel(x: 1.00, y: 0.73),
        ],
      ),
    ];
  }
}
