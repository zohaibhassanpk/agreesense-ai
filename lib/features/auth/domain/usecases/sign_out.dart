import '../repositories/auth_repository.dart';

class SignOut {
  SignOut(this.repository);

  final AuthRepository repository;

  Future<void> call() {
    return repository.signOut();
  }
}
