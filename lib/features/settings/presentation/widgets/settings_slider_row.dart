import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';

/// A two-thumb threshold editor for one sensor's Normal range.
class SettingsSliderRow extends StatelessWidget {
  const SettingsSliderRow({
    super.key,
    required this.title,
    required this.values,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
    required this.onChangeEnd,
    this.divisions,
    this.activeColor = AppColors.primary,
  });

  final String title;
  final RangeValues values;
  final double min;
  final double max;
  final String unit;
  final int? divisions;
  final ValueChanged<RangeValues> onChanged;
  final ValueChanged<RangeValues> onChangeEnd;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        (context.textTheme.titleSmall ?? AppTextStyles.titleSmall).copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        SizedBox(height: AppSpacing.sm.h),
        Row(
          children: [
            Expanded(
              child: _ThresholdValue(
                label: 'Minimum Threshold',
                value: _format(values.start),
                unit: unit,
                color: activeColor,
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: _ThresholdValue(
                label: 'Maximum Threshold',
                value: _format(values.end),
                unit: unit,
                color: activeColor,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm.h),
        SliderTheme(
          data: context.theme.sliderTheme.copyWith(
            trackHeight: AppSpacing.sm.h,
            activeTrackColor: activeColor,
            inactiveTrackColor: AppColors.border,
            rangeThumbShape: RoundRangeSliderThumbShape(
              enabledThumbRadius: AppSpacing.md.r,
            ),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: divisions,
            labels: RangeLabels(
              '${_format(values.start)}$unit',
              '${_format(values.end)}$unit',
            ),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }

  String _format(double value) {
    if (value.abs() >= 1000) {
      return value.round().toString();
    }
    final double rounded = (value * 10).roundToDouble() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.round().toString()
        : rounded.toStringAsFixed(1);
  }
}

class _ThresholdValue extends StatelessWidget {
  const _ThresholdValue({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.sm.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.s12.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (context.textTheme.labelSmall ?? AppTextStyles.labelSmall)
                .copyWith(color: AppColors.textSecondary, fontSize: 9.sp),
          ),
          SizedBox(height: AppSpacing.xs.h),
          Text(
            '$value$unit',
            style: (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium)
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
