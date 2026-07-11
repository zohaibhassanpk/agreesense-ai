import '../../domain/entities/onboarding_page_entity.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_datasource.dart';

/// Implementation of [OnboardingRepository].
class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl({required this.localDataSource});

  final OnboardingLocalDataSource localDataSource;

  @override
  Future<List<OnboardingPageEntity>> getAllPages() async {
    return localDataSource.getAllPages();
  }

  @override
  Future<OnboardingPageEntity?> getPageById(String pageId) async {
    return localDataSource.getPageById(pageId);
  }

  @override
  Future<int> getTotalPages() async {
    return localDataSource.getTotalPages();
  }
}
