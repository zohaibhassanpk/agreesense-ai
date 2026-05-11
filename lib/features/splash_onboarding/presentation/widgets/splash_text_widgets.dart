import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';

class SplashTitle extends StatelessWidget {
  const SplashTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle =
        (context.textTheme.displayLarge ?? AppTextStyles.displayLarge)
            .copyWith(color: AppColors.white);

    return Text.rich(
      TextSpan(
        text: 'AgriSense',
        style: baseStyle,
        children: [
          TextSpan(
            text: 'AI',
            style: baseStyle.copyWith(color: AppColors.accentBlue),
          ),
        ],
      ),
    );
  }
}

class SplashTagline extends StatelessWidget {
  const SplashTagline({super.key});

  static const double _letterSpacing = 1.2;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle =
        (context.textTheme.labelLarge ?? AppTextStyles.labelLarge)
            .copyWith(
      color: AppColors.white.withValues(alpha: 0.8),
      letterSpacing: _letterSpacing,
    );

    return Text(
      'SMART FARMING WITH AI',
      textAlign: TextAlign.center,
      style: baseStyle,
    );
  }
}

class SplashPagerDots extends StatelessWidget {
  const SplashPagerDots({super.key, required this.animations});

  final List<Animation<double>> animations;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PulseDot(animation: animations[0], color: AppColors.white),
        AppSpacing.sm.wt,
        _PulseDot(
          animation: animations[1],
          color: AppColors.white.withValues(alpha: 0.6),
        ),
        AppSpacing.sm.wt,
        _PulseDot(
          animation: animations[2],
          color: AppColors.white.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double scale = 0.9 + (0.1 * animation.value);
        final double opacity = 0.6 + (0.4 * animation.value);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Container(
        width: AppSpacing.sm.r,
        height: AppSpacing.sm.r,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
