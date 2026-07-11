import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/injection_container.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/widgets/snackbars/custom_snackbars.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/profile_dashboard.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_logout_button.dart';
import '../widgets/profile_summary_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileProvider>(
      create: (_) => di<ProfileProvider>()..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  Future<void> _handleLogout(
    BuildContext context,
    ProfileProvider provider,
  ) async {
    await provider.logout();
    if (!context.mounted) return;

    if (provider.errorMessage != null) {
      CustomSnackbar.show(
        context: context,
        message: provider.errorMessage!,
        type: SnackbarType.error,
      );
      return;
    }

    CustomSnackbar.show(
      context: context,
      message: 'Logged out successfully.',
      type: SnackbarType.success,
    );

    context.go(RouteNames.auth);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        final ProfileDashboard? profile = provider.profile;

        if (provider.isLoading && profile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && profile == null) {
          return _ProfileErrorState(message: provider.errorMessage!);
        }

        if (profile == null) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              ProfileHeader(title: profile.title),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl.w,
                    AppSpacing.xl.h,
                    AppSpacing.xl.w,
                    AppSpacing.xl.h,
                  ),
                  children: [
                    ProfileSummaryCard(
                      displayName: profile.displayName,
                      subtitle: profile.subtitle,
                      photoUrl: profile.photoUrl,
                    ),
                    SizedBox(height: AppSpacing.x2l.h),
                    ProfileInfoCard(
                      label: 'Selected Crop',
                      value: profile.selectedCrop,
                      icon: AppAssets.leaf,
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    ProfileInfoCard(
                      label: 'Language',
                      value: profile.language,
                      icon: AppAssets.flagUs,
                    ),
                    SizedBox(height: AppSpacing.x2l.h),
                    ProfileLogoutButton(
                      label: profile.logoutLabel,
                      onPressed: provider.isLoading
                          ? null
                          : () => _handleLogout(context, provider),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
          color: AppColors.textSecondary,
        );

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.x2l.r),
        child: Text(message, style: style, textAlign: TextAlign.center),
      ),
    );
  }
}
