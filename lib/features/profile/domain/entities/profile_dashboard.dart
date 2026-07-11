class ProfileDashboard {
  const ProfileDashboard({
    required this.title,
    required this.displayName,
    required this.subtitle,
    required this.photoUrl,
    required this.selectedCrop,
    required this.language,
    required this.logoutLabel,
  });

  final String title;
  final String displayName;
  final String subtitle;
  final String? photoUrl;
  final String selectedCrop;
  final String language;
  final String logoutLabel;
}
