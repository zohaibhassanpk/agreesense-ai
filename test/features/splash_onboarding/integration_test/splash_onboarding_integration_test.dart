import 'package:agrisenseaiapp/features/splash_onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:agrisenseaiapp/features/splash_onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:agrisenseaiapp/core/services/local_storage/local_storage_service.dart';
import 'package:agrisenseaiapp/features/splash_onboarding/presentation/providers/onboarding_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SplashOnboarding Integration', () {
    testWidgets('initialize and navigate full page sequence', (tester) async {
      final provider = OnboardingProvider(
        repository: OnboardingRepositoryImpl(
          localDataSource: OnboardingLocalDataSourceImpl(),
        ),
        localStorageService: LocalStorageService(),
      );

      await provider.initialize();
      expect(provider.totalPages, 3);
      expect(provider.currentPageIndex, 0);

      while (provider.hasNextPage) {
        provider.nextPage();
      }

      expect(provider.currentPageIndex, 2);
      provider.reset();
      expect(provider.currentPageIndex, 0);
    });

    testWidgets('goToPage ignores invalid indexes', (tester) async {
      final provider = OnboardingProvider(
        repository: OnboardingRepositoryImpl(
          localDataSource: OnboardingLocalDataSourceImpl(),
        ),
        localStorageService: LocalStorageService(),
      );

      await provider.initialize();
      provider.goToPage(-1);
      expect(provider.currentPageIndex, 0);
      provider.goToPage(99);
      expect(provider.currentPageIndex, 0);
    });
  });
}
