import 'package:get_it/get_it.dart';

import '../../core/services/auth/firebase_auth_service.dart';
import '../../core/services/auth/google_sign_in_service.dart';
import '../../core/services/local_storage/local_storage_service.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/get_current_user.dart';
import 'domain/usecases/sign_in_with_google.dart';
import 'domain/usecases/sign_out.dart';
import 'presentation/providers/auth_login_provider.dart';

class AuthDI {
  void init(GetIt di) {
    // Data sources
    di.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        firebaseAuthService: di<FirebaseAuthService>(),
        googleSignInService: di<GoogleSignInService>(),
      ),
    );

    // Repositories
    di.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: di<AuthRemoteDataSource>(),
        localStorageService: di<LocalStorageService>(),
      ),
    );

    // Use cases
    di.registerLazySingleton<SignInWithGoogle>(
      () => SignInWithGoogle(di<AuthRepository>()),
    );
    di.registerLazySingleton<SignOut>(() => SignOut(di<AuthRepository>()));
    di.registerLazySingleton<GetCurrentUser>(
      () => GetCurrentUser(di<AuthRepository>()),
    );

    // Providers
    di.registerFactory<AuthLoginProvider>(
      () => AuthLoginProvider(signInWithGoogle: di<SignInWithGoogle>()),
    );
  }
}
