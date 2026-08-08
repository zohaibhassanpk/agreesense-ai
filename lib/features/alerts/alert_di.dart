import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';

import '../../core/constants/sensor_db_constants.dart';
import '../../core/providers/auth_session_provider.dart';
import '../../core/services/alerts/alerts_store.dart';
import '../../core/services/local_storage/local_storage_service.dart';
import 'data/datasources/alerts_live_datasource.dart';
import 'data/datasources/alerts_local_datasource.dart';
import 'data/repositories/alerts_repository_impl.dart';
import 'domain/repositories/alerts_repository.dart';
import 'presentation/providers/alerts_provider.dart';

class AlertsDI {
  void init(GetIt di) {
    di.registerLazySingleton<AlertsStore>(
      () => AlertsStore(storage: di<LocalStorageService>()),
    );

    di.registerLazySingleton<AlertsLocalDataSource>(
      () => AlertsLocalDataSourceImpl(),
    );

    di.registerLazySingleton<AlertsLiveDataSource>(
      () => AlertsLiveDataSourceImpl(
        alertsStore: di<AlertsStore>(),
        localDataSource: di<AlertsLocalDataSource>(),
        database: FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: SensorDbConstants.databaseUrl,
        ),
        authSession: di<AuthSessionProvider>(),
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
