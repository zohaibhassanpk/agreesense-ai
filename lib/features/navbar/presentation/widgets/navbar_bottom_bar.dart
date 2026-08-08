import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/navbar_item.dart';
import 'navbar_item_widget.dart';

class NavbarBottomBar extends StatelessWidget {
  const NavbarBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  static const List<NavbarItem> items = [
    NavbarItem(
      label: 'Home',
      icon: AppAssets.home,
      selectedIcon: AppAssets.homeSelected,
    ),
    NavbarItem(
      label: 'Alerts',
      icon: AppAssets.alertIcon,
      selectedIcon: AppAssets.alertIconSelected,
    ),
    NavbarItem(
      label: 'Analytics',
      icon: AppAssets.analytics,
      selectedIcon: AppAssets.analyticsSelected,
    ),
    NavbarItem(
      label: 'Settings',
      icon: AppAssets.setting,
      selectedIcon: AppAssets.settingSelected,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg.w,
            (AppSpacing.sm / 2).h,
            AppSpacing.lg.w,
            0,
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              return NavbarItemWidget(
                item: items[index],
                isSelected: selectedIndex == index,
                showBadge: index == 1,
                onTap: () => onTabSelected(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}
