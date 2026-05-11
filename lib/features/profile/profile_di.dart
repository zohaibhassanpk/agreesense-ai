import 'package:get_it/get_it.dart';

import '../../core/services/auth/firebase_auth_service.dart';
import 'data/datasources/profile_local_datasource.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'domain/repositories/profile_repository.dart';
import 'presentation/providers/profile_provider.dart';
import '../auth/domain/usecases/sign_out.dart';

class ProfileDI {
  void init(GetIt di) {
    di.registerLazySingleton<ProfileLocalDataSource>(
      () => ProfileLocalDataSourceImpl(authService: di<FirebaseAuthService>()),
    );

    di.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(localDataSource: di()),
    );

    di.registerFactory<ProfileProvider>(
      () => ProfileProvider(
        repository: di(),
        signOut: di<SignOut>(),
      ),
    );
  }
}
