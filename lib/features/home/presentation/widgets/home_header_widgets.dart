import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/providers/auth_session_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/home_dashboard.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.dashboard});

  final HomeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final TextStyle greetingStyle =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        );
    final TextStyle titleStyle =
        context.textTheme.displaySmall ?? AppTextStyles.displaySmall;

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dashboard.greeting, style: greetingStyle),
                    SizedBox(height: (AppSpacing.sm / 2).h),
                    Text(dashboard.fieldName, style: titleStyle),
                  ],
                ),
              ),
              const HomeProfileButton(),
            ],
          ),
          SizedBox(height: AppSpacing.xl.h),
          HomeConnectionPill(
            label: dashboard.connectionStatus,
            status: dashboard.deviceStatus,
          ),
        ],
      ),
    );
  }
}

class HomeProfileButton extends StatelessWidget {
  const HomeProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthSessionProvider>().user;
    final String? photoUrl = user?.photoUrl;

    return InkWell(
      onTap: () => context.push(RouteNames.profile),
      borderRadius: BorderRadius.circular(AppBorderRadius.circular.r),
      child: Container(
        width: (AppSpacing.x2l + AppSpacing.lg).w,
        height: (AppSpacing.x2l + AppSpacing.lg).w,
        decoration: const BoxDecoration(
          color: AppColors.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: Center(child: _ProfileAvatar(photoUrl: photoUrl)),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final double size = AppSpacing.x2l.w;
    final bool hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    if (!hasPhoto) {
      return SvgPicture.asset(
        AppAssets.profile,
        width: size,
        height: size,
        colorFilter: const ColorFilter.mode(
          AppColors.darkGreen,
          BlendMode.srcIn,
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return SvgPicture.asset(
            AppAssets.profile,
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(
              AppColors.darkGreen,
              BlendMode.srcIn,
            ),
          );
        },
      ),
    );
  }
}

class HomeConnectionPill extends StatelessWidget {
  const HomeConnectionPill({
    super.key,
    required this.label,
    this.status = DeviceStatus.unknown,
  });

  final String label;
  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final bool isChecking =
        status == DeviceStatus.unknown || status == DeviceStatus.loading;
    final Color statusColor = switch (status) {
      DeviceStatus.online => AppColors.primary,
      DeviceStatus.offline || DeviceStatus.error => AppColors.accentBrown,
      DeviceStatus.unknown || DeviceStatus.loading => AppColors.textTertiary,
    };
    final TextStyle labelStyle =
        (context.textTheme.labelLarge ?? AppTextStyles.labelLarge).copyWith(
          color: statusColor,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.w,
        vertical: AppSpacing.sm.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.chip,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isChecking)
            SizedBox(
              width: AppSpacing.md.w,
              height: AppSpacing.md.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            )
          else
            Container(
              width: AppSpacing.sm.w,
              height: AppSpacing.sm.w,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
          SizedBox(width: AppSpacing.md.w),
          Text(label, style: labelStyle),
        ],
      ),
    );
  }
}
