import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/analytics_metric_average.dart';

class AnalyticsMetricAverageCard extends StatelessWidget {
  const AnalyticsMetricAverageCard({
    super.key,
    required this.metric,
    required this.isWide,
    required this.showIcon,
    required this.centerContent,
  });

  final AnalyticsMetricAverage metric;
  final bool isWide;
  final bool showIcon;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _colorFromKey(metric.colorKey);
    final TextStyle labelStyle =
        (context.textTheme.labelSmall ?? AppTextStyles.labelSmall).copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w500,
          height: 1.1,
        );
    final TextStyle valueStyle =
        (context.textTheme.titleMedium ?? AppTextStyles.titleMedium).copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        );

    return Container(
      constraints: BoxConstraints(minHeight: 72.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.s24.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: AppSpacing.sm.r,
            offset: Offset(0, (AppSpacing.sm / 2).h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (showIcon) ...[
            SvgPicture.asset(
              metric.icon,
              width: 16.w,
              height: 16.w,
              colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: labelStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                ),
                SizedBox(height: (AppSpacing.sm / 2).h),
                Text(
                  metric.value,
                  style: valueStyle,
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        ],
      ),
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
