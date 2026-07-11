import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/home_dashboard_legacy_widgets.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SafeArea(
          bottom: false,
          child: HomeDashboardHeader(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.x2l.w,
              AppSpacing.x2l.h,
              AppSpacing.x2l.w,
              AppSpacing.x2l.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SmartActionCard(),
                SizedBox(height: AppSpacing.x2l.h),
                const LiveSensorsHeader(),
                SizedBox(height: AppSpacing.lg.h),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.lg.h,
                  crossAxisSpacing: AppSpacing.lg.w,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1,
                  children: const [
                    SensorCard(
                      label: 'Soil Moisture',
                      value: '28',
                      unit: '%',
                      icon: AppAssets.drop,
                      iconColor: AppColors.accentBlue,
                      statusColor: AppColors.accentYellow,
                    ),
                    SensorCard(
                      label: 'Temperature',
                      value: '24',
                      unit: '°C',
                      icon: AppAssets.temprature,
                      iconColor: AppColors.primary,
                      statusColor: AppColors.primary,
                    ),
                    SensorCard(
                      label: 'Humidity',
                      value: '62',
                      unit: '%',
                      icon: AppAssets.cloud,
                      iconColor: AppColors.accentBlue,
                      statusColor: AppColors.primary,
                    ),
                    SensorCard(
                      label: 'Light Intensity',
                      value: '760',
                      unit: 'lx',
                      icon: AppAssets.sun,
                      iconColor: AppColors.accentYellow,
                      statusColor: AppColors.accentYellow,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.x2l.h),
                Row(
                  children: [
                    const DashboardActionButton(
                      label: 'Water Logs',
                      icon: AppAssets.timeRefresh,
                    ),
                    SizedBox(width: AppSpacing.lg.w),
                    const DashboardActionButton(
                      label: 'Pump Control',
                      icon: AppAssets.pump,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
