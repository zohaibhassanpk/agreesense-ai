import 'package:agrisenseaiapp/features/devices/data/datasources/devices_local_datasource.dart';
import 'package:agrisenseaiapp/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:agrisenseaiapp/features/devices/presentation/providers/devices_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('devices provider refresh flow works', () async {
    final provider = DevicesProvider(
      repository: DevicesRepositoryImpl(
        localDataSource: DevicesLocalDataSourceImpl(),
      ),
    );
    await provider.refreshAvailableDevices();
    expect(provider.isRefreshing, isFalse);
  });
}
