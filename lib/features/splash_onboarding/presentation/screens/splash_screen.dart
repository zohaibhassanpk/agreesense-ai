import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/injection_container.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/providers/auth_session_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/local_storage/local_storage_service.dart';
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
  late final AuthSessionProvider _authSessionProvider;
  late final LocalStorageService _localStorageService;
  Timer? _navigationTimer;
  VoidCallback? _authListener;

  @override
  void initState() {
    super.initState();
    _authSessionProvider = context.read<AuthSessionProvider>();
    _localStorageService = di<LocalStorageService>();
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

    _navigationTimer = Timer(const Duration(seconds: 3), _handleSplashComplete);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    if (_authListener != null) {
      _authSessionProvider.removeListener(_authListener!);
    }
    _pulseController.dispose();
    SystemUtils.disableFullScreen();
    SystemUtils.setDefaultSystemUI();
    super.dispose();
  }

  Future<void> _handleSplashComplete() async {
    if (!mounted) return;

    if (!_authSessionProvider.isReady) {
      _authListener = () {
        if (!_authSessionProvider.isReady || !mounted) return;
        _authSessionProvider.removeListener(_authListener!);
        _authListener = null;
        _navigateFromSplash();
      };
      _authSessionProvider.addListener(_authListener!);
      return;
    }

    await _navigateFromSplash();
  }

  Future<void> _navigateFromSplash() async {
    final String targetRoute;
    if (_authSessionProvider.isAuthenticated) {
      targetRoute = RouteNames.navbar;
    } else {
      final completed = await _localStorageService.getOnboardingCompleted();
      targetRoute = completed ? RouteNames.auth : RouteNames.onboarding;
    }

    if (!mounted) return;
    context.go(targetRoute);
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
                padding: EdgeInsets.symmetric(horizontal: contentPadding.w),
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
