import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/responsive_extension.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;

  const CustomFloatingActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label!,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: backgroundColor ?? context.colorScheme.primary,
        foregroundColor: foregroundColor ?? AppColors.white,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? context.colorScheme.primary,
      foregroundColor: foregroundColor ?? AppColors.white,
      child: Icon(icon),
    );
  }
}
