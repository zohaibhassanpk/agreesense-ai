import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/system_utils.dart';
import '../widgets/splash_text_widgets.dart';
import '../widgets/splash_visual_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    SystemUtils.enableFullScreen();
    SystemUtils.setCustomSystemUI(
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      navigationBarColor: Colors.transparent,
      navigationBarIconBrightness: Brightness.light,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Navigate to onboarding screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go(RouteNames.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    SystemUtils.disableFullScreen();
    SystemUtils.setDefaultSystemUI();
    super.dispose();
  }

  Animation<double> _dotAnimation(double start) {
    return CurvedAnimation(
      parent: _pulseController,
      curve: Interval(start, start + 0.6, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double contentPadding = AppSpacing.x2l + AppSpacing.sm;
    final double topOffset = (AppSpacing.x2l * 3) + AppSpacing.sm;
    final double leftOffset = AppSpacing.x2l + AppSpacing.lg;
    final double bottomOffset = (AppSpacing.x2l * 2) + AppSpacing.lg;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.lightGreen, AppColors.primary],
          ),
        ),
        child: Stack(
          children: [
            SplashBackgroundIcon(
              asset: AppAssets.leaf,
              top: topOffset,
              left: leftOffset,
              size: (AppSpacing.x2l * 5) + AppSpacing.sm,
            ),
            SplashBackgroundIcon(
              asset: AppAssets.router,
              bottom: AppSpacing.x2l * 5 + AppSpacing.sm,
              right: leftOffset,
              size: AppSpacing.x2l * 4,
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: contentPadding.w,
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    const SplashLogoTile(),
                    AppSpacing.x2l.ht,
                    const SplashTitle(),
                    AppSpacing.sm.ht,
                    const SplashTagline(),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomOffset.h,
              child: SplashPagerDots(
                animations: [
                  _dotAnimation(0.0),
                  _dotAnimation(0.2),
                  _dotAnimation(0.4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
