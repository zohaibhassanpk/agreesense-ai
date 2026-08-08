import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        (context.textTheme.labelMedium ?? AppTextStyles.labelMedium).copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 1.2.r,
        );

    return Text(label.toUpperCase(), style: style);
  }
}
