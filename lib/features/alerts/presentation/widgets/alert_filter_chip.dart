import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';

class AlertFilterChip extends StatelessWidget {
  const AlertFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        isSelected ? AppColors.darkGreen : AppColors.surfaceMuted;
    final Color textColor = isSelected
        ? AppColors.surface
        : AppColors.textSecondary;
    final TextStyle textStyle =
        (context.textTheme.labelMedium ?? AppTextStyles.labelMedium).copyWith(
      color: textColor,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.chip,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg.w,
          vertical: (AppSpacing.sm / 2).h,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppBorderRadius.chip,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.08),
                    blurRadius: AppSpacing.sm.r,
                    offset: Offset(0, (AppSpacing.sm / 2).h),
                  ),
                ]
              : null,
        ),
        child: Text(label, style: textStyle),
      ),
    );
  }
}
