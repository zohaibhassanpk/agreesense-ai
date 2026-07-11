import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/analytics_period_data.dart';
import '../../domain/entities/analytics_time_range.dart';

class AnalyticsRangeTabs extends StatelessWidget {
  const AnalyticsRangeTabs({
    super.key,
    required this.periods,
    required this.selectedRange,
    required this.onSelected,
  });

  final List<AnalyticsPeriodData> periods;
  final AnalyticsTimeRange selectedRange;
  final ValueChanged<AnalyticsTimeRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36.h,
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppBorderRadius.s12.r),
      ),
      child: Row(
        children: periods.map((AnalyticsPeriodData period) {
          final bool isSelected = period.range == selectedRange;
          final TextStyle textStyle =
              (context.textTheme.titleLarge ?? AppTextStyles.titleLarge)
                  .copyWith(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12.sp,
                    height: 1,
                  );

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(period.range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : AppColors.transparent,
                  borderRadius: BorderRadius.circular(AppBorderRadius.s8.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.05),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ]
                      : null,
                ),
                child: Center(child: Text(period.tabLabel, style: textStyle)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
