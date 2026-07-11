import '../../../../core/entities/app_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser {
  GetCurrentUser(this.repository);

  final AuthRepository repository;

  AppUser? call() {
    return repository.currentUser;
  }
}
