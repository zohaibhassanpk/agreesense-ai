# Firebase Realtime Database implementation plan

## 1. Purpose and current project position

This document explains how AgriSenseAI can receive live farm data from Firebase Realtime Database (RTDB), show it on the Home screen, keep a usable local cache, render history in Analytics charts, and operate the irrigation pump safely.

The app already initializes Firebase in `lib/main.dart` and uses a clean feature structure: data source -> repository -> provider -> UI. This is a good foundation. At the moment, however:

- `HomeLocalDataSource` returns fixed sensor values.
- `AnalyticsLocalDataSource` returns fixed graph points and averages.
- the pump state exists only in the Home widget (`_isPumpOn`), so it resets and is not connected to hardware.
- `firebase_database` is not yet in `pubspec.yaml`.
- `sqflite` is available but is not yet used for cached sensor readings.

The recommended approach is to add RTDB data sources alongside the existing local data sources, then make repositories combine live remote data with a local cache. Widgets should continue receiving data only through their Providers; widgets should not call Firebase directly.

## 2. Overall data flow

```text
Sensor / ESP device
       |
       | writes readings and observes commands
       v
Firebase Realtime Database
       |                         ^
       | live stream             | pump command / acknowledgement
       v                         |
Flutter RTDB data source -> repository -> Home / Analytics / Alerts providers -> UI
                                  |
                                  | save successful readings
                                  v
                            SQLite local cache
                                  |
                                  | last known data when offline
                                  v
                              Flutter UI
```

There are two different types of data and they must not be mixed:

1. **Current state**: the latest temperature, humidity, soil moisture, pH, and pump status. This is small and updates the Home screen immediately.
2. **Historical readings**: timestamped records. This is used for graphs, averages, water logs, and analysis.

## 3. Recommended RTDB structure

Use the Firebase Authentication user ID as the top-level access boundary. A user can have multiple farms, fields, and devices. For an initial single-field project, one `fieldId` and one `deviceId` is sufficient, but keeping these IDs in the structure prevents a redesign later.

