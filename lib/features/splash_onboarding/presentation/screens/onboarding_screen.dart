import 'package:agrisenseaiapp/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/injection_container.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/system_utils.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_control_widgets.dart';
import '../widgets/onboarding_visual_widgets.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OnboardingProvider>(
      create: (_) => di<OnboardingProvider>(),
      child: const _OnboardingScreenContent(),
    );
  }
}

class _OnboardingScreenContent extends StatefulWidget {
  const _OnboardingScreenContent();

  @override
  State<_OnboardingScreenContent> createState() =>
      _OnboardingScreenContentState();
}

class _OnboardingScreenContentState extends State<_OnboardingScreenContent> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    SystemUtils.enableFullScreen();
    SystemUtils.setCustomSystemUI(
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      navigationBarColor: Colors.white,
      navigationBarIconBrightness: Brightness.dark,
    );
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeOnboarding();
      }
    });
  }

  Future<void> _initializeOnboarding() async {
    final provider =
        Provider.of<OnboardingProvider>(context, listen: false);
    await provider.initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemUtils.disableFullScreen();
    SystemUtils.setDefaultSystemUI();
    super.dispose();
  }

  void _handlePageChanged(int index) {
    final provider =
        Provider.of<OnboardingProvider>(context, listen: false);
    provider.goToPage(index);
  }

  void _handleSkip() {
    context.go(RouteNames.auth);
  }

  void _handleCta() {
    final provider =
        Provider.of<OnboardingProvider>(context, listen: false);
    if (provider.hasNextPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      context.go(RouteNames.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double skipPadding = AppSpacing.x2l;
    final double contentHorizontalPadding = AppSpacing.x2l + AppSpacing.sm;
    final double contentTopPadding = AppSpacing.lg;
    final double footerHorizontalPadding = contentHorizontalPadding;
    final double footerTopPadding = AppSpacing.x2l + AppSpacing.sm;
    final double footerBottomPadding = AppSpacing.x2l + AppSpacing.lg;
    final double footerGap = AppSpacing.x2l + AppSpacing.sm;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Consumer<OnboardingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.pages.isEmpty) {
            return Center(
              child: Text('No onboarding pages available', style: context.textTheme.bodyMedium),
            );
          }

          final currentPage = provider.currentPage;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: skipPadding.w,
                  vertical: skipPadding.h,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OnboardingSkipButton(
                    isVisible: currentPage?.showSkip ?? false,
                    onPressed: _handleSkip,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    contentHorizontalPadding.w,
                    contentTopPadding.h,
                    contentHorizontalPadding.w,
                    0,
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: provider.pages.length,
                    onPageChanged: _handlePageChanged,
                    itemBuilder: (context, index) {
                      final page = provider.pages[index];
                      return OnboardingPageContent(
                        title: page.title,
                        description: page.description,
                        illustration: _getIllustrationVariant(
                          page.illustrationType,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  footerHorizontalPadding.w,
                  footerTopPadding.h,
                  footerHorizontalPadding.w,
                  footerBottomPadding.h,
                ),
                child: Column(
                  children: [
                    OnboardingPagerIndicator(
                      currentIndex: provider.currentPageIndex,
                      total: provider.totalPages,
                    ),
                    SizedBox(height: footerGap.h),
                    OnboardingPrimaryButton(
                      label: currentPage?.ctaLabel ?? 'Next',
                      iconAsset: currentPage?.ctaIcon ?? '',
                      onPressed: _handleCta,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  OnboardingIllustrationVariant _getIllustrationVariant(
    String illustrationType,
  ) {
    return switch (illustrationType) {
      'monitor' => OnboardingIllustrationVariant.monitor,
      'automate' => OnboardingIllustrationVariant.automate,
      'insights' => OnboardingIllustrationVariant.insights,
      _ => OnboardingIllustrationVariant.monitor,
    };
  }
}
