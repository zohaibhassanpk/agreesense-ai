import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/alert_item.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    this.isMuted = false,
  });

  final AlertItem alert;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _resolveAccentColor(alert.severity);
    final TextStyle titleStyle =
        (context.textTheme.titleMedium ?? AppTextStyles.titleMedium).copyWith(
      color: AppColors.textPrimary,
      letterSpacing: 0,
    );
    final TextStyle timeStyle =
        (context.textTheme.bodySmall ?? AppTextStyles.bodySmall).copyWith(
      color: AppColors.textTertiary,
    );
    final TextStyle bodyStyle =
        (context.textTheme.bodySmall ?? AppTextStyles.bodySmall).copyWith(
      color: AppColors.textSecondary,
    );

    final double iconContainerSize =
        (AppSpacing.x2l + AppSpacing.lg).w;

    final Widget card = Container(
      padding: EdgeInsets.all(AppSpacing.lg.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.s16.r),
        border: Border.all(color: _resolveBorderColor(alert.severity)),
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
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                alert.icon,
                width: AppSpacing.xl.w,
                height: AppSpacing.xl.w,
                colorFilter: ColorFilter.mode(
                  accentColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.lg.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(alert.title, style: titleStyle)),
                    SizedBox(width: AppSpacing.sm.w),
                    Text(alert.timeLabel, style: timeStyle),
                  ],
                ),
                SizedBox(height: (AppSpacing.sm / 2).h),
                Text(alert.message, style: bodyStyle),
              ],
            ),
          ),
        ],
      ),
    );

    if (!isMuted) {
      return card;
    }

    return Opacity(opacity: 0.75, child: card);
  }

  Color _resolveAccentColor(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.critical => AppColors.error,
      AlertSeverity.warning => AppColors.accentYellow,
      AlertSeverity.info => AppColors.primary,
    };
  }

  Color _resolveBorderColor(AlertSeverity severity) {
    if (severity == AlertSeverity.critical) {
      return AppColors.error.withValues(alpha: 0.2);
    }

    return AppColors.borderLight;
  }
}
