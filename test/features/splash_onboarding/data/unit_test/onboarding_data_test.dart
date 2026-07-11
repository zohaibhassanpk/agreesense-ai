import 'package:agrisenseaiapp/features/splash_onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:agrisenseaiapp/features/splash_onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onboarding datasource and repository return complete pages', () async {
    final ds = OnboardingLocalDataSourceImpl();
    final repo = OnboardingRepositoryImpl(localDataSource: ds);
    final pages = await repo.getAllPages();
    expect(pages.length, 3);
    expect(await repo.getTotalPages(), 3);
  });
}
