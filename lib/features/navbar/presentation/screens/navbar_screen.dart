import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../alerts/presentation/screens/alerts_screen.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../providers/navbar_provider.dart';
import '../widgets/navbar_bottom_bar.dart';

class NavbarScreen extends StatelessWidget {
  const NavbarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavbarProvider(),
      child: const _NavbarView(),
    );
  }
}

class _NavbarView extends StatelessWidget {
  const _NavbarView();

  static const List<Widget> _pages = [
    HomeScreen(),
    AlertsScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NavbarProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: IndexedStack(index: provider.selectedIndex, children: _pages),
          bottomNavigationBar: NavbarBottomBar(
            selectedIndex: provider.selectedIndex,
            onTabSelected: provider.selectTab,
          ),
        );
      },
    );
  }
}
