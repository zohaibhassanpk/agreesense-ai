import '../entities/onboarding_page_entity.dart';

/// Abstract repository for onboarding data.
abstract class OnboardingRepository {
  /// Fetches all onboarding pages.
  Future<List<OnboardingPageEntity>> getAllPages();

  /// Fetches a single onboarding page by [pageId].
  Future<OnboardingPageEntity?> getPageById(String pageId);

  /// Fetches the total number of onboarding pages.
  Future<int> getTotalPages();
}
