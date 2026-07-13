# Local Threshold Notifications & In-App Alerts

Status: **implemented.**

The app evaluates live field readings against one canonical threshold profile. A qualifying zone transition creates both an operating-system notification and a matching item in the Alerts tab.

## Canonical threshold profile

| Metric | Normal | Warning | Critical | User setting |
|---|---|---|---|---|
| Temperature | 20°C through configured maximum | 10–<20°C or above the configured maximum through 36°C | Below 10°C or above 36°C | Maximum, default 30°C; clamped to 20–36°C |
| Humidity | 60% through configured maximum | 40–<60% or above the configured maximum through 85% | Below 40% or above 85% | Maximum, default 75%; clamped to 60–85% |
| Soil Moisture | Configured minimum through 85% | 50% through below the configured minimum, or above 85% through 90% | Below 50% or above 90% | Minimum, default 60%; clamped to 50–85% |
| Light Intensity | 45,000–70,000 lux | 20,000–<45,000 lux or above 70,000 lux, except for the high-light/heat case | Below 20,000 lux, or above 90,000 lux when temperature is also above 35°C | Fixed; no Settings slider |

The Settings sliders update the shared threshold service immediately while dragging and persist to secure local storage when released. Saved values are loaded before the sensor monitor starts, so the first reading uses the user's configuration. The old, incompatible Home-only threshold table has been removed.

## Notification flow

- `SensorAlertMonitor` resolves the signed-in user's RTDB field key, with the shared demo key as the safety fallback.
- It listens to the field's live `current` reading and classifies temperature, humidity, soil moisture, and light intensity.
- It notifies only when a metric changes into Warning or Critical. Repeated readings in the same zone do not create duplicate alerts; returning to Normal resets the transition state.
- Every message includes the sensor name, measured value, and the exact fixed or configured threshold that was crossed.
- The same event is sent to `flutter_local_notifications` and added to the in-app `AlertsStore` with severity and timestamp.

## Alerts tab

- Live alerts are merged with the existing seeded/demo history and sorted newest first.
- Items are grouped into Today and Earlier sections from their timestamps.
- All shows every item; Critical and Warnings reuse the existing severity filters.
- The Critical chip count updates from the merged live data.
- The live in-app store is capped at 50 items to bound memory growth.

Live alerts are session-scoped and are not persisted across a full app restart. Persisted alert history or cross-device synchronization would require a database-backed alerts repository.

## Runtime limitation

This remains an on-device monitor. It works while the app process is alive, but it cannot guarantee notifications after the app has been fully terminated. Reliable closed-app delivery requires a server-side trigger and Firebase Cloud Messaging; that larger design remains in `NOTIFICATIONS_FEATURE_PLAN.md`.

Light readings in the provided sample data are around 90–95 lux, far below the 20,000 lux critical boundary. Confirm the hardware unit/calibration before release to avoid legitimate-but-unhelpful low-light alerts.
