import 'package:agrisenseaiapp/features/devices/data/datasources/devices_local_datasource.dart';
import 'package:agrisenseaiapp/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('devices repository returns dashboard', () async {
    final repo = DevicesRepositoryImpl(
      localDataSource: DevicesLocalDataSourceImpl(),
    );
    final dash = await repo.getDashboard();
    expect(dash.availableDevices, isNotEmpty);
  });
}
