import 'package:agrisenseaiapp/features/devices/data/datasources/devices_local_datasource.dart';
import 'package:agrisenseaiapp/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:agrisenseaiapp/features/devices/domain/entities/devices_dashboard.dart';
import 'package:agrisenseaiapp/features/devices/domain/repositories/devices_repository.dart';
import 'package:agrisenseaiapp/features/devices/presentation/providers/devices_provider.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingDevicesRepository implements DevicesRepository {
  @override
  Future<DevicesDashboard> getDashboard() async {
    throw Exception('devices fail');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Devices Integration', () {
    testWidgets('load and refresh flow', (tester) async {
      final provider = DevicesProvider(
        repository: DevicesRepositoryImpl(
          localDataSource: DevicesLocalDataSourceImpl(),
        ),
      );

      await provider.loadDevices();
      await provider.refreshAvailableDevices();

      expect(provider.dashboard, isNotNull);
      expect(provider.dashboard!.availableDevices, isNotEmpty);
      expect(provider.isRefreshing, isFalse);
    });

    testWidgets('load failure sets error', (tester) async {
      final provider = DevicesProvider(repository: _FailingDevicesRepository());

      await provider.loadDevices();
      expect(provider.dashboard, isNull);
      expect(provider.errorMessage, 'Unable to load devices.');
    });
  });
}