```json
{
  "users": {
    "{uid}": {
      "farms": {
        "farm_001": {
          "name": "My Farm",
          "fields": {
            "field_001": {
              "name": "My Tobacco Field",
              "deviceId": "esp32_001",
              "thresholds": {
                "minMoisturePercent": 30,
                "maxTemperatureC": 35,
                "minPh": 5.5,
                "maxPh": 7.0
              },
              "current": {
                "temperatureC": 24.3,
                "humidityPercent": 62.0,
                "soilMoisturePercent": 28.0,
                "soilPh": 6.8,
                "lightLux": 760,
                "updatedAt": 1783760400000,
                "deviceOnline": true
              },
              "history": {
                "2026-07-11": {
                  "-PUSH_KEY_1": {
                    "temperatureC": 24.3,
                    "humidityPercent": 62.0,
                    "soilMoisturePercent": 28.0,
                    "soilPh": 6.8,
                    "lightLux": 760,
                    "recordedAt": 1783760400000
                  }
                }
              },
              "pump": {
                "state": "off",
                "mode": "manual",
                "lastChangedAt": 1783760200000,
                "lastChangedBy": "{uid}",
                "lastCommandId": "cmd_abc"
              },
              "pumpCommands": {
                "cmd_abc": {
                  "desiredState": "off",
                  "requestedAt": 1783760200000,
                  "requestedBy": "{uid}",
                  "status": "applied",
                  "acknowledgedAt": 1783760204000,
                  "failureReason": null
                }
              },
              "waterLogs": {
                "log_abc": {
                  "startedAt": 1783760000000,
                  "endedAt": 1783760200000,
                  "durationSeconds": 200,
                  "source": "manual",
                  "commandId": "cmd_abc"
                }
              },
              "alerts": {
                "alert_abc": {
                  "type": "low_moisture",
                  "severity": "warning",
                  "message": "Soil moisture is 28%; irrigation is recommended.",
                  "createdAt": 1783760400000,
                  "isRead": false,
                  "isMuted": false
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### Why this shape is recommended

- `current` is a single small object. The app listens to it continuously and does not download historical readings when opening Home.
- `history/YYYY-MM-DD/pushKey` makes a day query predictable and prevents one huge flat list. Use `recordedAt` in every item even though the key is ordered, because it is explicit and easy to parse.
- The **device writes** the actual `pump.state`; the app writes a request under `pumpCommands`. This means the UI displays confirmed physical state rather than assuming that a write has operated a relay.
- A `pumpCommands` entry makes each action traceable and supports an acknowledgement or error message.
- `waterLogs` can be generated by the device when it truly starts/stops the pump, or by trusted backend logic. It should not be inferred solely from a button tap.

### Device write cadence

The device should update `current` after each valid sensor cycle, for example every 30-60 seconds. It should write one historical record less frequently (for example every 5 minutes), or only if a significant value change occurs. Sending every raw sample to history will make charts slower and increase database usage.

Use Firebase server time (`ServerValue.timestamp`) for records written by the device whenever possible. Store epoch milliseconds, not formatted dates, in the database. The app formats dates according to the user's locale.

## 4. Data ownership and responsibilities

| Actor | Reads | Writes | Important rule |
| --- | --- | --- | --- |
| Sensor device | Its assigned field, pump commands | `current`, `history`, confirmed `pump`, `waterLogs`, command acknowledgement | Validate sensor ranges before upload. |
| Flutter app | User's fields, state, history, logs, alerts | Pump command requests, alert read/mute state, user settings | Never write a fake confirmed pump state. |
| Optional Cloud Function | All authorised server paths | Alert events, summaries, notifications | Best place for trusted automation and FCM. |

For a first version, alerts may be calculated in the app while the Home stream is active. For reliable alerts and notifications when the app is closed, move that calculation to a Cloud Function later.

## 5. Home screen mapping

The current Home screen presents sensor cards from `HomeDashboard.sensors`, a smart-action card, an update label, Water Logs, and Pump Control. Replace the hard-coded values with the following mappings.

| Home element | RTDB source | Display rule |
| --- | --- | --- |
| Soil Moisture card | `current/soilMoisturePercent` | One decimal or whole number, `%`; warning when below `thresholds/minMoisturePercent`. |
| Temperature card | `current/temperatureC` | One decimal, `°C`; warning when above `thresholds/maxTemperatureC`. |
| Humidity card | `current/humidityPercent` | One decimal or whole number, `%`. |
| Soil pH card | `current/soilPh` | One or two decimals; show low/high warning using the configured pH range. |
| Light Intensity card | `current/lightLux` | Optional fifth card if the device supplies it. Keep it only if it is a real measured field. |
| “Updated … ago” | `current/updatedAt` | Calculate relative time locally. Mark stale if older than the agreed device interval (for example 3 minutes). |
| Connection text | `current/deviceOnline` plus `updatedAt` | Show “Live” only for recent data; otherwise show “Device offline / last data …”. Do not call it Bluetooth unless Bluetooth is actually used. |
| Smart Action | Current readings + thresholds + pump state | Example: “Moisture is 28%, below the 30% limit. Irrigation recommended.” |
| Pump Control | `pump/state`, latest `pumpCommands/{id}` | Show confirmed state and command progress/error. |
| Water Logs | `waterLogs` | Show actual confirmed pump sessions with duration/source. |

The existing mock dashboard includes Light Intensity but not pH. The plan should decide whether the Home grid shows four cards (Moisture, Temperature, Humidity, pH) and moves Light Intensity to a detail screen, or shows all five. For the stated requirements, pH must replace one existing placeholder slot or be added as a fifth card.

## 6. Pump-control design (safe command and acknowledgement)

Do not set the Home screen to ON immediately and treat that as successful irrigation. A database write only proves Firebase accepted the command; it does not prove the device received it or the relay changed state.

### Command sequence

1. The user taps **Turn On** or **Turn Off** in the existing pump sheet.
2. `HomeProvider.requestPumpState(true/false)` creates a unique `commandId`.
3. The repository writes `pumpCommands/{commandId}` with `desiredState`, requester user ID, and server timestamp. The UI becomes **“Turning on…”** or **“Turning off…”**, and prevents duplicate taps.
4. The device observes the command, operates the relay, then updates `pump/state` and marks that command `applied` (or `failed` with a reason).
5. The app’s live stream receives the confirmed pump state and command status. It displays **ON/OFF**, or a clear failure/timeout message.
6. If no acknowledgement arrives within a chosen limit (for example 20 seconds), show **“Command not confirmed—check device connection”**. Preserve the command for audit; do not quietly force the UI state.

### Pump modes and safety rules

- Store `mode: manual | automatic`. Manual requests should be permitted only when this field allows them.
- The device/firmware must own physical failsafes: maximum run time, relay default state after reboot, and sensor/device fault handling.
- The app may recommend irrigation but should not automatically turn on a pump until the automation rules have been explicitly designed, tested, and approved.
- Each command and water session must record the time and source (`manual`, `automatic`, or `schedule`).

## 7. Graph and analytics plan

### Raw data and query ranges

The Analytics screen already supports Day, Week, and Month tabs. Map each to `history` data:

| Tab | Read | Recommended output |
| --- | --- | --- |
| Day | Today's `history/YYYY-MM-DD` | 1 point per 1-2 hour bucket (average valid readings). |
| Week | Seven daily history nodes | 1 point per day (daily average, min/max where needed). |
| Month | Each day in the selected month | 1 point per day or per week (average), depending on density. |

For the first version, retrieve the daily nodes needed for the selected range and aggregate in the repository. As usage grows, add precomputed `summaries/daily/YYYY-MM-DD` records created by a Cloud Function or the device; that avoids downloading many raw points for long ranges.

### Keep raw units, normalize only for the drawing layer

Temperature, moisture, humidity, and pH have different units and ranges. A single chart cannot truthfully put their raw values on one unlabelled Y-axis. Choose one of these designs:

1. **Recommended:** one selectable metric at a time, with its real Y-axis and unit (for example Soil Moisture 0-100%).
2. **Alternative:** a combined chart only if each series is normalized to a 0-1 display value, clearly labelled “relative trend.” Keep and show actual values in tooltips/cards.

The present chart painter expects normalized `x` and `y` points, so option 2 is close to the current UI. The repository should keep raw domain values; a chart mapper converts them to normalized coordinates based on selected metric/range. Never store normalized chart coordinates in Firebase.

### Analytics calculations

For every metric and selected range calculate:

- average: sum of valid values / number of valid values;
- minimum and maximum (especially temperature and moisture);
- last recorded value and timestamp;
- missing-data state when no readings exist;
- optional irrigation time from `waterLogs`.

Ignore malformed/out-of-range sensor values and log them for diagnosis. The app should display “No data for this period” rather than drawing an invented zero line.

Suggested valid ranges before crop-specific calibration: humidity 0-100%, moisture 0-100%, pH 0-14, light >= 0, and a sensible hardware-specific temperature range. These are validation guards, not agricultural recommendations.

## 8. Local cache and offline behaviour

Firebase has built-in offline persistence on supported mobile platforms, but the app should still use its existing `sqflite` dependency for a deliberate, queryable cache for graphs and reliable offline UI. `FlutterSecureStorage` is currently used for small secrets/preferences and is not appropriate for time-series readings.

### SQLite tables to add

```text
sensor_readings
  id                 TEXT PRIMARY KEY       // RTDB push key
  field_id           TEXT NOT NULL
  recorded_at        INTEGER NOT NULL       // epoch ms
  temperature_c      REAL
  humidity_percent   REAL
  soil_moisture_pct  REAL
  soil_ph            REAL
  light_lux          REAL
  synced_at          INTEGER NOT NULL

