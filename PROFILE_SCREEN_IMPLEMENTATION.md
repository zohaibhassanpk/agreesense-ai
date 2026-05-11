# Profile Screen Implementation

## Overview

Implemented a new `profile` feature screen following the project Clean Architecture rules and using display data derived from `APP_DESIGN.html`.

## Design Source Usage

The design file does not contain a dedicated standalone profile screen, so the screen was self-designed while using profile-related values visible in `APP_DESIGN.html`, including:

- `My Tobacco Field`
- `Welcome back`
- `Tobacco`
- `English`

These values are surfaced through the profile feature's local datasource instead of being hardcoded inside the UI widgets.

## Architecture

Added a full feature under `lib/features/profile/` with:

- `domain/entities/profile_dashboard.dart`
- `domain/repositories/profile_repository.dart`
- `data/datasources/profile_local_datasource.dart`
- `data/models/profile_dashboard_model.dart`
- `data/repositories/profile_repository_impl.dart`
- `presentation/providers/profile_provider.dart`
- `presentation/screens/profile_screen.dart`
- feature widgets for header, summary card, info cards, and logout button
- `profile_di.dart`

## Navigation and DI

Integrated the profile feature by:

- registering `registerProfileDependencies(di)` in `lib/app/injection_container.dart`
- adding `RouteNames.profile`
- registering the new `GoRoute` in `lib/core/router/app_router.dart`
- wiring the existing home profile icon to navigate to the profile screen

## UI Structure

The screen includes:

- a rounded top header aligned with the app's existing feature headers
- a profile summary card with avatar icon and profile display name
- info cards for selected crop and language
- a logout button that navigates to the auth login flow

## Notes

- No new package was introduced.
- The screen uses existing theme tokens, responsive extensions, and SVG assets.
- The logout action currently routes to the login screen and can later be connected to a real auth service flow.
