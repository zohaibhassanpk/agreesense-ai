import '../../domain/entities/profile_dashboard.dart';

class ProfileDashboardModel extends ProfileDashboard {
  const ProfileDashboardModel({
    required super.title,
    required super.displayName,
    required super.subtitle,
    required super.photoUrl,
    required super.selectedCrop,
    required super.language,
    required super.logoutLabel,
  });
}
