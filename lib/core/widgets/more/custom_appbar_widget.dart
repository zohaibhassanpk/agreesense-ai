import 'custom_image_widget.dart';
import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/responsive_extension.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget>? actions;
  final Color? backgroundColor, foregroundColor;
  final VoidCallback? onBackPressed;
  final double elevation;
  final bool centerTitle;
  final TextStyle? titleStyle;
  final bool showShadow;

  const CustomAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.showBackButton = false,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.onBackPressed,
    this.elevation = 6,
    this.centerTitle = true,
    this.titleStyle,
    this.showShadow = false,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showShadow
          ? BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: AppBar(
        centerTitle: centerTitle,
        backgroundColor:
            backgroundColor ?? context.theme.appBarTheme.backgroundColor,
        foregroundColor: foregroundColor ?? AppColors.white,
        leading: showBackButton
            ? IconButton(
                icon: CustomImage(
                  image: 'AppAssets.arrow',
                  color: foregroundColor ?? context.colorScheme.onSurface,
                ),
                onPressed:
                    onBackPressed ??
                    () {
                      if (context.canPop()) context.pop();
                    },
              )
            : null,
        title: title == null ? null : Text(title!, style: titleStyle),
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 10.h);
}
