import 'package:agrisenseaiapp/features/home/data/datasources/home_local_datasource.dart';
import 'package:agrisenseaiapp/features/home/data/repositories/home_repository_impl.dart';
import 'package:agrisenseaiapp/features/home/presentation/providers/home_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home provider loads dashboard', () async {
    final provider = HomeProvider(
      repository: HomeRepositoryImpl(
        localDataSource: HomeLocalDataSourceImpl(),
      ),
    );
    await provider.loadDashboard();
    expect(provider.dashboard, isNotNull);
  });
}
