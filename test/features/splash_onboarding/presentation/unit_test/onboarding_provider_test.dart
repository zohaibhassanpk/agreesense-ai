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
  test('onboarding provider state transitions work', () async {
    final provider = OnboardingProvider(
      repository: OnboardingRepositoryImpl(
        localDataSource: OnboardingLocalDataSourceImpl(),
      ),
      localStorageService: _FakeLocalStorageService(),
    );
    await provider.initialize();
    provider.goToPage(2);
    expect(provider.currentPageIndex, 2);
  });
}
