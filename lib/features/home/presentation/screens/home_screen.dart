import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/injection_container.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/home_dashboard.dart';
import '../providers/home_provider.dart';
import '../widgets/home_dashboard_widgets.dart';
import '../widgets/home_header_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeProvider>(
      create: (_) => di<HomeProvider>()..loadDashboard(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  bool _isPumpOn = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, _) {
        final HomeDashboard? dashboard = provider.dashboard;

        if (provider.isLoading && dashboard == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && dashboard == null) {
          return _HomeErrorState(message: provider.errorMessage!);
        }

        if (dashboard == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            HomeHeader(dashboard: dashboard),
            Expanded(
              child: _HomeDashboardBody(
                dashboard: dashboard,
                isPumpOn: _isPumpOn,
                onPumpStateChanged: (value) {
                  setState(() {
                    _isPumpOn = value;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HomeDashboardBody extends StatelessWidget {
  const _HomeDashboardBody({
    required this.dashboard,
    required this.isPumpOn,
    required this.onPumpStateChanged,
  });

  final HomeDashboard dashboard;
  final bool isPumpOn;
  final ValueChanged<bool> onPumpStateChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg.w,
        AppSpacing.lg.h,
        AppSpacing.lg.w,
        AppSpacing.lg.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSmartActionCard(action: dashboard.smartAction),
          SizedBox(height: AppSpacing.md.h),
          HomeSectionHeader(updatedLabel: dashboard.updatedLabel),
          SizedBox(height: (AppSpacing.sm / 2).h),
          GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: dashboard.sensors.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm.h,
              crossAxisSpacing: AppSpacing.lg.w,
              childAspectRatio: 1.24,
            ),
            itemBuilder: (context, index) {
              return HomeSensorCard(sensor: dashboard.sensors[index]);
            },
          ),
          SizedBox(height: AppSpacing.lg.h),
          Row(
            children: [
              const HomeActionButton(
                label: 'Water Logs',
                icon: AppAssets.timeRefresh,
              ),
              SizedBox(width: AppSpacing.md.w),
              HomeActionButton(
                label: 'Pump Control',
                icon: AppAssets.pump,
                onPressed: () {
                  HomePumpControlSheet.show(
                    context: context,
                    isPumpOn: isPumpOn,
                    onTurnOn: () {
                      onPumpStateChanged(true);
                      Navigator.of(context).pop();
                    },
                    onTurnOff: () {
                      onPumpStateChanged(false);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({required this.message});

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
