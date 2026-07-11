import 'package:flutter/material.dart';

import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'settings_slider_row.dart';

class SettingsThresholdCard extends StatelessWidget {
  const SettingsThresholdCard({
    super.key,
    required this.minMoisture,
    required this.maxTemperature,
    required this.onMinMoistureChanged,
    required this.onMaxTemperatureChanged,
  });

  final double minMoisture;
  final double maxTemperature;
  final ValueChanged<double> onMinMoistureChanged;
  final ValueChanged<double> onMaxTemperatureChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.r),
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
          SettingsSliderRow(
            title: 'Min. Moisture Level',
            valueLabel: '${minMoisture.toStringAsFixed(0)}%',
            value: minMoisture,
            min: 0,
            max: 100,
            onChanged: onMinMoistureChanged,
          ),
          SizedBox(height: AppSpacing.lg.h),
          SettingsSliderRow(
            title: 'Max. Temperature',
              valueLabel: '${maxTemperature.toStringAsFixed(0)}\u00B0C',
            value: maxTemperature,
            min: 0,
            max: 50,
            activeColor: AppColors.error,
            onChanged: onMaxTemperatureChanged,
          ),
        ],
      ),
    );
  }
}
