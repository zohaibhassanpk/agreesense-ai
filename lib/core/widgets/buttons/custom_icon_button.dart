import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../extensions/widget_extensions.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/responsive_extension.dart';

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final String? tooltip;
  final BoxShape? shape;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.tooltip,
    this.shape = BoxShape.circle,
  });

  @override
  Widget build(BuildContext context) {
    final button =
        SizedBox(
          width: size ?? 35.w,
          height: size ?? 35.w,
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: iconColor ?? context.colorScheme.onSurface,
              size: 20.sp,
            ),
            padding: EdgeInsets.zero,
          ),
        ).decorated(
          color: backgroundColor ?? context.colorScheme.surface,
          borderRadius: shape == BoxShape.circle
              ? null
              : BorderRadius.circular(AppConstants.borderRadius),
          shape: shape ?? BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}