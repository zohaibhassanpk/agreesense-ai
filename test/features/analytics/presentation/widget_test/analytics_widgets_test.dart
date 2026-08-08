import 'package:agrisenseaiapp/core/constants/app_assets.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_chart_point.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_metric_average.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_metric_series.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_period_data.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_time_range.dart';
import 'package:agrisenseaiapp/features/analytics/presentation/widgets/analytics_metric_average_card.dart';
import 'package:agrisenseaiapp/features/analytics/presentation/widgets/analytics_metric_chart_card.dart';
import 'package:agrisenseaiapp/features/analytics/presentation/widgets/analytics_range_tabs.dart';
import 'package:flutter/material.dart';
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

  testWidgets('combined chart includes the light intensity line', (
    tester,
  ) async {
    const points = <AnalyticsChartPoint>[
      AnalyticsChartPoint(x: 0, y: 0.8),
      AnalyticsChartPoint(x: 1, y: 0.3),
    ];
    const period = AnalyticsPeriodData(
      range: AnalyticsTimeRange.week,
      tabLabel: 'Week',
      axisLabels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      averagesTitle: 'Averages (Week)',
      metricSeries: [
        AnalyticsMetricSeries(
          label: 'Moisture',
          icon: AppAssets.drop,
          colorKey: 'blue',
          points: points,
        ),
        AnalyticsMetricSeries(
          label: 'Temp',
          icon: AppAssets.temprature,
          colorKey: 'red',
          points: points,
        ),
        AnalyticsMetricSeries(
          label: 'Humidity',
          icon: AppAssets.cloud,
          colorKey: 'green',
          points: points,
        ),
        AnalyticsMetricSeries(
          label: 'Light',
          icon: AppAssets.sun,
          colorKey: 'yellow',
          points: points,
        ),
      ],
      averages: [],
    );

    await tester.pumpWidget(
      buildResponsiveTestApp(
        const SingleChildScrollView(
          child: AnalyticsMetricChartCard(
            chartTitle: 'Combined Metrics',
            period: period,
          ),
        ),
      ),
    );

    expect(find.text('Combined Metrics'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Light Intensity Trend'), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('light summary uses the standard metric summary card', (
    tester,
  ) async {
    const light = AnalyticsMetricAverage(
      label: 'Light Intensity',
      value: '52,100 lux',
      icon: AppAssets.sun,
      colorKey: 'yellow',
    );

    await tester.pumpWidget(
      buildResponsiveTestApp(
        const AnalyticsMetricAverageCard(
          metric: light,
          isWide: false,
          showIcon: true,
          centerContent: false,
        ),
      ),
    );

    expect(find.text('Light Intensity'), findsOneWidget);
    expect(find.text('52,100 lux'), findsOneWidget);
  });
}