field_current_cache
  field_id           TEXT PRIMARY KEY
  payload_json       TEXT NOT NULL
  updated_at         INTEGER NOT NULL

pump_command_cache
  command_id         TEXT PRIMARY KEY
  field_id           TEXT NOT NULL
  desired_state      TEXT NOT NULL
  status             TEXT NOT NULL
  requested_at       INTEGER NOT NULL
  acknowledged_at    INTEGER
  failure_reason     TEXT
```

### Cache rules

1. On app launch, load `field_current_cache` immediately so Home can show the latest known values with a visible “Last synced” timestamp.
2. Start RTDB listeners. On each valid `current` event, update the provider and replace the current cache.
3. When Analytics is opened, show cached readings first, then refresh the requested range from RTDB and upsert by the RTDB push key.
4. When offline, permit viewing cached values/charts and clearly label them as offline/stale. Disable a new pump command unless the Firebase SDK can safely queue it and the product requirement explicitly permits queued irrigation commands.
5. Retain a bounded amount of raw history locally (for example 90 days) and remove only data older than the retention policy.

## 9. Flutter architecture changes

Keep the existing feature boundaries. The following names are illustrative; exact names can follow project conventions.

```text
lib/features/home/
  data/datasources/home_rtdb_datasource.dart        // current state stream, commands, water logs
  data/datasources/home_cache_datasource.dart       // SQLite current cache
  data/models/live_sensor_snapshot_model.dart
  data/models/pump_state_model.dart
  domain/entities/pump_command.dart
  domain/repositories/home_repository.dart          // add streams and requestPumpState
  presentation/providers/home_provider.dart         // owns StreamSubscription and command UI state

