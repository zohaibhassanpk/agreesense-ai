import 'package:agrisenseaiapp/features/home/data/datasources/home_local_datasource.dart';
import 'package:agrisenseaiapp/features/home/data/repositories/home_repository_impl.dart';
import 'package:agrisenseaiapp/features/home/domain/entities/home_dashboard.dart';
import 'package:agrisenseaiapp/features/home/domain/repositories/home_repository.dart';
import 'package:agrisenseaiapp/features/home/presentation/providers/home_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingHomeRepository implements HomeRepository {
  @override
  Future<HomeDashboard> getDashboard() async {
    throw Exception('home fail');
  }

  @override
  Stream<HomeDashboard> watchDashboard() =>
      Stream<HomeDashboard>.error(Exception('home fail'));

  @override
  Future<void> setPumpStatus(bool isOn) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Home Integration', () {
    testWidgets('dashboard load success flow', (tester) async {
      final provider = HomeProvider(
        repository: HomeRepositoryImpl(
          localDataSource: HomeLocalDataSourceImpl(),
        ),
      );

      await provider.loadDashboard();

      expect(provider.dashboard, isNotNull);
      expect(provider.dashboard!.sensors.isNotEmpty, isTrue);
      expect(provider.errorMessage, isNull);
    });

    testWidgets('dashboard load failure flow', (tester) async {
      final provider = HomeProvider(repository: _FailingHomeRepository());
      await provider.loadDashboard();

      expect(provider.dashboard, isNull);
      expect(provider.errorMessage, 'Unable to load dashboard data.');
      expect(provider.isLoading, isFalse);
    });
  });
}
