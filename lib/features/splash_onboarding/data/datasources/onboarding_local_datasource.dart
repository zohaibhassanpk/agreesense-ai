import '../models/onboarding_page_model.dart';

/// Local data source for onboarding pages.
/// Contains hardcoded onboarding data.
abstract class OnboardingLocalDataSource {
  /// Fetches all onboarding pages from local storage.
  Future<List<OnboardingPageModel>> getAllPages();

  /// Fetches a single onboarding page by [pageId].
  Future<OnboardingPageModel?> getPageById(String pageId);

  /// Gets the total number of onboarding pages.
  Future<int> getTotalPages();
}

/// Concrete implementation of [OnboardingLocalDataSource].
class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  /// Hardcoded onboarding pages data.
  static final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      id: '1',
      title: 'Monitor Your Farm',
      description:
          'Keep track of soil moisture, temperature, and environment in '
          'real-time, right from your phone.',
      illustrationType: 'monitor',
      order: 0,
      ctaLabel: 'Next',
      ctaIcon: 'assets/svgs/forward_arrow.svg',
      showSkip: true,
    ),
    OnboardingPageModel(
      id: '2',
      title: 'Automate Irrigation',
      description:
          'Set thresholds and let our smart algorithms handle water '
          'distribution to save resources.',
      illustrationType: 'automate',
      order: 1,
      ctaLabel: 'Next',
      ctaIcon: 'assets/svgs/forward_arrow.svg',
      showSkip: true,
    ),
    OnboardingPageModel(
      id: '3',
      title: 'AI Crop Insights',
      description:
          'Get predictive analytics and data-driven farming insights using '
          'our advanced sensor algorithms.',
      illustrationType: 'insights',
      order: 2,
      ctaLabel: 'Get Started',
      ctaIcon: 'assets/svgs/rocket.svg',
      showSkip: false,
    ),
  ];

  @override
  Future<List<OnboardingPageModel>> getAllPages() async {
    return Future.value(_pages);
  }

  @override
  Future<OnboardingPageModel?> getPageById(String pageId) async {
    try {
      return Future.value(_pages.firstWhere((page) => page.id == pageId));
    } catch (_) {
      return Future.value(null);
    }
  }

  @override
  Future<int> getTotalPages() async {
    return Future.value(_pages.length);
  }
}
