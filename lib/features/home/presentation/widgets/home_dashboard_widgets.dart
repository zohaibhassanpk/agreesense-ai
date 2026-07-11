import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/bottom sheets/custom_bottom_sheets.dart';
import '../../../../core/widgets/snackbars/custom_snackbars.dart';
import '../../domain/entities/sensor_reading.dart';
import '../../domain/entities/smart_action.dart';
import '../providers/home_provider.dart';
import 'home_color_resolver.dart';

class HomeSmartActionCard extends StatelessWidget {
  const HomeSmartActionCard({super.key, required this.action});

  final SmartAction action;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        context.textTheme.titleLarge ?? AppTextStyles.titleLarge;
    final TextStyle bodyStyle =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
          color: AppColors.textSecondary,
        );

    return Container(
      constraints: BoxConstraints(minHeight: (AppSpacing.x2l * 2.8).h),
      padding: EdgeInsets.all(AppSpacing.md.r),
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
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm.h),
            child: SvgPicture.asset(
              AppAssets.shine,
              width: AppSpacing.x2l.w,
              height: AppSpacing.x2l.w,
              colorFilter: const ColorFilter.mode(
                AppColors.accentBlue,
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.lg.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.title, style: titleStyle),
                SizedBox(height: (AppSpacing.sm / 2).h),
                Text.rich(
                  TextSpan(
                    style: bodyStyle,
                    children: [
                      TextSpan(text: action.message),
                      TextSpan(
                        text: action.highlight,
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

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({super.key, required this.updatedLabel});

  final String updatedLabel;

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
        Text(updatedLabel, style: timeStyle),
      ],
    );
  }
}

class HomeSensorCard extends StatelessWidget {
  const HomeSensorCard({super.key, required this.sensor});

  final SensorReading sensor;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = HomeColorResolver.byKey(sensor.iconColorKey);
    final Color statusColor = HomeColorResolver.byKey(sensor.statusColorKey);
    final TextStyle labelStyle =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        );
    final TextStyle valueStyle =
        (context.textTheme.displaySmall ?? AppTextStyles.displaySmall).copyWith(
          letterSpacing: 0,
        );
    final TextStyle unitStyle =
        (context.textTheme.titleLarge ?? AppTextStyles.titleLarge).copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        );

    return Container(
      padding: EdgeInsets.all(AppSpacing.md.r),
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
            child: _SensorStatusDot(color: statusColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                height: AppSpacing.x2l.h,
                child: SvgPicture.asset(
                  sensor.icon,
                  width: AppSpacing.xl.w,
                  height: AppSpacing.xl.w,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
              const Spacer(),
              Text(sensor.label, style: labelStyle),
              SizedBox(height: (AppSpacing.sm / 2).h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(sensor.value, style: valueStyle),
                  SizedBox(width: (AppSpacing.sm / 2).w),
                  Padding(
                    padding: EdgeInsets.only(bottom: (AppSpacing.sm / 2).h),
                    child: Text(sensor.unit, style: unitStyle),
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

class _SensorStatusDot extends StatelessWidget {
  const _SensorStatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.sm.w,
      height: AppSpacing.sm.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: color == AppColors.accentYellow
            ? [
                BoxShadow(
                  color: AppColors.accentYellow.withValues(alpha: 0.5),
                  blurRadius: AppSpacing.sm.r,
                ),
              ]
            : null,
      ),
    );
  }
}

class HomeActionButton extends StatelessWidget {
  const HomeActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isActive = false,
  });

  final String label;
  final String icon;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = isActive
        ? AppColors.primary
        : AppColors.darkGreen;
    final TextStyle labelStyle =
        (context.textTheme.titleMedium ?? AppTextStyles.titleMedium).copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        );

    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive
              ? AppColors.primaryTint20
              : AppColors.surface,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
          side: BorderSide(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.s16.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: AppSpacing.x2l.w,
              height: AppSpacing.x2l.w,
              colorFilter: ColorFilter.mode(foregroundColor, BlendMode.srcIn),
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

class HomeWaterLogsSheet extends StatelessWidget {
  const HomeWaterLogsSheet({super.key});

  static Future<void> show({required BuildContext context}) {
    return CustomBottomSheet.show<void>(
      context: context,
      child: const HomeWaterLogsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        context.textTheme.titleMedium ?? AppTextStyles.titleMedium;
    final TextStyle subtitleStyle =
        (context.textTheme.bodySmall ?? AppTextStyles.bodySmall).copyWith(
          color: AppColors.textTertiary,
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x2l.w,
        AppSpacing.lg.h,
        AppSpacing.x2l.w,
        AppSpacing.x2l.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Water Logs', style: titleStyle),
          SizedBox(height: (AppSpacing.sm / 2).h),
          Text('Last 7 days', style: subtitleStyle),
          SizedBox(height: AppSpacing.lg.h),
          _WaterLogTile(
            title: 'Morning drip cycle',
            subtitle: 'Today • 07:30 AM',
            amount: '18 L',
            status: 'Completed',
            statusColor: AppColors.primary,
          ),
          _WaterLogTile(
            title: 'Auto irrigation',
            subtitle: 'Yesterday • 06:50 AM',
            amount: '22 L',
            status: 'Completed',
            statusColor: AppColors.primary,
          ),
          _WaterLogTile(
            title: 'Field recharge',
            subtitle: 'May 9 • 05:15 PM',
            amount: '12 L',
            status: 'Completed',
            statusColor: AppColors.primary,
          ),
          _WaterLogTile(
            title: 'Manual test run',
            subtitle: 'May 8 • 03:40 PM',
            amount: '5 L',
            status: 'Paused',
            statusColor: AppColors.accentYellow,
          ),
        ],
      ),
    );
  }
}

