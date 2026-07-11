import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/device_item.dart';
import 'dashed_border.dart';

class AvailableDeviceCard extends StatelessWidget {
  const AvailableDeviceCard({super.key, required this.device});

  final DeviceItem device;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        (context.textTheme.titleMedium ?? AppTextStyles.titleMedium).copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
    final TextStyle statusStyle =
        (context.textTheme.labelSmall ?? AppTextStyles.labelSmall).copyWith(
      color: AppColors.textTertiary,
      letterSpacing: 0,
    );
    final TextStyle buttonStyle =
        (context.textTheme.labelMedium ?? AppTextStyles.labelMedium).copyWith(
      color: AppColors.white,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );

    final double iconSize = (AppSpacing.xl * 2).w;

    return DashedBorderContainer(
      borderRadius: BorderRadius.circular(AppBorderRadius.s16.r),
      color: AppColors.border,
      dashLength: AppSpacing.sm,
      dashGap: AppSpacing.xs,
      padding: EdgeInsets.all(AppSpacing.lg.r),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                device.icon,
                width: AppSpacing.xl.w,
                height: AppSpacing.xl.w,
                colorFilter: const ColorFilter.mode(
                  AppColors.textTertiary,
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
                Text(device.name, style: titleStyle),
                SizedBox(height: (AppSpacing.sm / 2).h),
                Text(device.statusText, style: statusStyle),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md.w,
                vertical: AppSpacing.xs.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.s8.r),
              ),
              textStyle: buttonStyle,
            ),
            child: Text('Connect', style: buttonStyle),
          ),
        ],
      ),
    );
  }
}
