# Local Threshold Notifications

Status: **implemented.**

Local (on-device) notifications now fire when temperature, humidity, soil moisture, or light intensity move out of their normal range, using the exact zone table below.

## How it works

- A new service, `SensorAlertMonitor` (`lib/core/services/notifications/sensor_alert_monitor.dart`), listens to the same live Firebase stream Home already uses (`SensorDatabaseService.watchCurrent()`).
- On every new reading, it checks each of the 4 metrics against its Normal / Warning / Critical zone.
- It only shows a notification when a metric's zone **changes** to something other than Normal — e.g. Normal → Warning, or Warning → Critical. If a value stays in Warning for the next 5 readings in a row, you get **one** notification, not five. Returning to Normal doesn't notify (silently resets, so a future re-crossing notifies again).
- Notifications are shown with `flutter_local_notifications` (via the existing `NotificationLocalHandler`, which was already written but unused before this).
- Started in `lib/main.dart` right after app startup: requests the Android 13+ notification permission, then starts the monitor. It's registered in dependency injection like every other core service (`lib/app/injection_container.dart`).

## Zone table used

| Metric | Normal | Warning | Critical |
|---|---|---|---|
| Temperature | 20–30°C | 15–19°C or 31–35°C | <10°C or >36°C |
| Humidity | 60–75% | 45–59% or 76–85% | <40% or >85% |
| Soil Moisture | 60–85% | 50–59% or 86–90% | <50% or >90% |
| Light Intensity | 45,000–70,000 lux | 25,000–44,000 lux | <20,000 lux, or >90,000 lux **only if** temperature is also >35°C |

A couple of small gaps in the original table (e.g. nothing labeled between Warning and Critical at 35–36°C) default to **Warning** — better to alert a bit early than miss a real crossing.

## Example notifications

- Soil moisture drops to 45%: **"Critical: Low Soil Moisture — Soil moisture is 45% — critical low. Irrigate immediately."**
- Temperature climbs to 32°C: **"Warning: High Temperature — Temperature is 32°C — above the optimal 20–30°C range."**

## Important — check this on your hardware

Your live sensor data currently reports light intensity around **90–95 lux** (e.g. `lightLux: 91.67` in your export). The table's "normal" range is 45,000–70,000 lux, which is real outdoor daylight-scale. At the current reading, light intensity will show as **Critical: Low Light Intensity on every single reading**, because 91 lux is nowhere close to 20,000. That's not a bug in this code — it's applying your table exactly as given. Worth confirming with whoever owns the ESP32 firmware whether the light sensor is reporting raw/uncalibrated values, a different unit, or genuinely needs recalibrating, before this ships — otherwise light intensity will alert constantly.

## Known limitation (by design, per your request)

This only works while the app process is alive (open, or briefly backgrounded) — it will **not** notify if the app has been fully closed/swiped away. Reliable "notify me even when the app is closed" requires a server-side trigger (Cloud Function) pushing through Firebase Cloud Messaging instead of a local, on-device check. That fuller approach is written up in `NOTIFICATIONS_FEATURE_PLAN.md` if you want it later — this implementation is the simpler, local-only version you asked for.