class _WaterLogTile extends StatelessWidget {
  const _WaterLogTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.statusColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium;
    final TextStyle subtitleStyle =
        (context.textTheme.bodySmall ?? AppTextStyles.bodySmall).copyWith(
          color: AppColors.textTertiary,
        );
    final TextStyle amountStyle =
        (context.textTheme.titleMedium ?? AppTextStyles.titleMedium).copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        );
    final TextStyle statusStyle =
        (context.textTheme.labelMedium ?? AppTextStyles.labelMedium).copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        );

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md.h),
      padding: EdgeInsets.all(AppSpacing.md.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: (AppSpacing.x2l + AppSpacing.sm).w,
            height: (AppSpacing.x2l + AppSpacing.sm).w,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppBorderRadius.s12.r),
            ),
            child: Center(
              child: SvgPicture.asset(
                AppAssets.timeRefresh,
                width: AppSpacing.xl.w,
                height: AppSpacing.xl.w,
                colorFilter: ColorFilter.mode(statusColor, BlendMode.srcIn),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                SizedBox(height: (AppSpacing.sm / 2).h),
                Text(subtitle, style: subtitleStyle),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: amountStyle),
              SizedBox(height: (AppSpacing.sm / 2).h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm.w,
                  vertical: (AppSpacing.sm / 2).h,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppBorderRadius.s12.r),
                ),
                child: Text(status, style: statusStyle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomePumpControlSheet extends StatelessWidget {
  const HomePumpControlSheet({super.key, required this.fallbackPumpOn});

  /// Value to show until the provider (watched live below) has one of its
  /// own; keeps the initial paint in sync with the button behind the sheet.
  final bool fallbackPumpOn;

  static Future<void> show({
    required BuildContext context,
    required HomeProvider provider,
  }) {
    return CustomBottomSheet.show<void>(
      context: context,
      child: ChangeNotifierProvider<HomeProvider>.value(
        value: provider,
        child: HomePumpControlSheet(
          fallbackPumpOn: provider.dashboard?.pumpOn ?? false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeProvider provider = context.watch<HomeProvider>();
    final bool isPumpOn = provider.dashboard?.pumpOn ?? fallbackPumpOn;
    final TextStyle titleStyle =
        context.textTheme.titleMedium ?? AppTextStyles.titleMedium;

    Future<void> handleTap(bool turnOn) async {
      Navigator.of(context).pop();
      final bool success = await provider.setPumpStatus(turnOn);
      if (!success && context.mounted) {
        CustomSnackbar.show(
          context: context,
          message: 'Could not update pump. Check your connection.',
          type: SnackbarType.error,
        );
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x2l.w,
        AppSpacing.lg.h,
        AppSpacing.x2l.w,
        AppSpacing.x2l.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pump Control', style: titleStyle),
          SizedBox(height: AppSpacing.md.h),
          _PumpActionTile(
            label: 'Turn On',
            icon: AppAssets.pump,
            color: AppColors.darkGreen,
            isSelected: isPumpOn,
            onTap: () => handleTap(true),
          ),
          _PumpActionTile(
            label: 'Turn Off',
            icon: AppAssets.pump,
            color: AppColors.error,
            isSelected: !isPumpOn,
            onTap: () => handleTap(false),
          ),
        ],
      ),
    );
  }
}

class _PumpActionTile extends StatelessWidget {
  const _PumpActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
    required this.isSelected,
  });

  final String label;
  final String icon;
  final VoidCallback onTap;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
          color: color,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        );
    final Color highlightColor = color.withValues(alpha: 0.12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.s16.r),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? highlightColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppBorderRadius.s16.r),
        ),
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.sm.h,
          horizontal: AppSpacing.sm.w,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: AppSpacing.x2l.w,
              height: AppSpacing.x2l.w,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(child: Text(label, style: labelStyle)),
          ],
        ),
      ),
    );
  }
}
