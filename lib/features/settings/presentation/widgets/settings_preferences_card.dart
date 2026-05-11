import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import 'settings_navigation_row.dart';
import 'settings_toggle.dart';

class SettingsPreferencesCard extends StatelessWidget {
  const SettingsPreferencesCard({
    super.key,
    required this.pushNotificationsEnabled,
    required this.language,
    required this.onToggleNotifications,
  });

  final bool pushNotificationsEnabled;
  final String language;
  final ValueChanged<bool> onToggleNotifications;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );

    return Container(
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
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg.w,
              vertical: AppSpacing.lg.h,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Push Notifications', style: titleStyle),
                ),
                SettingsToggle(
                  value: pushNotificationsEnabled,
                  onChanged: onToggleNotifications,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderLight),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: SettingsNavigationRow(
              title: 'Language',
              value: language,
            ),
          ),
        ],
      ),
    );
  }
}
