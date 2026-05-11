import 'package:get_it/get_it.dart';

import 'data/datasources/analytics_local_datasource.dart';
import 'data/repositories/analytics_repository_impl.dart';
import 'domain/repositories/analytics_repository.dart';
import 'presentation/providers/analytics_provider.dart';

class AnalyticsDI {
  void init(GetIt di) {
    di.registerLazySingleton<AnalyticsLocalDataSource>(
      () => AnalyticsLocalDataSourceImpl(),
    );

    di.registerLazySingleton<AnalyticsRepository>(
      () => AnalyticsRepositoryImpl(localDataSource: di()),
    );

    di.registerFactory<AnalyticsProvider>(
      () => AnalyticsProvider(repository: di()),
    );
  }
}
