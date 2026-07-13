import 'package:get_it/get_it.dart';

import '../../core/services/alerts/alerts_store.dart';
import 'data/datasources/alerts_live_datasource.dart';
import 'data/datasources/alerts_local_datasource.dart';
import 'data/repositories/alerts_repository_impl.dart';
import 'domain/repositories/alerts_repository.dart';
import 'presentation/providers/alerts_provider.dart';

class AlertsDI {
  void init(GetIt di) {
    di.registerLazySingleton<AlertsStore>(() => AlertsStore());

    di.registerLazySingleton<AlertsLocalDataSource>(
      () => AlertsLocalDataSourceImpl(),
    );

    di.registerLazySingleton<AlertsLiveDataSource>(
      () => AlertsLiveDataSourceImpl(
        alertsStore: di<AlertsStore>(),
        localDataSource: di<AlertsLocalDataSource>(),
      ),
    );

    di.registerLazySingleton<AlertsRepository>(
      () => AlertsRepositoryImpl(
        localDataSource: di<AlertsLocalDataSource>(),
        liveDataSource: di<AlertsLiveDataSource>(),
      ),
    );

    di.registerFactory<AlertsProvider>(
      () => AlertsProvider(repository: di<AlertsRepository>()),
    );
  }
}
