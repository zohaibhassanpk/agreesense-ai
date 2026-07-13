import 'package:get_it/get_it.dart';

import 'data/datasources/settings_local_datasource.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'domain/repositories/settings_repository.dart';
import 'presentation/providers/settings_provider.dart';

class SettingsDI {
  void init(GetIt di) {
    di.registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSourceImpl(),
    );

    di.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(localDataSource: di()),
    );

    di.registerFactory<SettingsProvider>(
      () => SettingsProvider(repository: di(), thresholdSettings: di()),
    );
  }
}
