import 'custom_image_widget.dart';
import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../extensions/widget_extensions.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/responsive_extension.dart';

class SettingsListTileWidget extends StatelessWidget {
  const SettingsListTileWidget({
    super.key,
    this.icon,
    required this.title,
    required this.onTap,
    this.isArrowVisible = true,
    this.color,
    this.contentPadding,
  });
  final String? icon;
  final String title;
  final VoidCallback onTap;
  final bool? isArrowVisible;
  final Color? color;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: contentPadding ?? EdgeInsets.zero,
      leading: icon == null
          ? null
          : CustomImage(
                  image: icon!,
                  color: color ?? context.colorScheme.primary,
                  height: 25.w,
                  width: 25.w,
                )
                .paddingAll(5.w)
                .decorated(
                  color: (AppColors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
      title: Text(title, style: context.textTheme.bodyMedium),
      trailing: isArrowVisible == true
          ? Transform.flip(
              flipX: true,
              child: CustomImage(
                image: 'AppAssets.arrow',
                color: AppColors.black,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
