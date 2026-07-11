import 'package:get_it/get_it.dart';

import 'data/datasources/onboarding_local_datasource.dart';
import 'data/repositories/onboarding_repository_impl.dart';
import 'domain/repositories/onboarding_repository.dart';
import 'presentation/providers/onboarding_provider.dart';

class SplashOnboardingDI {
  void init(GetIt di) {
    // Data Sources
    di.registerLazySingleton<OnboardingLocalDataSource>(
      () => OnboardingLocalDataSourceImpl(),
    );

    // Repositories
    di.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(localDataSource: di()),
    );

    // Providers
    di.registerFactory<OnboardingProvider>(
      () => OnboardingProvider(
        repository: di(),
        localStorageService: di(),
      ),
    );
  }
}
