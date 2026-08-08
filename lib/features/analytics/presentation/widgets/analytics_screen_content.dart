import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/enums/app_enums.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/snackbars/custom_snackbars.dart';
import '../../domain/entities/analytics_dashboard.dart';
import '../../domain/entities/analytics_metric_average.dart';
import '../../domain/entities/analytics_period_data.dart';
import '../../domain/entities/analytics_time_range.dart';
import '../providers/analytics_provider.dart';
import 'analytics_header.dart';
import 'analytics_metric_average_card.dart';
import 'analytics_metric_chart_card.dart';
import 'analytics_range_tabs.dart';

class AnalyticsScreenContent extends StatelessWidget {
  const AnalyticsScreenContent({
    super.key,
    required this.dashboard,
    required this.period,
    required this.selectedRange,
    required this.onRangeSelected,
  });

  final AnalyticsDashboard dashboard;
  final AnalyticsPeriodData period;
  final AnalyticsTimeRange selectedRange;
  final ValueChanged<AnalyticsTimeRange> onRangeSelected;

  @override
  Widget build(BuildContext context) {
    final TextStyle averagesTitleStyle =
        (context.textTheme.titleMedium ?? AppTextStyles.titleMedium).copyWith(
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        );

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                AnalyticsHeader(title: dashboard.title),
                AnalyticsRangeTabs(
                  periods: dashboard.periods,
                  selectedRange: selectedRange,
                  onSelected: onRangeSelected,
                ),
                SizedBox(height: AppSpacing.md.h),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _refresh(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                children: [
                  AnalyticsMetricChartCard(
                    chartTitle: dashboard.chartTitle,
                    period: period,
                  ),
                  SizedBox(height: 24.h),
                  Text(period.averagesTitle, style: averagesTitleStyle),
                  SizedBox(height: 12.h),
                  _AnalyticsSummaryGrid(metrics: period.averages),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final AnalyticsProvider provider = context.read<AnalyticsProvider>();
    await provider.loadDashboard();
    if (provider.errorMessage != null && context.mounted) {
      CustomSnackbar.show(
        context: context,
        message: "Couldn't refresh analytics data.",
        type: SnackbarType.error,
      );
    }
  }
}

class _AnalyticsSummaryGrid extends StatelessWidget {
  const _AnalyticsSummaryGrid({required this.metrics});

  final List<AnalyticsMetricAverage> metrics;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];

    for (int index = 0; index < metrics.length; index += 2) {
      if (rows.isNotEmpty) {
        rows.add(SizedBox(height: 12.h));
      }
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _summaryCard(metrics[index])),
            SizedBox(width: 12.w),
            Expanded(
              child: index + 1 < metrics.length
                  ? _summaryCard(metrics[index + 1])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _summaryCard(AnalyticsMetricAverage metric) {
    return AnalyticsMetricAverageCard(
      metric: metric,
      isWide: false,
      showIcon: true,
      centerContent: false,
    );
  }
}
