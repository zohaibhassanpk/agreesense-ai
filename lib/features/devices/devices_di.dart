import 'package:get_it/get_it.dart';

import 'data/datasources/devices_local_datasource.dart';
import 'data/repositories/devices_repository_impl.dart';
import 'domain/repositories/devices_repository.dart';
import 'presentation/providers/devices_provider.dart';

class DevicesDI {
  void init(GetIt di) {
    di.registerLazySingleton<DevicesLocalDataSource>(
      () => DevicesLocalDataSourceImpl(),
    );

    di.registerLazySingleton<DevicesRepository>(
      () => DevicesRepositoryImpl(localDataSource: di()),
    );

    di.registerFactory<DevicesProvider>(
      () => DevicesProvider(repository: di()),
    );
  }
}
