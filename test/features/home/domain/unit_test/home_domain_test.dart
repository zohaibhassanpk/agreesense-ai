import 'package:agrisenseaiapp/features/home/data/datasources/home_local_datasource.dart';
import 'package:agrisenseaiapp/features/home/data/repositories/home_repository_impl.dart';
import 'package:agrisenseaiapp/features/home/domain/entities/home_dashboard.dart';
import 'package:agrisenseaiapp/features/home/domain/repositories/home_repository.dart';
import 'package:agrisenseaiapp/features/home/presentation/providers/home_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingHomeRepo implements HomeRepository {
  @override
  Future<HomeDashboard> getDashboard() async {
    throw Exception('fail');
  }
}

void main() {
  group('Home Unit Tests', () {
    test('local datasource returns dashboard with sensor cards', () async {
      final source = HomeLocalDataSourceImpl();
      final dashboard = await source.getDashboard();
      expect(dashboard.fieldName, contains('Field'));
      expect(dashboard.sensors.length, 4);
    });

    test('repository forwards dashboard from datasource', () async {
      final repo = HomeRepositoryImpl(
        localDataSource: HomeLocalDataSourceImpl(),
      );
      final dashboard = await repo.getDashboard();
      expect(dashboard.smartAction.title, 'Smart Action');
    });

    test('provider loads dashboard state', () async {
      final provider = HomeProvider(
        repository: HomeRepositoryImpl(
          localDataSource: HomeLocalDataSourceImpl(),
        ),
      );
      await provider.loadDashboard();
      expect(provider.isLoading, isFalse);
      expect(provider.dashboard, isNotNull);
      expect(provider.errorMessage, isNull);
    });

    test('provider surfaces error when repo fails', () async {
      final provider = HomeProvider(repository: _FailingHomeRepo());
      await provider.loadDashboard();
      expect(provider.dashboard, isNull);
      expect(provider.errorMessage, 'Unable to load dashboard data.');
    });
  });
}
