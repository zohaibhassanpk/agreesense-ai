import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/navbar_item.dart';

class NavbarItemWidget extends StatelessWidget {
  const NavbarItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.showBadge = false,
  });

  final NavbarItem item;
  final bool isSelected;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected
        ? AppColors.navActive
        : AppColors.navInactive;
    final String icon = isSelected ? item.selectedIcon : item.icon;
    final TextStyle labelStyle = AppTextStyles.labelSmall.copyWith(
      color: color,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: (AppSpacing.sm / 2).h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    icon,
                    width: AppSpacing.x2l.w,
                    height: AppSpacing.x2l.w,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                  if (showBadge)
                    Positioned(
                      top: 0,
                      right: -1.w,
                      child: Container(
                        width: AppSpacing.sm.w,
                        height: AppSpacing.sm.w,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.w,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: (AppSpacing.sm / 2).h),
              Text(
                item.label,
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
