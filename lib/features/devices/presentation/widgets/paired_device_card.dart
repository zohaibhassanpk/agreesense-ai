import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/device_item.dart';

class PairedDeviceCard extends StatelessWidget {
  const PairedDeviceCard({
    super.key,
    required this.device,
    this.onMenuTap,
  });

  final DeviceItem device;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        (context.textTheme.titleMedium ?? AppTextStyles.titleMedium).copyWith(
      letterSpacing: 0,
    );
    final TextStyle statusStyle =
        (context.textTheme.labelSmall ?? AppTextStyles.labelSmall).copyWith(
      color: AppColors.textSecondary,
      letterSpacing: 0,
    );

    final double iconBoxSize = (AppSpacing.x2l * 2).w;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.s16.r),
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
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppBorderRadius.s12.r),
            ),
            child: Center(
              child: SvgPicture.asset(
                device.icon,
                width: AppSpacing.x2l.w,
                height: AppSpacing.x2l.w,
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.lg.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: titleStyle),
                SizedBox(height: (AppSpacing.sm / 2).h),
                Row(
                  children: [
                    _ConnectionDot(isConnected: device.isConnected),
                    SizedBox(width: AppSpacing.xs.w),
                    Expanded(
                      child: Text(device.statusText, style: statusStyle),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          InkWell(
            onTap: onMenuTap,
            borderRadius: BorderRadius.circular(AppBorderRadius.circular.r),
            child: Container(
              width: (AppSpacing.x2l + AppSpacing.sm).w,
              height: (AppSpacing.x2l + AppSpacing.sm).w,
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  AppAssets.menuDots,
                  width: AppSpacing.lg.w,
                  height: AppSpacing.lg.w,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textTertiary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.xs.w,
      height: AppSpacing.xs.w,
      decoration: BoxDecoration(
        color: isConnected ? AppColors.primary : AppColors.textTertiary,
        shape: BoxShape.circle,
      ),
    );
  }
}
