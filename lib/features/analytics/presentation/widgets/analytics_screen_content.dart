import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/analytics_dashboard.dart';
import '../../domain/entities/analytics_period_data.dart';
import '../../domain/entities/analytics_time_range.dart';
import 'analytics_header.dart';
import 'analytics_metric_average_card.dart';
import 'analytics_metric_chart_card.dart';
import 'analytics_range_tabs.dart';

class AnalyticsScreenContent extends StatelessWidget {
  const AnalyticsScreenContent({
    super.key,
    required this.dashboard,
    required this.period,
    required this.selectedRange,
    required this.onRangeSelected,
  });

  final AnalyticsDashboard dashboard;
  final AnalyticsPeriodData period;
  final AnalyticsTimeRange selectedRange;
  final ValueChanged<AnalyticsTimeRange> onRangeSelected;

  @override
  Widget build(BuildContext context) {
    final TextStyle averagesTitleStyle =
        (context.textTheme.titleMedium ?? AppTextStyles.titleMedium).copyWith(
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        );

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                AnalyticsHeader(title: dashboard.title),
                AnalyticsRangeTabs(
                  periods: dashboard.periods,
                  selectedRange: selectedRange,
                  onSelected: onRangeSelected,
                ),
                SizedBox(height: AppSpacing.md.h),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
              children: [
                AnalyticsMetricChartCard(
                  chartTitle: dashboard.chartTitle,
                  period: period,
                ),
                SizedBox(height: 24.h),
                Text(period.averagesTitle, style: averagesTitleStyle),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: AnalyticsMetricAverageCard(
                        metric: period.averages[0],
                        isWide: false,
                        showIcon: true,
                        centerContent: false,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: AnalyticsMetricAverageCard(
                        metric: period.averages[1],
                        isWide: false,
                        showIcon: true,
                        centerContent: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                AnalyticsMetricAverageCard(
                  metric: period.averages[2],
                  isWide: true,
                  showIcon: true,
                  centerContent: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
