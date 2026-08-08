import 'package:flutter/material.dart';

import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/services/settings/threshold_settings_service.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'settings_slider_row.dart';

class SettingsThresholdCard extends StatelessWidget {
  const SettingsThresholdCard({
    super.key,
    required this.temperatureRange,
    required this.humidityRange,
    required this.moistureRange,
    required this.lightRange,
    required this.onTemperatureChanged,
    required this.onTemperatureChangeEnd,
    required this.onHumidityChanged,
    required this.onHumidityChangeEnd,
    required this.onMoistureChanged,
    required this.onMoistureChangeEnd,
    required this.onLightChanged,
    required this.onLightChangeEnd,
  });

  final RangeValues temperatureRange;
  final RangeValues humidityRange;
  final RangeValues moistureRange;
  final RangeValues lightRange;
  final ValueChanged<RangeValues> onTemperatureChanged;
  final ValueChanged<RangeValues> onTemperatureChangeEnd;
  final ValueChanged<RangeValues> onHumidityChanged;
  final ValueChanged<RangeValues> onHumidityChangeEnd;
  final ValueChanged<RangeValues> onMoistureChanged;
  final ValueChanged<RangeValues> onMoistureChangeEnd;
  final ValueChanged<RangeValues> onLightChanged;
  final ValueChanged<RangeValues> onLightChangeEnd;

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
            title: 'Temperature',
            values: temperatureRange,
            min: ThresholdSettingsService.temperatureRangeMin,
            max: ThresholdSettingsService.temperatureRangeMax,
            divisions: 50,
            unit: '°C',
            activeColor: AppColors.error,
            onChanged: onTemperatureChanged,
            onChangeEnd: onTemperatureChangeEnd,
          ),
          _divider(),
          SettingsSliderRow(
            title: 'Humidity',
            values: humidityRange,
            min: ThresholdSettingsService.humidityRangeMin,
            max: ThresholdSettingsService.humidityRangeMax,
            divisions: 100,
            unit: '%',
            activeColor: AppColors.accentBlue,
            onChanged: onHumidityChanged,
            onChangeEnd: onHumidityChangeEnd,
          ),
          _divider(),
          SettingsSliderRow(
            title: 'Soil Moisture',
            values: moistureRange,
            min: ThresholdSettingsService.moistureRangeMin,
            max: ThresholdSettingsService.moistureRangeMax,
            divisions: 100,
            unit: '%',
            onChanged: onMoistureChanged,
            onChangeEnd: onMoistureChangeEnd,
          ),
          _divider(),
          SettingsSliderRow(
            title: 'Light Intensity',
            values: lightRange,
            min: ThresholdSettingsService.lightRangeMin,
            max: ThresholdSettingsService.lightRangeMax,
            divisions: 100,
            unit: ' lux',
            activeColor: AppColors.accentYellow,
            onChanged: onLightChanged,
            onChangeEnd: onLightChangeEnd,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
    child: const Divider(color: AppColors.borderLight, height: 1),
  );
}
