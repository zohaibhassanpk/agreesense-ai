import '../models/profile_dashboard_model.dart';
import '../../../../core/services/auth/firebase_auth_service.dart';

abstract class ProfileLocalDataSource {
  Future<ProfileDashboardModel> getProfile();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  ProfileLocalDataSourceImpl({required this.authService});

  final FirebaseAuthService authService;

  @override
  Future<ProfileDashboardModel> getProfile() async {
    final user = authService.currentUser;
    final displayName =
        user?.displayName ?? user?.phoneNumber ?? 'AgriSense User';

    return ProfileDashboardModel(
      title: 'Profile',
      displayName: displayName,
      subtitle: 'Welcome back',
      photoUrl: user?.photoUrl,
      selectedCrop: 'Tobacco',
      language: 'English',
      logoutLabel: 'Log Out',
    );
  }
}
