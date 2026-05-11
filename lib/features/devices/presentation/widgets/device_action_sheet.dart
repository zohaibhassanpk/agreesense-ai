import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';

class DeviceActionSheet extends StatelessWidget {
  const DeviceActionSheet({
    super.key,
    required this.onViewDetails,
    required this.onRefresh,
    required this.onRemove,
  });

  final VoidCallback onViewDetails;
  final VoidCallback onRefresh;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        (context.textTheme.titleMedium ?? AppTextStyles.titleMedium).copyWith(
      letterSpacing: 0,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x2l.w,
        AppSpacing.lg.h,
        AppSpacing.x2l.w,
        AppSpacing.x2l.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: (AppSpacing.x2l * 2).w,
              height: (AppSpacing.xs).h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppBorderRadius.s12.r),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg.h),
          Text('Device Options', style: titleStyle),
          SizedBox(height: AppSpacing.md.h),
          _ActionTile(
            icon: AppAssets.device,
            label: 'View Details',
            onTap: onViewDetails,
          ),
          _ActionTile(
            icon: AppAssets.refresh,
            label: 'Refresh',
            onTap: onRefresh,
          ),
          _ActionTile(
            icon: AppAssets.alert,
            label: 'Remove Device',
            onTap: onRemove,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color resolvedColor = color ?? AppColors.textPrimary;
    final TextStyle labelStyle =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
      color: resolvedColor,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.s16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: AppSpacing.xl.w,
              height: AppSpacing.xl.w,
              colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
            ),
            SizedBox(width: AppSpacing.lg.w),
            Text(label, style: labelStyle),
          ],
        ),
      ),
    );
  }
}
