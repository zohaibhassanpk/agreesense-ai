import '../entities/profile_dashboard.dart';

abstract class ProfileRepository {
  Future<ProfileDashboard> getProfile();
}
