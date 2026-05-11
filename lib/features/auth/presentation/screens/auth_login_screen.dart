import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/injection_container.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/snackbars/custom_snackbars.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/system_utils.dart';
import '../providers/auth_login_provider.dart';
import '../widgets/auth_login_widgets.dart';

class AuthLoginScreen extends StatelessWidget {
  const AuthLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthLoginProvider>(
      create: (_) => di<AuthLoginProvider>(),
      child: const _AuthLoginScreenContent(),
    );
  }
}

class _AuthLoginScreenContent extends StatefulWidget {
  const _AuthLoginScreenContent();

  @override
  State<_AuthLoginScreenContent> createState() =>
      _AuthLoginScreenContentState();
}

class _AuthLoginScreenContentState extends State<_AuthLoginScreenContent> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SystemUtils.setCustomSystemUI(
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      navigationBarColor: context.colorScheme.surface,
      navigationBarIconBrightness: Brightness.dark,
    );
  }

  @override
  void dispose() {
    SystemUtils.setDefaultSystemUI();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = AppSpacing.x2l;
    final double topPadding = AppSpacing.x2l * 2;
    final double introGap = AppSpacing.x2l + AppSpacing.sm;

    final TextStyle titleStyle =
      context.textTheme.headlineLarge ?? AppTextStyles.headingLarge;
    final TextStyle bodyStyle =
        context.textTheme.bodyMedium ?? const TextStyle();

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding.w,
                  topPadding.h,
                  horizontalPadding.w,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuthHeaderIcon(),
                    AppSpacing.x2l.ht,
                    Text('Welcome Back', style: titleStyle),
                    AppSpacing.sm.ht,
                    Text(
                      'Sign in with Google to continue '
                      'accessing your farm data.',
                      style: bodyStyle,
                    ),
                    SizedBox(height: introGap.h),
                    Consumer<AuthLoginProvider>(
                      builder: (context, provider, _) {
                        return AuthGoogleButton(
                          onPressed: provider.isLoading
                              ? null
                              : () async {
                                  final success =
                                      await provider.signInWithGoogle();
                                  if (!mounted) return;

                                  if (success) {
                                    context.go(RouteNames.navbar);
                                    return;
                                  }

                                  final message = provider.errorMessage;
                                  if (message != null) {
                                    CustomSnackbar.show(
                                      context: context,
                                      message: message,
                                      type: SnackbarType.error,
                                    );
                                  }
                                },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding.w,
                AppSpacing.x2l.h,
                horizontalPadding.w,
                horizontalPadding.h,
              ),
              child: const AuthFooterText(),
            ),
          ],
        ),
      ),
    );
  }
}
