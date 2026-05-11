# Alerts Feature UI Design Notes

## Design Reference
- Source: APP_DESIGN.html (Screen 8: Alerts & History)
- Target: Match header layout, filter chips, section labels, and alert cards

## Implementation Summary
- Created Alerts feature structure with Clean Architecture folders and DI.
- Built the Alerts screen with a header, filter chips, and sectioned alert list.
- Used feature-level widgets for reusable layout pieces and styling.

## UI Components
- AlertsHeader: Title and horizontal filter chips.
- AlertFilterChip: Selected/unselected pill styling.
- AlertSectionLabel: Uppercase section labels (Today, Yesterday).
- AlertCard: Icon badge, title, time, and message.

## Design System Usage
- Colors: AppColors (primary, darkGreen, accentYellow, error, surface, border).
- Spacing: AppSpacing for padding, gaps, and list rhythm.
- Radius: AppBorderRadius for pill and card rounding.
- Typography: AppTextStyles via context.textTheme.
- Responsiveness: responsive_extension.dart for sizing and spacing.

## Notes
- Critical alerts use error-colored borders and icon badge.
- Historical (Yesterday) alerts are muted with opacity to match design.
- Filter chips reflect selection state and match the design pill style.
