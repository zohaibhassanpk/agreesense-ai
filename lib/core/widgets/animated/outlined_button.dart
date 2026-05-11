import '../loaders/custom_loader.dart';
import 'package:flutter/material.dart';
import '../more/custom_image_widget.dart';
import '../../extensions/widget_extensions.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/responsive_extension.dart';
import 'package:agrisenseaiapp/core/theme/app_colors.dart';

class CustomOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? icon;
  final Color? borderColor;
  final double? width;
  final double? height;
  final Color? iconColor;
  final TextStyle? textStyle;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<BoxShadow>? boxShadow;

  const CustomOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.borderColor,
    this.width,
    this.height,
    this.iconColor,
    this.textStyle,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor ?? AppColors.border),
          shape: borderRadius != null
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius!),
                )
              : null,
        ),
        child: isLoading
            ? CustomLoader(color: AppColors.primary)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    CustomImage(image: icon!, color: iconColor),
                    5.wt,
                  ],
                  5.wt,
                  Text(
                    text,
                    style:
                        textStyle ??
                        context.textTheme.bodyMedium?.copyWith(
                          color: foregroundColor ?? AppColors.textPrimary,
                        ),
                  ).flexible(),
                ],
              ),
      ).decorated(boxShadow: boxShadow),
    );
  }
}
