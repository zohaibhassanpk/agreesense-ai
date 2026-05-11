# Navbar Feature Design

## Overview

The navbar feature adds the main authenticated app shell for AgriSenseAI. It
matches the dashboard and bottom navigation structure shown in `APP_DESIGN.html`
and the provided screenshot.

## Structure

Created:

- `lib/features/navbar/domain/entities/navbar_item.dart`
- `lib/features/navbar/presentation/providers/navbar_provider.dart`
- `lib/features/navbar/presentation/screens/navbar_screen.dart`
- `lib/features/navbar/presentation/screens/home_dashboard_screen.dart`
- `lib/features/navbar/presentation/widgets/navbar_bottom_bar.dart`
- `lib/features/navbar/presentation/widgets/navbar_item_widget.dart`
- `lib/features/navbar/presentation/widgets/home_dashboard_widgets.dart`

No data layer or dependency injection was added, as requested.

## Design Implementation

The Home tab follows the design reference:

- White rounded dashboard header with welcome text, field title, profile action,
  and Bluetooth connection pill.
- Light muted screen background.
- Smart Action card with icon, title, and highlighted time estimate.
- Live Sensors two-column grid for soil moisture, temperature, humidity, and
  soil pH.
- Action buttons for Water Logs and Pump Control.
- Fixed white bottom navbar with Home, Alerts, Analytics, Devices, and Settings.

The implementation uses existing project tokens and assets:

- Colors from `AppColors`
- Spacing from `AppSpacing`
- Radius from `AppBorderRadius`
- Typography from `context.textTheme` and `AppTextStyles`
- SVG paths from `AppAssets`
- Responsive extensions from `responsive_extension.dart`

## Navigation

The new route is `RouteNames.navbar`. The OTP Verify Code button now navigates
to the navbar shell after verification.
