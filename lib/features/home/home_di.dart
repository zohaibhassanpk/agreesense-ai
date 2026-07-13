import 'package:get_it/get_it.dart';

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
        sensorDatabase: di(),
        authSessionProvider: di(),
        thresholdSettings: di(),
      ),
    );

    di.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(localDataSource: di(), remoteDataSource: di()),
    );

    di.registerFactory<HomeProvider>(() => HomeProvider(repository: di()));
  }
}
