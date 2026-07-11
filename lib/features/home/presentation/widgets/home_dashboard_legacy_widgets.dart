import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';

class HomeDashboardHeader extends StatelessWidget {
  const HomeDashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle welcomeStyle =
        (context.textTheme.labelMedium ?? AppTextStyles.labelMedium).copyWith(
      color: AppColors.textTertiary,
      letterSpacing: 0,
    );
    final TextStyle titleStyle =
        context.textTheme.headlineLarge ?? AppTextStyles.headingLarge;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x2l.w,
        AppSpacing.x2l.h,
        AppSpacing.x2l.w,
        AppSpacing.x2l.h,
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
                    Text('Welcome back', style: welcomeStyle),
                    SizedBox(height: (AppSpacing.sm / 2).h),
                    Text('My Tobacco Field', style: titleStyle),
                  ],
                ),
              ),
              const HomeProfileButton(),
            ],
          ),
          SizedBox(height: AppSpacing.x2l.h),
          const DeviceConnectionPill(),
        ],
      ),
    );
  }
}

class HomeProfileButton extends StatelessWidget {
  const HomeProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (AppSpacing.x2l * 2).w,
      height: (AppSpacing.x2l * 2).w,
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.asset(
          AppAssets.profile,
          width: AppSpacing.x2l.w,
          height: AppSpacing.x2l.w,
          colorFilter: const ColorFilter.mode(
            AppColors.darkGreen,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class DeviceConnectionPill extends StatelessWidget {
  const DeviceConnectionPill({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle =
        (context.textTheme.labelLarge ?? AppTextStyles.labelLarge).copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.w,
        vertical: AppSpacing.md.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.chip,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSpacing.md.w,
            height: AppSpacing.md.w,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Text('Device Connected (Bluetooth)', style: textStyle),
        ],
      ),
    );
  }
}

class SmartActionCard extends StatelessWidget {
  const SmartActionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        context.textTheme.titleLarge ?? AppTextStyles.titleLarge;
    final TextStyle bodyStyle =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
      color: AppColors.textSecondary,
    );

    return Container(
      padding: EdgeInsets.all(AppSpacing.x2l.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: AppSpacing.sm.r,
            offset: Offset(0, (AppSpacing.sm / 2).h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            AppAssets.shine,
            width: AppSpacing.x2l.w,
            height: AppSpacing.x2l.w,
            colorFilter: const ColorFilter.mode(
              AppColors.accentBlue,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: AppSpacing.x2l.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart Action', style: titleStyle),
                SizedBox(height: AppSpacing.sm.h),
                Text.rich(
                  TextSpan(
                    style: bodyStyle,
                    children: [
                      const TextSpan(
                        text: 'Soil is drying faster than usual.\n'
                            'Irrigation needed in approx ',
                      ),
                      TextSpan(
                        text: '2 hours.',
                        style: bodyStyle.copyWith(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LiveSensorsHeader extends StatelessWidget {
  const LiveSensorsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        context.textTheme.titleLarge ?? AppTextStyles.titleLarge;
    final TextStyle timeStyle =
        (context.textTheme.bodySmall ?? AppTextStyles.bodySmall).copyWith(
      color: AppColors.textTertiary,
    );

    return Row(
      children: [
        Expanded(child: Text('Live Sensors', style: titleStyle)),
        Text('Updated 2m ago', style: timeStyle),
      ],
    );
  }
}

class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.statusColor,
  });

  final String label;
  final String value;
  final String unit;
  final String icon;
  final Color iconColor;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
    );
    final TextStyle valueStyle =
        (context.textTheme.displayMedium ?? AppTextStyles.displayMedium)
            .copyWith(letterSpacing: 0);
    final TextStyle unitStyle =
        (context.textTheme.titleLarge ?? AppTextStyles.titleLarge).copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
    );

    return Container(
      height: (AppSpacing.x2l * 6).h,
      padding: EdgeInsets.all(AppSpacing.x2l.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: AppSpacing.sm.r,
            offset: Offset(0, (AppSpacing.sm / 2).h),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: AppSpacing.md.w,
              height: AppSpacing.md.w,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: statusColor == AppColors.accentYellow
                    ? [
                        BoxShadow(
                          color: AppColors.accentYellow.withValues(alpha: 0.35),
                          blurRadius: AppSpacing.md.r,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SvgPicture.asset(
                icon,
                width: AppSpacing.x2l.w,
                height: AppSpacing.x2l.w,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              const Spacer(),
              Text(label, style: labelStyle),
              SizedBox(height: AppSpacing.sm.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value, style: valueStyle),
                  SizedBox(width: (AppSpacing.sm / 2).w),
                  Padding(
                    padding: EdgeInsets.only(bottom: (AppSpacing.sm / 2).h),
                    child: Text(unit, style: unitStyle),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardActionButton extends StatelessWidget {
  const DashboardActionButton({
    super.key,
    required this.label,
    required this.icon,
  });

  final String label;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle =
        (context.textTheme.titleMedium ?? AppTextStyles.titleMedium).copyWith(
      color: AppColors.darkGreen,
      fontWeight: FontWeight.w500,
    );

    return Expanded(
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.h),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.s16.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: AppSpacing.xl.w,
              height: AppSpacing.xl.w,
              colorFilter: const ColorFilter.mode(
                AppColors.darkGreen,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
            Flexible(
              child: Text(
                label,
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
