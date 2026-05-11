import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/alert_filter.dart';
import 'alert_filter_chip.dart';

class AlertsHeader extends StatelessWidget {
  const AlertsHeader({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final List<AlertFilter> filters;
  final AlertFilterType selectedFilter;
  final ValueChanged<AlertFilterType> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseTitleStyle =
        context.textTheme.headlineLarge ?? AppTextStyles.headingLarge;
    final TextStyle titleStyle = baseTitleStyle.copyWith(
      fontWeight: AppTextStyles.headingLarge.fontWeight,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x2l.w,
        (AppSpacing.x2l + AppSpacing.xl).h,
        AppSpacing.x2l.w,
        AppSpacing.lg.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppBorderRadius.s24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: AppSpacing.md.r,
            offset: Offset(0, AppSpacing.sm.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alerts & History', style: titleStyle),
          SizedBox(height: AppSpacing.lg.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _buildFilterChips(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilterChips(BuildContext context) {
    final List<Widget> chips = [];

    for (final filter in filters) {
      if (chips.isNotEmpty) {
        chips.add(SizedBox(width: AppSpacing.sm.w));
      }
      chips.add(
        AlertFilterChip(
          label: filter.label,
          isSelected: selectedFilter == filter.type,
          onTap: () => onFilterSelected(filter.type),
        ),
      );
    }

    return chips;
  }
}
