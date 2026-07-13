# Home & Analytics — Live Firebase Data

Status: **implemented.**

Home and Analytics read authenticated Firebase Realtime Database (RTDB) data. Home listens to the field's `current` node, while Analytics listens only to `history`.

## User field resolution

The app no longer assumes that every account owns the hardcoded demo field.

1. It sanitizes the signed-in user's email and phone number so they are valid RTDB keys.
2. It checks those candidate user paths through the authenticated Firebase session.
3. It uses the first candidate whose `current` node exists.
4. If no linked user path is available, it falls back to the shared demo key, `zohaibhassanpk2`.

The fallback keeps the existing hardware demo usable while device-to-account linking remains out of scope. See `DEVICES_FEATURE_PLAN.md` for that future flow. RTDB access is locked down, so failures are handled inside the app rather than probed anonymously.

## Home

- Listens live to `users/{resolvedUserKey}/farms/farm_01/fields/field_01/current`.
- Shows Soil Moisture, Temperature, Humidity, and Light Intensity readings.
- Uses the same canonical threshold profile as Settings and local alerts. The user-adjustable defaults are 60% minimum moisture, 30°C maximum temperature, and 75% maximum humidity; fixed Warning/Critical boundaries remain part of the shared profile.
- Recomputes field status every 10 seconds. Online/offline is derived from the latest reading timestamp rather than a potentially stale hardware flag; exactly 30 seconds remains Online, and anything older is Offline.
- Builds Smart Action guidance from the live readings and current saved thresholds.
- Removes the old Water Logs action and its hardcoded mock sheet.
- Keeps Pump Control synchronized with the global `sensor/controls/pump_status` value. Writes are made only by the authenticated app interaction; automated verification must not toggle the real relay.

## Analytics

- Reads and streams only `users/{resolvedUserKey}/farms/farm_01/fields/field_01/history`; it does not mix in the `current` node.
- Subscribes to RTDB query updates, so newly added history records refresh the dashboard without polling.
- Recomputes Day, Week, and Month buckets and their axis labels from the latest history snapshot.
- Preserves the Combined Metrics chart for Soil Moisture, Temperature, and Humidity.
- Adds a dedicated Light Intensity Trend chart using a fixed 0–100,000 lux domain.
- Shows Average, Minimum, Maximum, and Latest Reading statistics for light intensity.
- Skips missing metric values, displays `--` when a statistic has no data, and always supplies safe chart points for empty or single-reading windows.
- Keeps the last good dashboard if a later stream error occurs; a first-load failure still surfaces a retryable error state.

## Operational boundary

There is still one physical demo node today. Resolving an account-specific key enables already-linked accounts, but it does not provision or pair hardware. Until device linking is implemented, unlinked accounts intentionally use the demo fallback.
