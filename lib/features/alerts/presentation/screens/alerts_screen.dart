import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/injection_container.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/alert_section.dart';
import '../providers/alerts_provider.dart';
import '../widgets/alert_card.dart';
import '../widgets/alert_section_label.dart';
import '../widgets/alerts_header.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AlertsProvider>(
      create: (_) => di<AlertsProvider>()..loadAlerts(),
      child: const _AlertsView(),
    );
  }
}

class _AlertsView extends StatelessWidget {
  const _AlertsView();

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertsProvider>(
      builder: (context, provider, _) {
        final List<AlertSection> sections = provider.visibleSections;

        if (provider.isLoading && sections.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && sections.isEmpty) {
          return _AlertsErrorState(message: provider.errorMessage!);
        }

        return Column(
          children: [
            AlertsHeader(
              filters: provider.filters,
              selectedFilter: provider.selectedFilter,
              onFilterSelected: provider.selectFilter,
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg.w,
                  AppSpacing.lg.h,
                  AppSpacing.lg.w,
                  AppSpacing.x2l.h,
                ),
                itemCount: _itemCount(sections),
                itemBuilder: (context, index) {
                  return _buildListItem(sections, index);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  int _itemCount(List<AlertSection> sections) {
    int count = 0;
    for (final section in sections) {
      count += 1 + section.items.length;
    }
    return count;
  }

  Widget _buildListItem(List<AlertSection> sections, int index) {
    int cursor = 0;

    for (final section in sections) {
      if (index == cursor) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
          child: AlertSectionLabel(label: section.label),
        );
      }
      cursor += 1;

      for (final alert in section.items) {
        if (index == cursor) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg.h),
            child: AlertCard(
              alert: alert,
              isMuted: section.isHistorical,
            ),
          );
        }
        cursor += 1;
      }
    }

    return const SizedBox.shrink();
  }
}

class _AlertsErrorState extends StatelessWidget {
  const _AlertsErrorState({required this.message});

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
