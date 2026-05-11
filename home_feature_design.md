# Home Feature Design

## Overview

The Home feature implements the dashboard UI shown in `APP_DESIGN.html`
Screen 7 and the provided screenshot. It is now a dedicated Clean Architecture
feature instead of being owned by the navbar feature.

## Structure

Created:

- `lib/features/home/home_di.dart`
- `lib/features/home/domain/entities/home_dashboard.dart`
- `lib/features/home/domain/entities/sensor_reading.dart`
- `lib/features/home/domain/entities/smart_action.dart`
- `lib/features/home/domain/repositories/home_repository.dart`
- `lib/features/home/data/datasources/home_local_datasource.dart`
- `lib/features/home/data/models/home_dashboard_model.dart`
- `lib/features/home/data/models/sensor_reading_model.dart`
- `lib/features/home/data/models/smart_action_model.dart`
- `lib/features/home/data/repositories/home_repository_impl.dart`
- `lib/features/home/presentation/providers/home_provider.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/home/presentation/widgets/home_dashboard_widgets.dart`
- `lib/features/home/presentation/widgets/home_header_widgets.dart`
- `lib/features/home/presentation/widgets/home_color_resolver.dart`

## Dependency Injection

`registerHomeDependencies(di)` is defined in `home_di.dart` and called from
`app/injection_container.dart`. It registers:

- `HomeLocalDataSource`
- `HomeRepository`
- `HomeProvider`

## Design Implementation

The UI follows the Figma HTML reference:

- White rounded header with welcome label, field title, profile icon, and
  Bluetooth connection pill.
- Light background using `AppColors.background`.
- Smart Action card with blue-tinted gradient, icon container, and highlighted
  time estimate.
- Live Sensors section with updated time.
- Two-column sensor grid for soil moisture, temperature, humidity, and soil pH.
- Bottom action buttons for Water Logs and Pump Control.

The implementation uses centralized project tokens:

- `AppColors`
- `AppSpacing`
- `AppBorderRadius`
- `AppTextStyles` and `context.textTheme`
- `responsive_extension.dart`
- SVGs through `AppAssets`

## Navbar Integration

The navbar Home tab now renders `HomeScreen` from the Home feature. Other navbar
tabs remain placeholders until their own features are implemented.