lib/features/analytics/
  data/datasources/analytics_rtdb_datasource.dart   // range reading query
  data/datasources/analytics_cache_datasource.dart  // SQLite history query/upsert
  data/mappers/analytics_aggregation_mapper.dart
  presentation/providers/analytics_provider.dart    // reloads when range/field changes

lib/features/alerts/
  data/datasources/alerts_rtdb_datasource.dart
  presentation/providers/alerts_provider.dart

lib/core/services/
  firebase/realtime_database_paths.dart             // one source of truth for paths
  database/local_app_database.dart                  // opens/migrates SQLite
```

### Provider lifecycle

- `HomeProvider` starts a `current` and a `pump` stream when a field is selected, exposes a `dispose()` method that cancels both, and never leaves background listeners running after screen removal.
- `AnalyticsProvider` fetches only the selected date range. It should cancel/restart an in-flight request when the tab or field changes.
- A selected `farmId`/`fieldId` should come from a central field-selection state, not from hard-coded strings in every feature.
- The providers expose `isLive`, `lastUpdatedAt`, `isCommandPending`, and specific error states so UI does not infer state from labels.

## 10. Dependency-injection migration

1. Add `firebase_database` to `pubspec.yaml` and run dependency resolution.
2. Register a single `FirebaseDatabase.instance` in `injection_container.dart`.
3. Register RTDB data sources and SQLite cache data sources in the relevant feature DI files.
4. Change `HomeRepositoryImpl` and `AnalyticsRepositoryImpl` to depend on remote + cache data sources instead of only the present mock local source.
5. Retain the current mock sources behind a development configuration only if demo data is still useful; do not ship a repository that silently returns static values.

No UI widget should require Firebase imports. Only data-layer classes should know RTDB paths and Firebase snapshots.

## 11. Firebase security and setup checklist

Before enabling the app against production data:

- Enable Realtime Database in the same Firebase project used by `firebase_options.dart`.
- Confirm the intended RTDB region and database URL are configured for the Android/iOS apps.
- Add Firebase Authentication access before permissive database rules are removed.
- Give each user access only to `users/{uid}/...`; never use public read/write rules in production.
- Give the device a securely provisioned identity and restrict it to its assigned field/device paths. Do not embed an administrator credential in firmware or in the Flutter app.
- Add indexes for queried fields such as `recordedAt` in relevant `history` locations.
- Validate every incoming snapshot: absent fields, `int` vs `double`, malformed timestamps, stale values, and unknown pump status must result in a safe UI state.
- Test rules with the Firebase Local Emulator Suite before real device testing.

An initial user-owned rules outline is:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    }
  }
}
```

