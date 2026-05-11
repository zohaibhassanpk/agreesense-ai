import 'package:flutter/material.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/responsive_extension.dart';

class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;

  const CustomTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.textColor,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18.sp), 6.ht],
          Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: fontSize ?? 14.sp,
              fontWeight: fontWeight ?? FontWeight.w600,
              color: textColor ?? context.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
