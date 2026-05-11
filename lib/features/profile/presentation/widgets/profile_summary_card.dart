import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.displayName,
    required this.subtitle,
    required this.photoUrl,
  });

  final String displayName;
  final String subtitle;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final TextStyle subtitleStyle =
        (context.textTheme.bodySmall ?? AppTextStyles.bodySmall).copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        );
    final TextStyle titleStyle =
        context.textTheme.displaySmall ?? AppTextStyles.displaySmall;

    final double avatarSize = (AppSpacing.x2l * 3).w;

    return Container(
      padding: EdgeInsets.all(AppSpacing.xl.r),
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
      child: Column(
        children: [
          _ProfileAvatar(
            size: avatarSize,
            photoUrl: photoUrl,
          ),
          SizedBox(height: AppSpacing.lg.h),
          Text(subtitle, style: subtitleStyle),
          SizedBox(height: (AppSpacing.sm / 2).h),
          Text(displayName, style: titleStyle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.size, required this.photoUrl});

  final double size;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = photoUrl?.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ClipOval(
        child: imageUrl == null || imageUrl.isEmpty
            ? Center(
                child: SvgPicture.asset(
                  AppAssets.profile,
                  width: (AppSpacing.x2l + AppSpacing.md).w,
                  height: (AppSpacing.x2l + AppSpacing.md).w,
                  colorFilter: const ColorFilter.mode(
                    AppColors.darkGreen,
                    BlendMode.srcIn,
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (context, _, __) => Center(
                  child: SvgPicture.asset(
                    AppAssets.profile,
                    width: (AppSpacing.x2l + AppSpacing.md).w,
                    height: (AppSpacing.x2l + AppSpacing.md).w,
                    colorFilter: const ColorFilter.mode(
                      AppColors.darkGreen,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
