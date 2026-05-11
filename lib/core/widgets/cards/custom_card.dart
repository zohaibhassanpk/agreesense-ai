import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../extensions/widget_extensions.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/responsive_extension.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool hasShadow;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? margin;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.hasShadow = true,
    this.onLongPress,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child:
          Container(
                padding: padding ?? EdgeInsets.all(16.r),
                margin: margin,
                child: child,
              )
              .inkWell(onTap: onTap ?? () {})
              .decorated(
                color: color ?? context.theme.cardColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF404040)
                      : const Color(0xFFE5E5E5),
                  width: 1,
                ),
              ),
    );
  }
}
