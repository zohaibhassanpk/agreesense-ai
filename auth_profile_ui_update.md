# Auth and Profile UI Update

## What changed
- Expanded the OTP UI to 6 input boxes to match Firebase phone auth codes.
- Made the OTP row wrap on smaller screens to preserve spacing.
- Added support for showing the authenticated user's display name and profile
  photo in the profile summary card.
- Replaced the fixed phone prefix with a country picker using intl_phone_field.
- Added SMS auto-fill support and a dynamic resend timer on the OTP screen.

## Components touched
- Auth login and OTP screens and widgets in lib/features/auth/presentation/.
- Profile summary card in lib/features/profile/presentation/widgets/.

## Design alignment
- Reused existing spacing tokens, typography, colors, and SVG assets.
- Avoided hardcoded sizes outside the existing spacing system.
- Preserved the existing layout structure while extending it for 6-digit OTP.
