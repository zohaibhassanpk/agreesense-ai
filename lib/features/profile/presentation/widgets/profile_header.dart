import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        context.textTheme.headlineMedium ?? AppTextStyles.headingMedium;

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
      child: Row(
        children: [
          _ProfileBackButton(onTap: context.pop),
          SizedBox(width: AppSpacing.md.w),
          Expanded(child: Text(title, style: titleStyle)),
        ],
      ),
    );
  }
}

class _ProfileBackButton extends StatelessWidget {
  const _ProfileBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.s12.r),
      child: Container(
        width: (AppSpacing.x2l + AppSpacing.sm).w,
        height: (AppSpacing.x2l + AppSpacing.sm).w,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppBorderRadius.s12.r),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: AppSpacing.md.w,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
