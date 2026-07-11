import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_chart_point.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_metric_average.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_metric_series.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_period_data.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_time_range.dart';
import 'package:agrisenseaiapp/features/analytics/presentation/widgets/analytics_range_tabs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_widget_harness.dart';

void main() {
  testWidgets('AnalyticsRangeTabs switches selected tab', (tester) async {
    const periods = [
      AnalyticsPeriodData(
        range: AnalyticsTimeRange.day,
        tabLabel: 'Day',
        axisLabels: ['a'],
        averagesTitle: 'avg',
        metricSeries: [
          AnalyticsMetricSeries(
            label: 'm',
            icon: 'i',
            colorKey: 'c',
            points: [AnalyticsChartPoint(x: 0, y: 0)],
          ),
        ],
        averages: [
          AnalyticsMetricAverage(
            label: 'a',
            value: '1',
            icon: 'i',
            colorKey: 'c',
          ),
        ],
      ),
      AnalyticsPeriodData(
        range: AnalyticsTimeRange.week,
        tabLabel: 'Week',
        axisLabels: ['b'],
        averagesTitle: 'avg',
        metricSeries: [
          AnalyticsMetricSeries(
            label: 'm',
            icon: 'i',
            colorKey: 'c',
            points: [AnalyticsChartPoint(x: 0, y: 0)],
          ),
        ],
        averages: [
          AnalyticsMetricAverage(
            label: 'a',
            value: '1',
            icon: 'i',
            colorKey: 'c',
          ),
        ],
      ),
    ];

    AnalyticsTimeRange selected = AnalyticsTimeRange.day;

    await tester.pumpWidget(
      buildResponsiveTestApp(
        AnalyticsRangeTabs(
          periods: periods,
          selectedRange: selected,
          onSelected: (range) => selected = range,
        ),
      ),
    );

    await tester.tap(find.text('Week'));
    expect(selected, AnalyticsTimeRange.week);
  });
}
