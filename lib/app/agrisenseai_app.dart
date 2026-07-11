import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_session_provider.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import 'injection_container.dart';

class AgriSenseAIApp extends StatelessWidget {
  AgriSenseAIApp({super.key})
      : _router = AppRouter(
          authSessionProvider: di<AuthSessionProvider>(),
        );

  final AppRouter _router;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthSessionProvider>.value(
      value: di<AuthSessionProvider>(),
      child: MaterialApp.router(
        title: 'AgriSenseAI',
        debugShowCheckedModeBanner: false,
        // Themes - Light theme only for now
        theme: AppTheme.light,
        // Router
        routerConfig: _router.router,
      ),
    );
  }
}
