import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/injection_container.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_border_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/devices_dashboard.dart';
import '../../domain/entities/device_item.dart';
import '../providers/devices_provider.dart';
import '../widgets/available_device_card.dart';
import '../widgets/device_section_label.dart';
import '../widgets/device_action_sheet.dart';
import '../widgets/devices_header.dart';
import '../widgets/paired_device_card.dart';
import '../widgets/refresh_icon_button.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DevicesProvider>(
      create: (_) => di<DevicesProvider>()..loadDevices(),
      child: const _DevicesView(),
    );
  }
}

class _DevicesView extends StatelessWidget {
  const _DevicesView();

  @override
  Widget build(BuildContext context) {
    return Consumer<DevicesProvider>(
      builder: (context, provider, _) {
        final DevicesDashboard? dashboard = provider.dashboard;

        if (provider.isLoading && dashboard == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && dashboard == null) {
          return _DevicesErrorState(message: provider.errorMessage!);
        }

        if (dashboard == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            DevicesHeader(banner: dashboard.banner),
            Expanded(
              child: _DevicesBody(
                dashboard: dashboard,
                isRefreshing: provider.isRefreshing,
                onRefresh: provider.refreshAvailableDevices,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DevicesBody extends StatelessWidget {
  const _DevicesBody({
    required this.dashboard,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final DevicesDashboard dashboard;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl.w,
        AppSpacing.xl.h,
        AppSpacing.xl.w,
        AppSpacing.xl.h,
      ),
      children: [
        DeviceSectionLabel(label: 'Paired Devices'),
        SizedBox(height: AppSpacing.md.h),
        ...dashboard.pairedDevices.map(
          (device) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg.h),
            child: PairedDeviceCard(
              device: device,
              onMenuTap: () => _showDeviceActionsSheet(
                context,
                device,
                onRefresh: onRefresh,
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        _AvailableDevicesHeader(
          isRefreshing: isRefreshing,
          onRefresh: onRefresh,
        ),
        SizedBox(height: AppSpacing.md.h),
        ...dashboard.availableDevices.map(
          (device) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg.h),
            child: AvailableDeviceCard(device: device),
          ),
        ),
      ],
    );
  }
}

class _AvailableDevicesHeader extends StatelessWidget {
  const _AvailableDevicesHeader({
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: DeviceSectionLabel(label: 'Available Devices')),
        RefreshIconButton(isAnimating: isRefreshing, onPressed: onRefresh),
      ],
    );
  }
}

class _DevicesErrorState extends StatelessWidget {
  const _DevicesErrorState({required this.message});

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

void _showDeviceActionsSheet(
  BuildContext context,
  DeviceItem device, {
  required VoidCallback onRefresh,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppBorderRadius.bottomSheet,
    ),
    builder: (sheetContext) {
      return DeviceActionSheet(
        onViewDetails: () {
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device details coming soon.')),
          );
        },
        onRefresh: () {
          Navigator.of(sheetContext).pop();
          onRefresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Refreshing device list...')),
          );
        },
        onRemove: () {
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed ${device.name}.')),
          );
        },
      );
    },
  );
}
