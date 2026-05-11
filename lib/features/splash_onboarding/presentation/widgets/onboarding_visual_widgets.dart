import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';

enum OnboardingIllustrationVariant { monitor, automate, insights }

class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({
    super.key,
    required this.title,
    required this.description,
    required this.illustration,
  });

  final String title;
  final String description;
  final OnboardingIllustrationVariant illustration;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        (context.textTheme.displaySmall ?? AppTextStyles.displaySmall)
            .copyWith(color: AppColors.darkGreen);
    final TextStyle bodyStyle =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium)
            .copyWith(color: AppColors.textSecondary);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        OnboardingIllustration(variant: illustration),
        SizedBox(height: (AppSpacing.x2l + AppSpacing.lg).h),
        Text(
          title,
          textAlign: TextAlign.center,
          style: titleStyle,
        ),
        AppSpacing.md.ht,
        Text(
          description,
          textAlign: TextAlign.center,
          style: bodyStyle,
        ),
      ],
    );
  }
}

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key, required this.variant});

  final OnboardingIllustrationVariant variant;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case OnboardingIllustrationVariant.monitor:
        return const _MonitorIllustration();
      case OnboardingIllustrationVariant.automate:
        return const _AutomationIllustration();
      case OnboardingIllustrationVariant.insights:
        return const _InsightsIllustration();
    }
  }
}

class _MonitorIllustration extends StatelessWidget {
  const _MonitorIllustration();

  @override
  Widget build(BuildContext context) {
    final double cardSize = (AppSpacing.x2l * 3) + AppSpacing.sm;
    final double iconSize = AppSpacing.x2l + (AppSpacing.md / 2);
    const double leftRotation = -6 * math.pi / 180;
    const double rightRotation = 3 * math.pi / 180;

    return _IllustrationShell(
      accentColor: AppColors.lightGreen,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: leftRotation,
            child: _InfoCard(
              size: cardSize,
              iconAsset: AppAssets.temprature,
              label: '24°C',
              color: AppColors.primary,
              iconSize: iconSize,
            ),
          ),
          SizedBox(width: AppSpacing.lg.w),
          Transform.translate(
            offset: Offset(0, AppSpacing.x2l.h),
            child: Transform.rotate(
              angle: rightRotation,
              child: _InfoCard(
                size: cardSize,
                iconAsset: null,
                label: '45%',
                color: AppColors.accentBlue,
                iconSize: iconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutomationIllustration extends StatelessWidget {
  const _AutomationIllustration();

  @override
  Widget build(BuildContext context) {
    final double tileSize = AppSpacing.x2l * 4;
    final double badgeSize = AppSpacing.x2l + AppSpacing.sm;
    final double badgeIconSize = AppSpacing.md + (AppSpacing.sm / 2);

    return _IllustrationShell(
      accentColor: AppColors.accentBlue,
      child: SizedBox(
        width: tileSize.w,
        height: tileSize.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _IconCard(
              size: tileSize,
              iconAsset: AppAssets.drop,
              color: AppColors.accentBlue,
              iconSize: AppSpacing.x2l * 2,
              borderColor: AppColors.border,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: AppSpacing.md.r,
                  offset: Offset(0, AppSpacing.sm.h),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: _BadgeCircle(
                size: badgeSize,
                iconAsset: AppAssets.doubleCheak,
                iconSize: badgeIconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsIllustration extends StatelessWidget {
  const _InsightsIllustration();

  @override
  Widget build(BuildContext context) {
    final double tileSize = (AppSpacing.x2l * 3) + AppSpacing.sm;
    final double iconSize = AppSpacing.xl + AppSpacing.lg;

    return _IllustrationShell(
      accentColor: AppColors.accentYellow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconCard(
            size: tileSize,
            iconAsset: AppAssets.shine,
            color: AppColors.accentYellow,
            iconSize: iconSize,
            borderRadius: BorderRadius.circular(AppBorderRadius.s16),
            borderColor: AppColors.border,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: AppSpacing.sm.r,
                offset: Offset(0, (AppSpacing.sm / 2).h),
              ),
            ],
          ),
          AppSpacing.md.ht,
          const _InsightPill(),
        ],
      ),
    );
  }
}

class _IllustrationShell extends StatelessWidget {
  const _IllustrationShell({
    required this.accentColor,
    required this.child,
  });

  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double size = (AppSpacing.x2l * 10) + AppSpacing.lg;

    return SizedBox(
      width: size.w,
      height: size.w,
      child: Center(child: child),
    );
  }
}

// ignore: unused_element
class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.size,
    required this.iconAsset,
    required this.label,
    required this.color,
    this.iconSize,
  });

  final double size;
  final String? iconAsset;
  final String label;
  final Color color;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle =
        (context.textTheme.labelMedium ?? AppTextStyles.labelMedium)
            .copyWith(color: color);
    final double resolvedIconSize = iconSize ?? AppSpacing.x2l;

    return Container(
      width: size.w,
      height: size.w,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.s16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: AppSpacing.sm.r,
            offset: Offset(0, (AppSpacing.sm / 2).h),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconAsset != null) ...[
            SvgPicture.asset(
              iconAsset!,
              width: resolvedIconSize.w,
              height: resolvedIconSize.w,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            SizedBox(height: (AppSpacing.sm / 2).h),
          ],
          Text(label, style: labelStyle),
        ],
      ),
    );
  }
}

class _IconCard extends StatelessWidget {
  const _IconCard({
    required this.size,
    required this.iconAsset,
    required this.color,
    this.iconSize,
    this.borderRadius,
    this.boxShadow,
    this.borderColor,
  });

  final double size;
  final String iconAsset;
  final Color color;
  final double? iconSize;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final double resolvedIconSize = iconSize ?? AppSpacing.x2l;

    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius ?? AppBorderRadius.card,
        border: Border.all(color: borderColor ?? AppColors.borderLight),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.08),
                blurRadius: AppSpacing.md.r,
                offset: Offset(0, (AppSpacing.sm / 2).h),
              ),
            ],
      ),
      child: Center(
        child: SvgPicture.asset(
          iconAsset,
          width: resolvedIconSize.w,
          height: resolvedIconSize.w,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _BadgeCircle extends StatelessWidget {
  const _BadgeCircle({
    required this.size,
    required this.iconAsset,
    this.iconSize,
  });

  final double size;
  final String iconAsset;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final double resolvedIconSize = iconSize ?? AppSpacing.sm;

    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white,
          width: (AppSpacing.sm / 4).r,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: AppSpacing.sm.r,
            offset: Offset(0, (AppSpacing.sm / 2).h),
          ),
        ],
      ),
      child: Center(
        child: SvgPicture.asset(
          iconAsset,
          width: resolvedIconSize.w,
          height: resolvedIconSize.w,
          colorFilter: const ColorFilter.mode(
            AppColors.white,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class _InsightPill extends StatelessWidget {
  const _InsightPill();

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle =
        (context.textTheme.labelMedium ?? AppTextStyles.labelMedium)
            .copyWith(color: AppColors.textSecondary);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.w,
        vertical: AppSpacing.sm.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.chip,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: AppSpacing.sm.r,
            offset: Offset(0, (AppSpacing.sm / 2).h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppAssets.insight,
            width: AppSpacing.lg.w,
            height: AppSpacing.lg.w,
            colorFilter: const ColorFilter.mode(
              AppColors.primary,
              BlendMode.srcIn,
            ),
          ),
          AppSpacing.md.wt,
          Text('Maximize Yield', style: labelStyle),
        ],
      ),
    );
  }
}

