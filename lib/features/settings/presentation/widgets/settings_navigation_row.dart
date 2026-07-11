import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';

class SettingsNavigationRow extends StatelessWidget {
  const SettingsNavigationRow({
    super.key,
    required this.title,
    required this.value,
    this.leadingIcon,
    this.onTap,
  });

  final String title;
  final String value;
  final String? leadingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
    final TextStyle valueStyle =
        (context.textTheme.labelMedium ?? AppTextStyles.labelMedium).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.s16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.h),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Container(
                width: (AppSpacing.x2l + AppSpacing.sm).w,
                height: (AppSpacing.x2l + AppSpacing.sm).w,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint20,
                  borderRadius: BorderRadius.circular(AppBorderRadius.s12.r),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    leadingIcon!,
                    width: AppSpacing.lg.w,
                    height: AppSpacing.lg.w,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md.w),
            ],
            Expanded(child: Text(title, style: titleStyle)),
            Row(
              children: [
                Text(value, style: valueStyle),
                SizedBox(width: AppSpacing.xs.w),
                SvgPicture.asset(
                  AppAssets.settingsArrow,
                  width: (AppSpacing.sm / 2).w,
                  height: AppSpacing.md.h,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
