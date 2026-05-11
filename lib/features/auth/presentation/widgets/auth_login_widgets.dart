import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class AuthHeaderIcon extends StatelessWidget {
  const AuthHeaderIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final double containerSize = AppSpacing.x2l * 2;
    final double iconSize = AppSpacing.x2l;
    final Color primaryColor = context.colorScheme.primary;

    return Container(
      width: containerSize.w,
      height: containerSize.w,
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppBorderRadius.s12),
      ),
      child: Center(
        child: SvgPicture.asset(
          AppAssets.leaf,
          width: iconSize.w,
          height: iconSize.w,
          colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle =
        (context.textTheme.bodyMedium ?? const TextStyle()).copyWith(
          color: context.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.button,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: AppSpacing.sm.r,
            offset: Offset(0, (AppSpacing.sm / 2).h),
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: context.colorScheme.surface,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.x2l.w,
            vertical: AppSpacing.lg.h,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              AppAssets.google,
              width: AppSpacing.xl.w,
              height: AppSpacing.xl.w,
            ),
            AppSpacing.md.wt,
            Text('Continue with Google', style: labelStyle),
          ],
        ),
      ),
    );
  }
}

class AuthFooterText extends StatelessWidget {
  const AuthFooterText({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle =
        context.textTheme.bodySmall ?? const TextStyle();
    final TextStyle linkStyle = baseStyle.copyWith(
      color: context.colorScheme.primary,
      fontWeight: FontWeight.w500,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(text: 'Terms', style: linkStyle),
          const TextSpan(text: ' & '),
          TextSpan(text: 'Privacy', style: linkStyle),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
