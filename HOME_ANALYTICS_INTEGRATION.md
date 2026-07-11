# Home & Analytics — Live Firebase Data

## What's done

The Home and Analytics tabs now show real sensor data from Firebase Realtime Database instead of mock data. Everything else in the app (Devices, Alerts, Settings, Profile) is unchanged and still mocked.

## How Home works

- Listens live to `users/zohaibhassanpk2/farms/farm_01/fields/field_01/current` — updates the screen the instant the hardware writes a new reading, no refresh needed.
- Shows 4 cards: **Soil Moisture**, **Temperature**, **Humidity**, **Light Intensity** (swapped in for the design's "Soil pH" card — your hardware has a light sensor, not a pH probe).
- A card turns yellow when its value crosses a threshold: moisture < 30%, temperature > 35°C, humidity outside 30–85%. Thresholds are hardcoded in `lib/core/constants/sensor_db_constants.dart` for now (see the Notifications plan for making these user-editable).
- Connection pill shows "Device Connected (Live)" or "Device Offline" — based on the hardware's `deviceOnline` flag *and* how recent the last reading is (a reading older than 30 minutes is treated as offline even if the flag is stuck on).
- "Smart Action" card generates real advice from the live values (e.g. tells you to irrigate when moisture is low) instead of static copy.
- Pump Control writes to `sensor/controls/pump_status`; the toggle reflects the real value from Firebase, and shows an error message if the write fails.

## How Analytics works

- Day / Week / Month charts and averages are computed from the `history` node, bucketed and averaged per period.
- Same swap as Home: the third chart line is **Humidity** instead of "Soil pH".
- Pull-to-refresh reloads from Firebase; a failed refresh shows a message instead of failing silently, and a failed first load shows a **Retry** button.

## Things worth knowing

- The database currently has **no access rules** — anyone can read or write it with no login required. Fine for testing, but should be locked down before real users are on it.
- All app users currently see the same field (`zohaibhassanpk2`'s), regardless of who logs in — there's no link yet between a Firebase account and a specific hardware device. See `DEVICES_FEATURE_PLAN.md`.
