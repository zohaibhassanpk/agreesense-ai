import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class SplashBackgroundIcon extends StatelessWidget {
  const SplashBackgroundIcon({
    super.key,
    required this.asset,
    required this.size,
    this.top,
    this.left,
    this.bottom,
    this.right,
  });

  final String asset;
  final double size;
  final double? top;
  final double? left;
  final double? bottom;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top?.h,
      left: left?.w,
      bottom: bottom?.h,
      right: right?.w,
      child: SvgPicture.asset(
        asset,
        width: size.r,
        height: size.r,
        colorFilter: ColorFilter.mode(
          AppColors.white.withValues(alpha: 0.1),
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class SplashLogoTile extends StatelessWidget {
  const SplashLogoTile({super.key});

  @override
  Widget build(BuildContext context) {
    final double tileSize = AppSpacing.x2l * 4;
    final double badgeSize = AppSpacing.x2l;

    return SizedBox(
      width: tileSize.w,
      height: tileSize.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.lightGreen, AppColors.primary],
              ),
              borderRadius: AppBorderRadius.card,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.2),
                  blurRadius: AppSpacing.lg.r,
                  offset: Offset(0, AppSpacing.sm.h),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                AppAssets.leaf,
                width: (AppSpacing.x2l * 2).w,
                height: (AppSpacing.x2l * 2).w,
                colorFilter: const ColorFilter.mode(
                  AppColors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: AppSpacing.md.h,
            right: AppSpacing.md.w,
            child: SvgPicture.asset(
              AppAssets.wayicon,
              width: badgeSize.w,
              height: badgeSize.w,
            ),
          ),
        ],
      ),
    );
  }
}
