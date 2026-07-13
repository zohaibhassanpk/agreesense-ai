import 'package:agrisenseaiapp/core/constants/app_assets.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_chart_point.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_metric_average.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_metric_series.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_period_data.dart';
import 'package:agrisenseaiapp/features/analytics/domain/entities/analytics_time_range.dart';
import 'package:agrisenseaiapp/features/analytics/presentation/widgets/analytics_light_intensity_card.dart';
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

  testWidgets('light intensity card renders its trend and four stats', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    const series = AnalyticsMetricSeries(
      label: 'Light Intensity',
      icon: AppAssets.sun,
      colorKey: 'yellow',
      points: [
        AnalyticsChartPoint(x: 0, y: 0.8),
        AnalyticsChartPoint(x: 1, y: 0.3),
      ],
    );
    const stats = [
      AnalyticsMetricAverage(
        label: 'Average',
        value: '50,000 lux',
        icon: AppAssets.sun,
        colorKey: 'yellow',
      ),
      AnalyticsMetricAverage(
        label: 'Minimum',
        value: '20,000 lux',
        icon: AppAssets.sun,
        colorKey: 'yellow',
      ),
      AnalyticsMetricAverage(
        label: 'Maximum',
        value: '80,000 lux',
        icon: AppAssets.sun,
        colorKey: 'yellow',
      ),
      AnalyticsMetricAverage(
        label: 'Latest Reading',
        value: '62,000 lux',
        icon: AppAssets.sun,
        colorKey: 'yellow',
      ),
    ];

    for (final size in [const Size(320, 568), const Size(375, 812)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        buildResponsiveTestApp(
          const SingleChildScrollView(
            child: AnalyticsLightIntensityCard(
              series: series,
              stats: stats,
              axisLabels: ['00:00', '08:00', '16:00', 'Now'],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    }

    expect(find.text('Light Intensity Trend'), findsOneWidget);
    expect(find.text('Average'), findsOneWidget);
    expect(find.text('Minimum'), findsOneWidget);
    expect(find.text('Maximum'), findsOneWidget);
    expect(find.text('Latest Reading'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
