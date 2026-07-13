import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/analytics_metric_average.dart';
import '../../domain/entities/analytics_metric_series.dart';
import 'analytics_line_chart.dart';
import 'analytics_metric_average_card.dart';

/// Displays the light-intensity trend and its summary statistics.
class AnalyticsLightIntensityCard extends StatelessWidget {
  const AnalyticsLightIntensityCard({
    super.key,
    required this.series,
    required this.stats,
    required this.axisLabels,
  });

  final AnalyticsMetricSeries series;
  final List<AnalyticsMetricAverage> stats;
  final List<String> axisLabels;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        (context.textTheme.titleMedium ?? AppTextStyles.titleMedium).copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.s32.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: AppSpacing.sm.r,
            offset: Offset(0, (AppSpacing.sm / 2).h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text('Light Intensity Trend', style: titleStyle)),
          SizedBox(height: 16.h),
          AnalyticsLineChart(series: [series], axisLabels: axisLabels),
          SizedBox(height: 20.h),
          _LightStatsGrid(stats: stats),
        ],
      ),
    );
  }
}

class _LightStatsGrid extends StatelessWidget {
  const _LightStatsGrid({required this.stats});

  final List<AnalyticsMetricAverage> stats;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];

    for (int index = 0; index < stats.length; index += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _LightStatCard(metric: stats[index])),
            SizedBox(width: 12.w),
            Expanded(
              child: index + 1 < stats.length
                  ? _LightStatCard(metric: stats[index + 1])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (index + 2 < stats.length) {
        rows.add(SizedBox(height: 12.h));
      }
    }

    return Column(children: rows);
  }
}

class _LightStatCard extends StatelessWidget {
  const _LightStatCard({required this.metric});

  final AnalyticsMetricAverage metric;

  @override
  Widget build(BuildContext context) {
    return AnalyticsMetricAverageCard(
      metric: metric,
      isWide: false,
      showIcon: true,
      centerContent: false,
    );
  }
}
