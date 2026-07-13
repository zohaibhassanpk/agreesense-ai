import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';

class SettingsSliderRow extends StatelessWidget {
  const SettingsSliderRow({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
    this.activeColor = AppColors.primary,
  });

  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        );
    final TextStyle valueStyle =
        (context.textTheme.labelSmall ?? AppTextStyles.labelSmall).copyWith(
          color: activeColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: titleStyle)),
            Text(valueLabel, style: valueStyle),
          ],
        ),
        SizedBox(height: AppSpacing.sm.h),
        SliderTheme(
          data: context.theme.sliderTheme.copyWith(
            trackHeight: (AppSpacing.sm).h,
            activeTrackColor: activeColor,
            inactiveTrackColor: AppColors.border,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: AppSpacing.md.r,
            ),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
}
