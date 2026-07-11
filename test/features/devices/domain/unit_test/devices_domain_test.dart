import 'package:agrisenseaiapp/features/devices/data/datasources/devices_local_datasource.dart';
import 'package:agrisenseaiapp/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:agrisenseaiapp/features/devices/domain/entities/devices_dashboard.dart';
import 'package:agrisenseaiapp/features/devices/domain/repositories/devices_repository.dart';
import 'package:agrisenseaiapp/features/devices/presentation/providers/devices_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingDevicesRepo implements DevicesRepository {
  @override
  Future<DevicesDashboard> getDashboard() async {
    throw Exception('bad');
  }
}

void main() {
  group('Devices Unit Tests', () {
    test('datasource provides paired and available devices', () async {
      final source = DevicesLocalDataSourceImpl();
      final data = await source.getDashboard();
      expect(data.pairedDevices.length, 1);
      expect(data.availableDevices.length, 1);
    });

    test('provider loadDevices success', () async {
      final provider = DevicesProvider(
        repository: DevicesRepositoryImpl(
          localDataSource: DevicesLocalDataSourceImpl(),
        ),
      );
      await provider.loadDevices();
      expect(provider.dashboard, isNotNull);
      expect(provider.errorMessage, isNull);
    });

    test('provider refresh flow updates refreshing flag', () async {
      final provider = DevicesProvider(
        repository: DevicesRepositoryImpl(
          localDataSource: DevicesLocalDataSourceImpl(),
        ),
      );

      await provider.refreshAvailableDevices();
      expect(provider.isRefreshing, isFalse);
      expect(provider.dashboard, isNotNull);
    });

    test('provider load failure sets proper error', () async {
      final provider = DevicesProvider(repository: _FailingDevicesRepo());
      await provider.loadDevices();
      expect(provider.errorMessage, 'Unable to load devices.');
    });
  });
}
