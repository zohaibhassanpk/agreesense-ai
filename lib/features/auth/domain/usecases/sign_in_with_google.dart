import '../../../../core/entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  SignInWithGoogle(this.repository);

  final AuthRepository repository;

  Future<AppUser> call() {
    return repository.signInWithGoogle();
  }
}
