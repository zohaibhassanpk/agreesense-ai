import 'package:get_it/get_it.dart';

import '../../core/providers/auth_session_provider.dart';
import '../../core/services/realtime_db/sensor_database_service.dart';
import '../../core/services/local_storage/local_storage_service.dart';
import '../../core/services/settings/threshold_settings_service.dart';
import 'data/datasources/home_local_datasource.dart';
import 'data/datasources/home_remote_datasource.dart';
import 'data/repositories/home_repository_impl.dart';
import 'domain/repositories/home_repository.dart';
import 'presentation/providers/home_provider.dart';

class HomeDI {
  void init(GetIt di) {
    di.registerLazySingleton<HomeLocalDataSource>(
      () => HomeLocalDataSourceImpl(),
    );

    di.registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSourceImpl(
        sensorDatabase: di<SensorDatabaseService>(),
        authSessionProvider: di<AuthSessionProvider>(),
        thresholdSettings: di<ThresholdSettingsService>(),
        storage: di<LocalStorageService>(),
      ),
    );

    di.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(localDataSource: di(), remoteDataSource: di()),
    );

    di.registerFactory<HomeProvider>(() => HomeProvider(repository: di()));
  }
}
