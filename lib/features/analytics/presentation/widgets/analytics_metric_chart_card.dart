import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/analytics_metric_series.dart';
import '../../domain/entities/analytics_period_data.dart';
import 'analytics_line_chart.dart';

class AnalyticsMetricChartCard extends StatelessWidget {
  const AnalyticsMetricChartCard({
    super.key,
    required this.chartTitle,
    required this.period,
  });

  final String chartTitle;
  final AnalyticsPeriodData period;

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
          Center(child: Text(chartTitle, style: titleStyle)),
          SizedBox(height: 16.h),
          _AnalyticsLegendRow(series: period.metricSeries),
          SizedBox(height: 16.h),
          AnalyticsLineChart(
            series: period.metricSeries,
            axisLabels: period.axisLabels,
            yAxisLabels: period.yAxisLabels,
            lightYAxisLabels: period.lightYAxisLabels,
          ),
        ],
      ),
    );
  }
}

class _AnalyticsLegendRow extends StatelessWidget {
  const _AnalyticsLegendRow({required this.series});

  final List<AnalyticsMetricSeries> series;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle =
        (context.textTheme.bodySmall ?? AppTextStyles.bodySmall).copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 10.sp,
        );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16.w,
      runSpacing: 8.h,
      children: series.map((AnalyticsMetricSeries item) {
        final Color accentColor = _colorFromKey(item.colorKey);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            SvgPicture.asset(
              item.icon,
              width: 12.w,
              height: 12.w,
              colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
            ),
            SizedBox(width: 6.w),
            Text(item.label, style: textStyle),
          ],
        );
      }).toList(),
    );
  }
}

Color _colorFromKey(String colorKey) {
  switch (colorKey) {
    case 'blue':
      return AppColors.accentBlue;
    case 'red':
      return AppColors.error;
    case 'green':
      return AppColors.primary;
    case 'yellow':
      return AppColors.accentYellow;
    default:
      return AppColors.textPrimary;
  }
}
