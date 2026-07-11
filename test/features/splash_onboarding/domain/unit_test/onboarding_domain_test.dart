import 'package:agrisenseaiapp/features/splash_onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:agrisenseaiapp/features/splash_onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:agrisenseaiapp/features/splash_onboarding/presentation/providers/onboarding_provider.dart';
import 'package:agrisenseaiapp/core/services/local_storage/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLocalStorageService extends LocalStorageService {
  @override
  Future<bool> getOnboardingCompleted() async => false;

  @override
  Future<void> saveOnboardingCompleted(bool completed) async {}
}

void main() {
  group('SplashOnboarding Unit Tests', () {
    test('local datasource returns 3 ordered pages', () async {
      final source = OnboardingLocalDataSourceImpl();
      final pages = await source.getAllPages();

      expect(pages.length, 3);
      expect(pages.first.order, 0);
      expect(pages.last.ctaLabel, 'Get Started');
    });

    test('getPageById returns null for unknown id', () async {
      final source = OnboardingLocalDataSourceImpl();
      final page = await source.getPageById('404');
      expect(page, isNull);
    });

    test('repository delegates to datasource', () async {
      final repo = OnboardingRepositoryImpl(
        localDataSource: OnboardingLocalDataSourceImpl(),
      );
      final pages = await repo.getAllPages();
      expect(pages, isNotEmpty);
    });

    test('provider initializes and handles navigation', () async {
      final provider = OnboardingProvider(
        repository: OnboardingRepositoryImpl(
          localDataSource: OnboardingLocalDataSourceImpl(),
        ),
        localStorageService: _FakeLocalStorageService(),
      );

      await provider.initialize();
      expect(provider.isLoading, isFalse);
      expect(provider.totalPages, 3);
      expect(provider.currentPageIndex, 0);

      provider.nextPage();
      expect(provider.currentPageIndex, 1);
      provider.previousPage();
      expect(provider.currentPageIndex, 0);
      provider.goToPage(2);
      expect(provider.hasNextPage, isFalse);
      provider.reset();
      expect(provider.currentPageIndex, 0);
    });
  });
}
