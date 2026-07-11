import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/injection_container.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/animated/primary_button.dart';
import '../../domain/entities/analytics_dashboard.dart';
import '../../domain/entities/analytics_period_data.dart';
import '../../domain/entities/analytics_time_range.dart';
import '../providers/analytics_provider.dart';
import 'analytics_day_screen.dart';
import 'analytics_month_screen.dart';
import 'analytics_week_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AnalyticsProvider>(
      create: (_) => di<AnalyticsProvider>()..loadDashboard(),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, _) {
        final AnalyticsDashboard? dashboard = provider.dashboard;
        final AnalyticsPeriodData? period = provider.selectedPeriod;

        if (provider.isLoading && dashboard == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && dashboard == null) {
          return _AnalyticsErrorState(
            message: provider.errorMessage!,
            isRetrying: provider.isLoading,
            onRetry: provider.loadDashboard,
          );
        }

        if (dashboard == null || period == null) {
          return const SizedBox.shrink();
        }

        switch (provider.selectedRange) {
          case AnalyticsTimeRange.day:
            return AnalyticsDayScreen(
              dashboard: dashboard,
              period: period,
              onRangeSelected: provider.selectRange,
            );
          case AnalyticsTimeRange.week:
            return AnalyticsWeekScreen(
              dashboard: dashboard,
              period: period,
              onRangeSelected: provider.selectRange,
            );
          case AnalyticsTimeRange.month:
            return AnalyticsMonthScreen(
              dashboard: dashboard,
              period: period,
              onRangeSelected: provider.selectRange,
            );
        }
      },
    );
  }
}

class _AnalyticsErrorState extends StatelessWidget {
  const _AnalyticsErrorState({
    required this.message,
    required this.isRetrying,
    required this.onRetry,
  });

  final String message;
  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        (context.textTheme.bodyMedium ?? AppTextStyles.bodyMedium).copyWith(
          color: AppColors.textSecondary,
        );

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.x2l.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: style, textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.lg.h),
            PrimaryButton(
              text: 'Retry',
              fitToContent: true,
              borderRadius: 12,
              isLoading: isRetrying,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
