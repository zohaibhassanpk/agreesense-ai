import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';

class AnalyticsHeader extends StatelessWidget {
  const AnalyticsHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseTitleStyle =
        context.textTheme.headlineLarge ?? AppTextStyles.headingLarge;
    final TextStyle titleStyle = baseTitleStyle.copyWith(
      color: AppColors.textPrimary,
      fontWeight: AppTextStyles.headingLarge.fontWeight,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x2l.w,
        (AppSpacing.x2l + AppSpacing.xl).h,
        AppSpacing.x2l.w,
        AppSpacing.lg.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppBorderRadius.s24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: AppSpacing.md.r,
            offset: Offset(0, AppSpacing.sm.h),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: titleStyle),
      ),
    );
  }
}
