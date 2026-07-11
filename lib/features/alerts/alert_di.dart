import 'package:get_it/get_it.dart';

import 'data/datasources/alerts_local_datasource.dart';
import 'data/repositories/alerts_repository_impl.dart';
import 'domain/repositories/alerts_repository.dart';
import 'presentation/providers/alerts_provider.dart';

class AlertsDI {
  void init(GetIt di) {
    di.registerLazySingleton<AlertsLocalDataSource>(
      () => AlertsLocalDataSourceImpl(),
    );

    di.registerLazySingleton<AlertsRepository>(
      () => AlertsRepositoryImpl(localDataSource: di()),
    );

    di.registerFactory<AlertsProvider>(
      () => AlertsProvider(repository: di()),
    );
  }
}
