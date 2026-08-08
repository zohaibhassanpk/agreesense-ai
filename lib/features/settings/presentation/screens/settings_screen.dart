import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/injection_container.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/settings_dashboard.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_preferences_card.dart';
import '../widgets/settings_profile_card.dart';
import '../widgets/settings_section_label.dart';
import '../widgets/settings_threshold_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsProvider>(
      create: (_) => di<SettingsProvider>()..loadSettings(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        final SettingsDashboard? dashboard = provider.dashboard;

        if (provider.isLoading && dashboard == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && dashboard == null) {
          return _SettingsErrorState(message: provider.errorMessage!);
        }

        if (dashboard == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            const SettingsHeader(),
            Expanded(
              child: _SettingsBody(dashboard: dashboard, provider: provider),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.dashboard, required this.provider});

  final SettingsDashboard dashboard;
  final SettingsProvider provider;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl.w,
        AppSpacing.xl.h,
        AppSpacing.xl.w,
        AppSpacing.xl.h,
      ),
      children: [
        Padding(
          padding: EdgeInsets.only(left: AppSpacing.xs.w),
          child: const SettingsSectionLabel(label: 'Farm Profile'),
        ),
        SizedBox(height: AppSpacing.sm.h),
        SettingsProfileCard(
          selectedCrop: dashboard.selectedCrop,
          onTap: () => _showCropSelectorSheet(
            context,
            selectedCrop: dashboard.selectedCrop,
          ),
        ),
        SizedBox(height: AppSpacing.x2l.h),
        Padding(
          padding: EdgeInsets.only(left: AppSpacing.xs.w),
          child: const SettingsSectionLabel(label: 'Alert Thresholds'),
        ),
        SizedBox(height: AppSpacing.sm.h),
        SettingsThresholdCard(
          temperatureRange: RangeValues(
            provider.minTemperature,
            provider.maxTemperature,
          ),
          humidityRange: RangeValues(
            provider.minHumidity,
            provider.maxHumidity,
          ),
          moistureRange: RangeValues(
            provider.minMoisture,
            provider.maxMoisture,
          ),
          lightRange: RangeValues(provider.minLight, provider.maxLight),
          onTemperatureChanged: (RangeValues values) =>
              provider.updateTemperatureRange(values.start, values.end),
          onTemperatureChangeEnd: (RangeValues values) =>
              provider.commitTemperatureRange(values.start, values.end),
          onHumidityChanged: (RangeValues values) =>
              provider.updateHumidityRange(values.start, values.end),
          onHumidityChangeEnd: (RangeValues values) =>
              provider.commitHumidityRange(values.start, values.end),
          onMoistureChanged: (RangeValues values) =>
              provider.updateMoistureRange(values.start, values.end),
          onMoistureChangeEnd: (RangeValues values) =>
              provider.commitMoistureRange(values.start, values.end),
          onLightChanged: (RangeValues values) =>
              provider.updateLightRange(values.start, values.end),
          onLightChangeEnd: (RangeValues values) =>
              provider.commitLightRange(values.start, values.end),
        ),
        SizedBox(height: AppSpacing.x2l.h),
        Padding(
          padding: EdgeInsets.only(left: AppSpacing.xs.w),
          child: const SettingsSectionLabel(label: 'Preferences'),
        ),
        SizedBox(height: AppSpacing.sm.h),
        SettingsPreferencesCard(
          pushNotificationsEnabled: provider.pushNotificationsEnabled,
          language: dashboard.language,
          onToggleNotifications: provider.togglePushNotifications,
        ),
        SizedBox(height: AppSpacing.lg.h),
        _ClearLocalDataButton(
          isClearing: provider.isClearingLocalData,
          onPressed: provider.isClearingLocalData
              ? null
              : () async {
                  final bool success = await provider.clearLocalData();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Local data cleared. Settings restored.'
                            : 'Could not clear local data.',
                      ),
                    ),
                  );
                },
        ),
      ],
    );
  }
}

class _ClearLocalDataButton extends StatelessWidget {
  const _ClearLocalDataButton({
    required this.onPressed,
    required this.isClearing,
  });

  final VoidCallback? onPressed;
  final bool isClearing;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppBorderRadius.s16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.s16.r),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: AppSpacing.sm.r,
              offset: Offset(0, (AppSpacing.sm / 2).h),
            ),
          ],
        ),
        child: Center(
          child: Text(
            isClearing ? 'Clearing Local Data...' : 'Clear Local Data',
            style: textStyle,
          ),
        ),
      ),
    );
  }
}

class _SettingsErrorState extends StatelessWidget {
  const _SettingsErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
          color: AppColors.textSecondary,
        );

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.x2l.r),
        child: Text(message, style: style, textAlign: TextAlign.center),
      ),
    );
  }
}

void _showCropSelectorSheet(
  BuildContext context, {
  required String selectedCrop,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppBorderRadius.bottomSheet,
    ),
    builder: (sheetContext) {
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
            Center(
              child: Container(
                width: (AppSpacing.x2l * 2).w,
                height: (AppSpacing.xs).h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppBorderRadius.s12.r),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            Text(
              'Select Crop',
              style: context.textTheme.titleMedium ?? AppTextStyles.titleMedium,
            ),
            SizedBox(height: AppSpacing.md.h),
            _CropOption(
              label: 'Tobacco',
              isSelected: selectedCrop == 'Tobacco',
              enabled: true,
            ),
            _CropOption(label: 'Maize', isSelected: false, enabled: false),
            _CropOption(label: 'Wheat', isSelected: false, enabled: false),
          ],
        ),
      );
    },
  );
}

class _CropOption extends StatelessWidget {
  const _CropOption({
    required this.label,
    required this.isSelected,
    required this.enabled,
  });

  final String label;
  final bool isSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color textColor = enabled
        ? AppColors.textPrimary
        : AppColors.textTertiary;
    final TextStyle labelStyle =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
      child: Row(
        children: [
          Container(
            width: AppSpacing.lg.w,
            height: AppSpacing.lg.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
              color: isSelected ? AppColors.primary : AppColors.surface,
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: AppSpacing.xs.w,
                      height: AppSpacing.xs.w,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: AppSpacing.md.w),
          Text(label, style: labelStyle),
          if (!enabled) ...[
            SizedBox(width: AppSpacing.sm.w),
            Text(
              'Soon',
              style: (context.textTheme.labelSmall ?? AppTextStyles.labelSmall)
                  .copyWith(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
