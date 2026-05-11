import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';

class OnboardingSkipButton extends StatelessWidget {
  const OnboardingSkipButton({
    super.key,
    required this.isVisible,
    this.onPressed,
  });

  final bool isVisible;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle =
        (context.textTheme.labelLarge ?? AppTextStyles.labelLarge)
            .copyWith(color: AppColors.textTertiary);

    return Visibility(
      visible: isVisible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text('Skip', style: textStyle),
      ),
    );
  }
}

class OnboardingPagerIndicator extends StatelessWidget {
  const OnboardingPagerIndicator({
    super.key,
    required this.currentIndex,
    required this.total,
  });

  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final bool isActive = index == currentIndex;
        final double width =
            isActive ? AppSpacing.x2l.w : AppSpacing.sm.w;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: (AppSpacing.sm / 2).w),
          width: width,
          height: AppSpacing.sm.h,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: AppBorderRadius.chip,
          ),
        );
      }),
    );
  }
}

class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.iconAsset,
    this.onPressed,
  });

  final String label;
  final String iconAsset;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle =
        (context.textTheme.bodyLarge ?? AppTextStyles.bodyLarge).copyWith(
      color: AppColors.white,
      fontWeight: FontWeight.w500,
    );
    final double height = (AppSpacing.x2l * 2) + (AppSpacing.sm / 2);
    final double iconSize = AppSpacing.lg + (AppSpacing.sm / 4);

    return SizedBox(
      width: double.infinity,
      height: height.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 3,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shadowColor: AppColors.primaryTint30,
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.button),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label, style: textStyle),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm.w),
                  child: SvgPicture.asset(
                    iconAsset,
                    width: iconSize.w,
                    height: iconSize.w,
                    colorFilter: const ColorFilter.mode(
                      AppColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
