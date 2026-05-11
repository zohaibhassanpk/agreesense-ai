# Settings Feature UI Implementation

## Design Sources
- APP_DESIGN.html, screen 13 (Settings)

## Implementation Notes
- Built the Settings UI in lib/features/settings/presentation to match the
  header, section labels, cards, sliders, toggle, and clear data button.
- Reused theme tokens from core/theme for colors, spacing, borders, and
  typography; no hardcoded styles.
- Implemented a custom toggle widget to match the visual style in the design.
- Sliders use SliderTheme with themed colors and sizing tokens.
- Added a crop selector bottom sheet with only Tobacco enabled for now.
- Clear Local Data provides a dummy snackbar confirmation.

## Components Created
- SettingsHeader
- SettingsSectionLabel
- SettingsProfileCard
- SettingsThresholdCard
- SettingsPreferencesCard
- SettingsSliderRow
- SettingsNavigationRow
- SettingsToggle

## Accessibility Checks
- Text uses themed contrast colors.
- Tap targets preserve consistent padding and sizing.
- Slider/thumb sizes use responsive units for touch comfort.
