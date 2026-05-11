# Auth Feature - Login and OTP UI

## Design Sources
- APP_DESIGN.html (Authentication Login and OTP screens)
- Provided login screenshot
- Provided OTP screenshot

## Feature Structure
```
features/auth/
├── auth_di.dart
├── data/
├── domain/
└── presentation/
    ├── providers/
    │   ├── auth_login_provider.dart
    │   └── auth_otp_provider.dart
    ├── screens/
    │   ├── auth_login_screen.dart
    │   └── auth_otp_screen.dart
    └── widgets/
      ├── auth_login_widgets.dart
      └── auth_otp_widgets.dart
```

## UI Implementation Notes
- OTP screen matches the header, title, and body spacing from Screen 6
  in APP_DESIGN.html using `AppSpacing` and responsive extensions.
- OTP digit fields use the 64x64 tile sizing via `AppSpacing` math,
  focus border, and a subtle primary shadow to reflect the design.
- OTP subtitle highlights the phone number with medium weight and the
  primary text color.
- Resend line uses `Text.rich` with the primary color applied to the
  timer label.
- Layout follows the p-6 / pt-12 / pb-6 padding from the design using
  `AppSpacing` and responsive extensions.
- Typography uses `AppTextStyles` via `context.textTheme` for the
  24.sp heading and 14.sp body text.
- Colors are pulled from `AppColors` (primary green, light green tint,
  surface background, and text secondary/tertiary).
- Phone input matches the two-part layout: static country code tile
  (flag + +1) and a `CustomTextField` with medium-weight text for entry.
- Header icon uses the rounded 12px tile with a light-green tint
  behind the leaf icon.
- Buttons use themed `ElevatedButton` and `OutlinedButton`, with a
  subtle shadow added to the Google button to match the design.
- Footer text uses a `Text.rich` span to style Terms & Privacy with
  the primary color.

## Reusable Widgets Created
- `AuthHeaderIcon`
- `AuthPhoneField`
- `AuthPrimaryButton`
- `AuthSectionDivider`
- `AuthGoogleButton`
- `AuthFooterText`
- `AuthOtpHeader`
- `AuthOtpBackButton`
- `AuthOtpTitle`
- `AuthOtpSubtitle`
- `AuthOtpCodeRow`
- `AuthOtpDigitField`
- `AuthOtpPrimaryButton`
- `AuthOtpResendText`

## Accessibility
- Touch targets meet minimum size (48dp) for primary actions.
- Text contrast and sizes align with the provided design.
- Inputs use the theme’s focus and error states for clarity.

## Future Enhancements
- Replace the static country tile with a selectable picker.
- Connect the UI to auth domain/use cases once backend is ready.