This outline is only a starting point. It needs separate, stricter device rules before a device writes sensor data; otherwise an authenticated user could edit readings or falsely acknowledge a pump command.

## 12. Phased delivery plan

### Phase 0 — confirm the contract

- Export or document the RTDB tree that already exists.
- Compare its exact key names, units, device IDs, and timestamps with the schema in section 3.
- Decide the final Home-card set: at minimum Moisture, Temperature, Humidity, and pH.
- Decide who creates history and pump acknowledgements: device firmware, Cloud Function, or both.
- Write the Firebase rules and device credentials plan before connecting a pump.

**Done when:** one agreed data contract exists and a sample RTDB record can be parsed without guessing.

### Phase 1 — live read-only dashboard

- Add the RTDB package and data source.
- Implement snapshot-to-domain mapping for `current` and thresholds.
- Update Home repository/provider to subscribe to the selected field.
- Replace fixed cards, update time, connection state, and smart action with real data.
- Persist last valid snapshot in SQLite and add stale/offline UI.

**Done when:** modifying a current reading in RTDB updates the corresponding Home card without reopening the app, and an offline restart shows a timestamped cached value.

### Phase 2 — historical readings and graphs

- Save/read timestamped history records.
- Implement cache upsert and bounded retention.
- Fetch day/week/month ranges, aggregate buckets, and calculate averages/min/max.
- Make the chart use actual range data and a selected metric or clearly-normalized combined trend.
- Handle loading, empty ranges, invalid readings, and date boundaries.

**Done when:** the chart and averages change when the selected tab changes and match known test records.

### Phase 3 — pump controls and water logs

- Implement command creation, pending state, live acknowledgement, timeout, and failure UI.
- Implement device-side command observation, relay action, acknowledged state, and water log creation.
- Add manual/automatic mode and firmware failsafes.
- Test with a safe test relay before any real irrigation equipment.

**Done when:** the app never displays a confirmed state until the device updates it, and every completed run appears in Water Logs.

### Phase 4 — alerts and production hardening

- Turn threshold breaches and device-offline events into alert records.
- Connect Alerts screen to RTDB and persist read/muted state.
- Add optional Cloud Functions/FCM for background alerts.
- Finalize Firebase rules, indexes, monitoring, retry strategy, and test coverage.

**Done when:** alerts are deduplicated, access is scoped correctly, and the app remains understandable with missing network/device data.

## 13. Test plan

| Area | Essential checks |
| --- | --- |
| Model mapping | Missing keys, null values, integers/doubles, bad timestamps, and invalid sensor ranges. |
| Live Home | A `current` RTDB change updates all relevant cards, smart action, and last-updated label. |
| Cache | Cached snapshot appears offline; a later live value replaces it; duplicate history keys are not duplicated. |
| Graphs | Day/week/month bucketing, local timezone boundaries, averages, no-data view, and selected metric scaling. |
| Pump | Pending, confirmed, rejected, device-offline, timeout, repeated tapping, and water-log recording. |
| Security | A signed-out user cannot read/write; User A cannot access User B; device role cannot alter unrelated fields. |

## 14. Decisions needed before implementation

1. What is the exact RTDB path and JSON shape you have already created?
2. Does the sensor device write pH and Light Intensity, or only Temperature, Humidity, and Moisture?
3. Which authenticated user/farm/field/device IDs identify the data currently?
4. Can the device read RTDB commands and send a confirmed acknowledgement after changing the relay?
5. Should automation be advisory only at first, or may it start irrigation automatically?
6. What historical sampling interval and retention period are acceptable for the project?

Once these are answered, the schema/mappers can be aligned to the existing database rather than requiring a database migration.
