import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/device_banner.dart';

class DevicesHeader extends StatelessWidget {
  const DevicesHeader({super.key, required this.banner});

  final DeviceBanner banner;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseTitleStyle =
        context.textTheme.headlineLarge ?? AppTextStyles.headingLarge;
    final TextStyle titleStyle = baseTitleStyle.copyWith(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Devices', style: titleStyle),
          SizedBox(height: AppSpacing.md.h),
          _OfflineModeBanner(banner: banner),
        ],
      ),
    );
  }
}

class _OfflineModeBanner extends StatelessWidget {
  const _OfflineModeBanner({required this.banner});

  final DeviceBanner banner;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        (context.textTheme.labelMedium ?? AppTextStyles.labelMedium).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );
    final TextStyle subtitleStyle =
        (context.textTheme.labelSmall ?? AppTextStyles.labelSmall).copyWith(
      color: AppColors.textSecondary,
      letterSpacing: 0,
    );

    final double iconSize = (AppSpacing.x2l + AppSpacing.sm).w;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.s12.r),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Center(
              child: SvgPicture.asset(
                banner.icon,
                width: AppSpacing.lg.w,
                height: AppSpacing.lg.w,
                colorFilter: const ColorFilter.mode(
                  AppColors.accentBrown,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(banner.title, style: titleStyle),
                SizedBox(height: (AppSpacing.sm / 2).h),
                Text(banner.subtitle, style: subtitleStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
