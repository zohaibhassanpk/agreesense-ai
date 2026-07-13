# Phase 2 Implementation Plan

Plan only — nothing in this document has been implemented yet. Written so another engineer (or another coding agent, e.g. Codex) can execute it without re-doing the research. All file paths are relative to the repo root.

## Context: what already exists

The app is a clean-architecture Flutter app (`entity → model → datasource → repository → provider → screen`, get_it DI, provider state management). Home and Analytics already read live data from Firebase Realtime Database (RTDB); local notifications for threshold crossings already exist (`SensorAlertMonitor`). This plan adds: per-user data resolution, pump sync verification, Water Log removal, a stricter online/offline heartbeat, Analytics improvements (Light Intensity + live streaming), and wiring Settings thresholds into a real Warning/Critical notification + Alerts-tab system.

**Important constraint discovered during research: the RTDB rules are now fully locked down (no anonymous read/write — confirmed via `curl`, previously they were open).** This means nothing can be probed externally anymore; all reads/writes must go through the authenticated app session. Build defensively — wrap every new Firebase call in try/catch with a safe fallback, the same way the existing code already does.

## Foundational decision: unify the two conflicting threshold systems

There are currently **two independent, numerically incompatible threshold systems** in the codebase, and task 6/7 below cannot be done safely without reconciling them first:

1. **`SensorThresholds`** in `lib/core/constants/sensor_db_constants.dart` — single-direction values (`minSoilMoisturePercent=30`, `maxTemperatureC=35`, `minHumidityPercent=30`, `maxHumidityPercent=85`), used only by `lib/features/home/data/datasources/home_remote_datasource.dart` to color sensor cards yellow and to generate the "Smart Action" text.
2. **The zone table in `lib/core/services/notifications/sensor_alert_monitor.dart`** — full Normal/Warning/Critical bands per metric, taken from the crop-condition image the user supplied earlier (moisture 50/60/85/90, temperature 10/20/30/36, humidity 40/60/75/85, light 20000/45000/70000/90000-conditional-on-temp).

These do not agree (e.g. Home's moisture warning trigger is 30%, but the zone table's moisture warning band starts at 60%). **Verified by hand-tracing**: if you naively substitute the Settings-configured value (default 30) into the zone table's `warningLow` slot for moisture, a reading of 55% (which the zone table says should be "Warning", since 50–59 is Warning) falls through to "Normal" instead — because the substituted low bound (30) is below the fixed critical bound (50). Any implementation that overrides zone-table boundaries with Settings values must not do this blindly.

**Required fix: adopt ONE canonical threshold table**, matching the zone table (since it's the more complete, later-supplied source of truth), and make exactly 3 of its boundaries user-configurable via Settings — the same 3 directions Settings already has a slider concept for (moisture-low, temperature-high) plus the new humidity-high the user asked to add:

| Metric | criticalLow (fixed) | warningLow (fixed unless noted) | warningHigh (fixed unless noted) | criticalHigh (fixed) |
|---|---|---|---|---|
| Temperature °C | 10 | 20 | **user-configurable via Settings "Max Temperature", default 30** | 36 |
| Humidity % | 40 | 60 | **user-configurable via Settings "Max Humidity" (NEW field), default 75** | 85 |
| Soil Moisture % | 50 | **user-configurable via Settings "Min. Moisture Level", default 60** | 85 | 90 |
| Light Intensity lux | 20,000 | 45,000 | 70,000 | 90,000 **and** temperature > 35°C (fixed, no Settings UI for light) |

Notes:
- This means the Settings screen's existing defaults change slightly (`minMoisture` 30→60, `maxTemperature` 35→30) to align with the zone table. This is a deliberate one-time alignment, not a regression — document it in the commit/PR description so it isn't mistaken for a bug.
- When accepting a user-typed override, clamp it so it can never cross the fixed critical bound on its own side (e.g. clamp Settings' `maxTemperature` to `(20, 36)`, `minMoisture` to `(50, 85)`, `maxHumidity` to `(60, 85)`) — prevents a slider drag from creating a nonsensical zone (warning bound past critical bound).
- `SensorThresholds` (the old Home-only class) should be **deleted** once Home is switched to read the same unified table (see Task 1 below) — don't leave two sources of truth.

---

## Task 1 — Fetch live data for the logged-in user

**Goal:** resolve the RTDB path from the logged-in user's identity instead of the hardcoded `zohaibhassanpk2` key, with a safety-net fallback so the demo hardware is still reachable regardless of which account is used to test.

**Current state:**
- `lib/core/constants/sensor_db_constants.dart`: `defaultUserKey = 'zohaibhassanpk2'`, `fieldPath({userKey = defaultUserKey, ...})`.
- `lib/core/services/realtime_db/sensor_database_service.dart`: `_fieldRef` getter always uses `SensorDbConstants.fieldPath()` (the default key) — no per-user parameterization at all.
- `lib/core/entities/app_user.dart`: `AppUser { uid, displayName, email, phoneNumber, photoUrl }`.
- `lib/core/providers/auth_session_provider.dart`: `AuthSessionProvider extends ChangeNotifier`, holds `AppUser? user`, registered as `di.registerLazySingleton<AuthSessionProvider>`.

**Steps:**
1. Add `SensorDbConstants.sanitizeRtdbKey(String raw)` — replace RTDB-illegal characters (`.`, `#`, `$`, `/`, `[`, `]`) with `_` (RTDB keys can't contain those).
2. In `SensorDatabaseService`, change `_fieldRef` from a getter to a method taking a `String userKey` param: `DatabaseReference _fieldRef(String userKey) => _database.ref(SensorDbConstants.fieldPath(userKey: userKey));`. Update `watchCurrent()`, `getHistoryFrom()`, and the new `watchHistoryFrom()` (Task Analytics-3 below) to accept `{required String userKey}` and pass it through. Pump path stays global/unparameterized (physically one pump).
3. Add to `SensorDatabaseService`:
   ```dart
   /// Tries the user's own email/phone (sanitized) as an RTDB key first — so a
   /// real device-linked account works — falling back to the shared demo key
   /// when nothing has been linked yet, so the app never shows a blank field.
   Future<String> resolveUserKey(AppUser? user) async {
     final candidates = <String>[
       if (user?.email != null && user!.email!.isNotEmpty)
         SensorDbConstants.sanitizeRtdbKey(user.email!),
       if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
         SensorDbConstants.sanitizeRtdbKey(user.phoneNumber!),
     ];
     for (final key in candidates) {
       try {
         final snapshot = await _fieldRef(key).child('current').get();
         if (snapshot.exists) return key;
       } catch (_) {
         // permission-denied or any other failure — try the next candidate
       }
     }
     return SensorDbConstants.defaultUserKey;
   }
   ```
4. `HomeRemoteDataSourceImpl.watchDashboard()` currently builds its `StreamController` and immediately calls `sensorDatabase.watchCurrent()`/`watchPumpStatus()` synchronously inside `onListen`. Change `onListen` to an async block that first `await`s `sensorDatabase.resolveUserKey(authSessionProvider.user)`, then starts the two live subscriptions using the resolved key.
5. Inject `AuthSessionProvider` into `HomeRemoteDataSourceImpl`'s constructor. Update `lib/features/home/home_di.dart` to pass `di<AuthSessionProvider>()`.
6. Apply the identical pattern to `AnalyticsRemoteDataSourceImpl` (needs the same `resolveUserKey` call before its history read/watch — see Analytics tasks below). Update `lib/features/analytics/analytics_di.dart` similarly.

**Why the fallback matters:** there is exactly one real hardware node in RTDB today (`zohaibhassanpk2`). Without the fallback, logging in as any other test account would show "no data" forever, since nothing writes to a per-account path yet (that requires the full device-linking/BLE feature — out of scope here, see `DEVICES_FEATURE_PLAN.md`).

---

## Task 2 — Pump control synchronization

**Status: already implemented, just verify — no code change expected.**

`SensorDatabaseService.setPumpStatus(bool)` writes to `sensor/controls/pump_status` (global path); `watchPumpStatus()` streams it live back into `HomeDashboard.pumpOn`; `HomePumpControlSheet` (`lib/features/home/presentation/widgets/home_dashboard_widgets.dart`) reads the live value via `context.watch<HomeProvider>()` and shows a "Could not update pump" snackbar if the write throws. This already satisfies "immediately becomes true/false" and "two-way sync." **Do not test-write to the real pump from a script/curl — it can drive a real relay if hardware is connected.** Verify only by reading the code and, if needed, toggling it from within the running app on a test device.

---

## Task 3 — Remove Water Log

**Current state:** `lib/features/home/presentation/screens/home_screen.dart` has a `Row` with two buttons: `HomeActionButton(label: 'Water Logs', onPressed: () => HomeWaterLogsSheet.show(...))` and `HomeActionButton(label: 'Pump Control', ...)`. `HomeWaterLogsSheet` and its private `_WaterLogTile` widget are defined in `lib/features/home/presentation/widgets/home_dashboard_widgets.dart` (fully hardcoded mock data, no real datasource).

**Steps:**
1. In `home_screen.dart`, delete the `HomeActionButton(label: 'Water Logs', ...)` block and the `SizedBox(width: ...)` separator before it, leaving the `Row` with just the Pump Control button. Since `HomeActionButton` wraps itself in `Expanded`, a single button in a `Row` will stretch full-width automatically — no other layout change needed.
2. Delete the `HomeWaterLogsSheet` and `_WaterLogTile` classes entirely from `home_dashboard_widgets.dart`.
3. Remove the now-unused `AppAssets.timeRefresh` import reference if nothing else in that file uses it (check first — grep the file).
4. Grep the whole `lib/` and `test/` tree for `HomeWaterLogsSheet`/`WaterLog` to make sure nothing else references it (none expected, but verify).

---

## Task 4 — Device online/offline heartbeat

**Note: the user's message contained two different numbers for this — an earlier casual "2 minutes" and a later, much more formal "user story" spec with an explicit `Δt > 30 seconds → Offline` formula. Treat the 30-second formal spec as authoritative** (it's more precise and was clearly the refined/final statement of the same requirement — implement 30 seconds, not 2 minutes). If that reading is wrong, this is a one-constant change to fix.

**Current state:** `lib/core/constants/sensor_db_constants.dart` has `onlineStaleness = Duration(minutes: 1)` (already simplified once, per a prior request in this same session, from an original 30-minute value). `lib/features/home/data/datasources/home_remote_datasource.dart::_mapDashboard` computes:
```dart
final bool isOnline = updatedAt != null &&
    DateTime.now().difference(updatedAt) < SensorDbConstants.onlineStaleness;
```
This is already unit-consistent — `SensorDatabaseService._toDateTime` parses `updatedAt` via `DateTime.fromMillisecondsSinceEpoch(value.toInt())`, and `DateTime.now().difference(...)` compares two `DateTime`s directly, so there's no epoch-seconds-vs-milliseconds bug to fix; the "technical notes" about unit conversion in the user's spec are already satisfied by the existing code.

**Steps:**
1. Change `onlineStaleness` from `Duration(minutes: 1)` to `Duration(seconds: 30)`.
2. No other change needed — the comparison logic already implements exactly `Δt ≤ 30s → Online, Δt > 30s → Offline`.
3. Optional but recommended: the 1-minute periodic re-emit timer in `HomeRemoteDataSourceImpl` (`_refreshInterval = Duration(minutes: 1)`) means the Online→Offline UI flip could lag up to ~60s after the true 30s boundary, since nothing re-evaluates `isOnline` between Firebase events except that timer. Tighten `_refreshInterval` to something shorter (e.g. `Duration(seconds: 10)`) so the UI reflects the 30s boundary promptly rather than up to a minute late.

---

## Task 5 — Analytics improvements

### 5a. Use History data only (already true — verify, don't rebuild)

`lib/features/analytics/data/datasources/analytics_remote_datasource.dart::getDashboard()` already calls `sensorDatabase.getHistoryFrom(...)` exclusively — it never touches the `current` node. No change needed for this specific sub-requirement; just don't introduce a `current`-node read while doing the rest of this task.

### 5b. Live/real-time updates from the History node

**Current state:** Analytics is a one-shot `Future<AnalyticsDashboardModel> getDashboard()`, refetched only on screen-mount and manual pull-to-refresh (`RefreshIndicator` in `lib/features/analytics/presentation/widgets/analytics_screen_content.dart`). `AnalyticsRepository` (`lib/features/analytics/domain/repositories/analytics_repository.dart`) has only `Future<AnalyticsDashboard> getDashboard();`. `AnalyticsProvider` (`lib/features/analytics/presentation/providers/analytics_provider.dart`) awaits it once per `loadDashboard()` call.

**Steps — mirror the exact pattern already used for Home (`HomeProvider`/`HomeRepositoryImpl`/`HomeRemoteDataSourceImpl`), which has already been built and adversarially reviewed in this codebase:**

1. `SensorDatabaseService`: add a live variant of the history read —
   ```dart
   Stream<List<SensorSample>> watchHistoryFrom(DateTime start, {required String userKey}) {
     final int startMs = start.millisecondsSinceEpoch;
     return _fieldRef(userKey)
         .child('history')
         .orderByKey()
         .startAt(startMs.toString())
         .onValue
         .map((event) => _parseHistory(event.snapshot.value))
         .map((samples) => (samples
                 .where((s) => s.timestamp.millisecondsSinceEpoch >= startMs)
                 .toList()
               ..sort((a, b) => a.timestamp.compareTo(b.timestamp))));
   }
   ```
   This fires automatically whenever a new child is added under `history` within the queried range — that's the "real-time updates when new records are added" requirement, satisfied by Firebase's own `onValue` semantics on a query, no polling needed.
2. `AnalyticsRepository`: add `Stream<AnalyticsDashboard> watchDashboard();` alongside the existing `getDashboard()` (keep `getDashboard()` — it's still needed as the local/test-fixture fallback, exactly like `HomeRepository` keeps both).
3. `AnalyticsRepositoryImpl`: add an optional `AnalyticsRemoteDataSource? remoteDataSource` param (same optional-remote-datasource pattern as `HomeRepositoryImpl`/`AnalyticsRepositoryImpl` today), implement `watchDashboard()` to delegate to `remoteDataSource.watchDashboard()` when present, else `localDataSource.getDashboard().asStream()`.
4. `AnalyticsRemoteDataSourceImpl`: add `Stream<AnalyticsDashboardModel> watchDashboard()` using a `StreamController` exactly like `HomeRemoteDataSourceImpl.watchDashboard()` does: on `onListen`, resolve the user key (Task 1), subscribe to `sensorDatabase.watchHistoryFrom(now.subtract(monthWindow), userKey: key)`, and on every emission re-run the SAME bucketing/averaging logic that `getDashboard()` currently runs (day/week/month periods, including the new Light Intensity section from 5d below) using the freshly-received sample list plus a recomputed `now`. Also add a periodic re-emit timer (~1 minute, matching Home's pattern) so axis labels/bucket boundaries and the day chart's "Now" position don't go stale between actual new-sample events (cadence is 10–15 min, so most of the time nothing new arrives for a while).
5. `AnalyticsProvider.loadDashboard()`: convert from a single `await repository.getDashboard()` to a stream-subscribe pattern — **copy `HomeProvider`'s implementation almost verbatim** (`lib/features/home/presentation/providers/home_provider.dart`), including: cancelling any prior subscription, a `Completer` for the first event with a timeout that shows the error state only if nothing has arrived yet, an `onError` handler that preserves the last-good dashboard if one exists, and — importantly — **the `_disposed` guard fix that was already applied to `HomeProvider`** (a timeout firing after `dispose()` must not call `notifyListeners()` on a disposed `ChangeNotifier`). Do not skip this guard; it was a confirmed bug when Home was built the same way.
6. `analytics_di.dart`: register `AnalyticsRemoteDataSourceImpl` with `AuthSessionProvider` injected (Task 1), and pass it into `AnalyticsRepositoryImpl` as `remoteDataSource:`.
7. **Test fallout:** `test/features/analytics/domain/unit_test/analytics_domain_test.dart` and `test/features/analytics/integration_test/analytics_integration_test.dart` each define a `_FailingAnalyticsRepo`/`_FailingAnalyticsRepository implements AnalyticsRepository` — adding `watchDashboard()` to the interface will break both (compile error: missing override). Add a one-line override to each, e.g. `@override Stream<AnalyticsDashboard> watchDashboard() => Stream.error(Exception('fail'));` (this is exactly what was done for the equivalent Home test fakes earlier in this project — search for `_FailingHomeRepo` for the precedent).

### 5c. Data accuracy / graceful degradation

Already mostly handled by existing code — verify these still hold after the stream conversion, don't regress them:
- `_buildSeries` skips null metric values (`if (value == null) continue;`) and guarantees at least 2 chart points (duplicates a lone point, flat-lines an empty window) so `_AnalyticsChartPainter` (which crashes on `points.last` for an empty list) never receives an empty series.
- `_buildAverage` uses `.whereType<double>()` to silently skip nulls; shows `'--'` when a window has zero samples for that metric.
- Keep both behaviors when adding the Light Intensity computation in 5d — reuse the same null-skipping/flat-line/`'--'` patterns rather than inventing new ones.

### 5d. Dedicated Light Intensity chart + stats

**Goal:** a separate chart card (not folded into the existing 3-line "Combined Metrics" chart), single line, styled like the existing sensor graphs, with Average/Minimum/Maximum/Latest stats below it.

**Steps:**
1. Extract the reusable parts of `lib/features/analytics/presentation/widgets/analytics_metric_chart_card.dart` — specifically the private `_AnalyticsChart` and `_AnalyticsChartPainter` widgets (they already take an arbitrary `List<AnalyticsMetricSeries>` + `axisLabels`, so they need zero logic changes) — into a new **public** file `lib/features/analytics/presentation/widgets/analytics_line_chart.dart`, e.g. `AnalyticsLineChart({required List<AnalyticsMetricSeries> series, required List<String> axisLabels})`. Update `AnalyticsMetricChartCard` to use this extracted widget internally instead of its own private copy — this is a pure refactor, no behavior change, so it's safe to do first and verify via existing widget tests before adding the new card.
2. Add to `AnalyticsPeriodData`/`AnalyticsPeriodDataModel` (`lib/features/analytics/domain/entities/analytics_period_data.dart` / `.../data/models/analytics_period_data_model.dart`): two new **optional** fields —
   ```dart
   final AnalyticsMetricSeries? lightIntensitySeries;       // single line
   final List<AnalyticsMetricAverage>? lightIntensityStats; // exactly 4: Average, Minimum, Maximum, Latest
   ```
   Keep them optional/nullable (not required) — this is the same "additive, don't break existing constructors" pattern already used throughout this codebase (e.g. `HomeDashboard.deviceOnline`/`updatedAt`/`pumpOn` were added the same way). This means `test/features/analytics/presentation/widget_test/analytics_widgets_test.dart`'s inline `AnalyticsPeriodData(...)` constructions keep compiling unchanged.
3. In `AnalyticsRemoteDataSourceImpl`, add a dedicated light-intensity computation (separate from the existing 3-metric `_metrics`/`_buildSeries`/`_buildAverage` loop, which should stay untouched at exactly Moisture/Temp/Humidity):
   - Series: same bucketing logic as `_buildSeries` but for `sample.lightLux`, normalized 0–1 with a fixed domain (e.g. 0–100,000 lux, or derive min/max from the window's actual data — pick whichever keeps the line readable; a fixed domain is simpler and consistent with how Moisture/Temp/Humidity already use fixed domains).
   - Stats: from the same `windowSamples` list, compute `average` (existing pattern), `min`/`max` (`.reduce`), and `latest` (the sample with the greatest `timestamp`, or `null`/`'--'` if the window is empty) — build 4 `AnalyticsMetricAverageModel`s with labels `'Average'`, `'Minimum'`, `'Maximum'`, `'Latest Reading'`, all sharing one icon/color (e.g. `AppAssets.sun`, colorKey `'yellow'`, matching Home's Light Intensity card).
4. New widget `lib/features/analytics/presentation/widgets/analytics_light_intensity_card.dart` (mirror the structure of `AnalyticsMetricChartCard`): title "Light Intensity Trend", uses `AnalyticsLineChart` from step 1 with a single-entry series list, then a 2×2 (or 1×4) grid of `AnalyticsMetricAverageCard`s (existing widget, already reusable) for the 4 stats.
5. In `lib/features/analytics/presentation/widgets/analytics_screen_content.dart`, render the new card below the existing "Combined Metrics" card + averages section — guard on `period.lightIntensitySeries != null && period.lightIntensityStats != null` so a null (shouldn't happen with the real/local datasources always populating it, but defensive per 5c) doesn't crash, simply omitting the section.
6. Update `AnalyticsLocalDataSourceImpl` (the mock/test fixture) to also populate `lightIntensitySeries`/`lightIntensityStats` with plausible mock data, for UI parity when running with mock data (tests/dev without Firebase).

---

## Task 6 — Settings ↔ Notifications integration

**Current state (confirmed via full read-through):**
- `SettingsDashboard` has `minMoisture`/`maxTemperature` only — **no Humidity field exists at all today**; must be added end-to-end (entity, model, mock datasource, provider, UI).
- `SettingsRepository`/`SettingsLocalDataSourceImpl` are 100% read-only, returning a hardcoded const — there is no save/persist method anywhere in this feature, no call to `LocalStorageService` or RTDB.
- `SettingsProvider.updateMinMoisture`/`updateMaxTemperature` only mutate private in-memory fields and call `notifyListeners()` — nothing durable, and the values evaporate on screen unmount because...
- `SettingsProvider` is registered `registerFactory` (`lib/features/settings/settings_di.dart`) — a brand-new instance is created every time the Settings screen is opened, so **there is currently no way for a background service like `SensorAlertMonitor` (a `registerLazySingleton`) to read "the current threshold" at all** — the data doesn't live anywhere outside the transient widget-scoped provider.
- `LocalStorageService` (`lib/core/services/local_storage/local_storage_service.dart`, `registerLazySingleton`) already exists, wraps `flutter_secure_storage`, and has an established typed-getter/setter-pair pattern per setting (e.g. `getNotificationsEnabled()`/`saveNotificationsEnabled(bool)`) — this is the right place to add threshold persistence, following the same pattern.

**Steps:**
1. Add 3 method pairs to `LocalStorageService`, following its existing pattern exactly (read as string, `double.tryParse`, write via `.toString()`):
   `getMinMoistureThreshold()`/`saveMinMoistureThreshold(double)`, `getMaxTemperatureThreshold()`/`saveMaxTemperatureThreshold(double)`, `getMaxHumidityThreshold()`/`saveMaxHumidityThreshold(double)`.
2. New file `lib/core/services/settings/threshold_settings_service.dart`:
   ```dart
   class ThresholdSettingsService extends ChangeNotifier {
     ThresholdSettingsService({required LocalStorageService storage}) : _storage = storage;
     final LocalStorageService _storage;

     double _minMoisture = 60;      // unified defaults — see the table above
     double _maxTemperature = 30;
     double _maxHumidity = 75;

     double get minMoisture => _minMoisture;
     double get maxTemperature => _maxTemperature;
     double get maxHumidity => _maxHumidity;

     Future<void> load() async {
       _minMoisture = await _storage.getMinMoistureThreshold() ?? 60;
       _maxTemperature = await _storage.getMaxTemperatureThreshold() ?? 30;
       _maxHumidity = await _storage.getMaxHumidityThreshold() ?? 75;
       notifyListeners();
     }

     Future<void> setMinMoisture(double value, {bool persist = true}) async {
       _minMoisture = value.clamp(50, 85);   // never let it cross the fixed critical bound
       notifyListeners();
       if (persist) await _storage.saveMinMoistureThreshold(_minMoisture);
     }
     // setMaxTemperature (clamp 20–36) and setMaxHumidity (clamp 60–85) follow the same shape.
   }
   ```
   Register as `di.registerLazySingleton<ThresholdSettingsService>(() => ThresholdSettingsService(storage: di()))` in `injection_container.dart`. Call `.load()` once at startup in `main.dart`, before `SensorAlertMonitor.start()` (so the very first sensor reading is already evaluated against the saved thresholds, not the hardcoded defaults).
3. Delete `SensorThresholds` from `sensor_db_constants.dart` once Home (Task 1) and `SensorAlertMonitor` (Task 7) both read from `ThresholdSettingsService` instead — don't leave the old class around as a second source of truth.
4. Add `maxHumidity` to `SettingsDashboard`/`SettingsDashboardModel`/`SettingsLocalDataSourceImpl`'s mock (`75`, matching the unified default).
5. Rewrite `SettingsProvider` to source its threshold getters from an injected `ThresholdSettingsService` instead of its own private fields, and to write through it:
   - Constructor takes `required ThresholdSettingsService thresholdSettings` (new dependency).
   - `loadSettings()` calls `await thresholdSettings.load()` and forwards `thresholdSettings.addListener(notifyListeners)` so slider redraws stay in sync (remove that listener in `dispose()`).
   - Add "live" (drag) vs "commit" (release) methods: `updateMinMoisture(double v) => thresholdSettings.setMinMoisture(v, persist: false)` for `onChanged`, and `commitMinMoisture(double v) => thresholdSettings.setMinMoisture(v)` for the new `onChangeEnd`. Same pair for temperature and the new humidity field.
6. Add `onChangeEnd` to `SettingsSliderRow` (currently only has `onChanged`) and wire `Slider(onChangeEnd: onChangeEnd)`.
7. Add a third slider to `SettingsThresholdCard` — "Max Humidity" — matching the existing "Max. Temperature" slider's shape (range 0–100, `activeColor: AppColors.error` or a distinct color), wired to the new `updateMaxHumidity`/`commitMaxHumidity` callback pair.
8. Update `settings_screen.dart` to pass the new humidity value + both callback pairs through, and update `settings_di.dart` to inject `ThresholdSettingsService` into `SettingsProvider`.

**This directly satisfies the user's examples:** setting Max Temperature to 35°C and getting a 37°C reading → `SensorAlertMonitor` (Task 7) reads `thresholdSettings.maxTemperature == 35` instead of the fixed default, 37 > 35 → notifies. Same shape for humidity.

---

## Task 7 — Warning & Critical notification system, wired into the Alerts tab

**Current state (confirmed via full read-through):**
- `AlertItem { title, message, timeLabel, severity: AlertSeverity{critical,warning,info}, icon }`, `AlertSection { label, items, isHistorical }`, `AlertFilter { type: AlertFilterType{all,critical,warnings}, label }` — all in `lib/features/alerts/domain/entities/`.
- `AlertsProvider._applyFilter` (`lib/features/alerts/presentation/providers/alerts_provider.dart`) **already correctly implements** the All/Critical/Warning tab logic — it filters the loaded `_sections` by `item.severity`, drops empty sections, and `_buildFilters` computes a dynamic `'Critical (N)'` count. **This logic does not need to change** — it already does exactly what's asked, generically, from whatever `AlertSection`s it's given.
- The gap: `AlertsLocalDataSourceImpl` returns a **hardcoded static const list** — there is no live/streamed data source, and **nothing in the app today writes new items into what the Alerts screen renders**. `SensorAlertMonitor` fires OS notifications but has zero connection to the Alerts feature (confirmed by a whole-codebase grep — no shared type, store, or stream between them).
- `AlertsProvider` is `registerFactory`, same as Settings — but `AlertsScreen` is one of `NavbarScreen`'s `IndexedStack` children (built once at app start, kept alive), so once created it persists for the session and can safely hold a live subscription, same as Home/Analytics already do.

**Steps:**
1. Add `required DateTime timestamp` to `AlertItem`/`AlertItemModel` (needed for real chronological grouping instead of a static "Today"/"Yesterday" label). Keep `timeLabel` as-is (still a pre-formatted display string the widget reads directly) but compute it via the existing `relativeTime()` util (`lib/core/utils/relative_time.dart`) at construction time for any item built from a real timestamp. Update `AlertsLocalDataSourceImpl`'s 3 mock items to also carry a synthetic `timestamp` (e.g. `DateTime.now().subtract(const Duration(minutes: 10))` etc.) — this means those instances can no longer be declared `const`; drop the `const` keyword on just those instances.
2. New core service `lib/core/services/alerts/alerts_store.dart`:
   ```dart
   class AlertsStore extends ChangeNotifier {
     final List<AlertItem> _liveItems = [];
     List<AlertItem> get liveItems => List.unmodifiable(_liveItems);

     void addAlert(AlertItem item) {
       _liveItems.insert(0, item);
       if (_liveItems.length > 50) _liveItems.removeLast(); // cap growth
       notifyListeners();
     }
   }
   ```
   Register as `registerLazySingleton` in `injection_container.dart` — this is the shared mutable state `SensorAlertMonitor` writes into and the Alerts feature reads from.
3. New `lib/features/alerts/data/datasources/alerts_live_datasource.dart` — `abstract class AlertsLiveDataSource { Stream<List<AlertSectionModel>> watchAlertSections(); }`, impl takes `AlertsStore` + the existing `AlertsLocalDataSource` (for the historical/demo seed items), and on every `AlertsStore` change (and once immediately), merges live items with the local mock items, grouping into sections by comparing each item's `timestamp` date to today's date (simple manual `year/month/day` equality check — group into `'Today'` vs `'Earlier'`, sorted newest-first within each section).
4. `AlertsRepository`: add `Stream<List<AlertSection>> watchAlertSections();` (keep the existing `Future<List<AlertSection>> getAlertSections()` too, as the local-fixture fallback). `AlertsRepositoryImpl` gets an optional `AlertsLiveDataSource?` param, same optional-remote-datasource pattern as everywhere else in this codebase.
5. `AlertsProvider.loadAlerts()`: convert to the same stream-subscribe pattern as `HomeProvider`/`AnalyticsProvider` (Task 5b step 5) — including the `_disposed` guard. Everything downstream (`visibleSections`, `_applyFilter`, `_buildFilters`, the whole tab/count UI) is unchanged, since it already operates generically on whatever `_sections` the stream delivers.
6. Update `alert_di.dart` to wire `AlertsLiveDataSource` (backed by `AlertsStore`) into `AlertsRepositoryImpl`.
7. **Test fallout:** check `test/features/alerts/` for a `_FailingAlertsRepo`/`_FailingAlertsRepository implements AlertsRepository` fake (same pattern as Home/Analytics — very likely exists) and add a one-line `watchAlertSections()` override, same as Task 5b step 7.

### Rewrite `SensorAlertMonitor` to drive both the OS notification and the Alerts tab from one source

**Current state:** `lib/core/services/notifications/sensor_alert_monitor.dart` already classifies each metric into `AlertZone {normal, warning, critical}` via 4 hardcoded zone functions (`_temperatureZone`, `_humidityZone`, `_soilMoistureZone`, `_lightZone`) and fires `notificationHandler.show(title, body, payload)` on a zone **transition** (not every reading — this "trigger once" behavior should be kept). It reads a fixed `SensorDatabaseService.watchCurrent()` (no per-user key yet — needs Task 1's resolution too, since this is a second, independent consumer of `watchCurrent()`).

**Steps:**
1. Extend the private `_ZoneResult` class to carry structured fields instead of just a prose string, so the same result can build both the OS notification AND a fully-detailed `AlertItem`:
   ```dart
   class _ZoneResult {
     const _ZoneResult(this.zone, {this.metricLabel = '', this.value = 0, this.unit = '', this.thresholdLabel = '', this.thresholdValue = 0, this.icon = '', this.body = ''});
     final AlertZone zone;
     final String metricLabel;   // 'Temperature', 'Humidity', 'Soil Moisture', 'Light Intensity'
     final double value;         // the raw reading
     final String unit;          // '°C', '%', 'lux'
     final String thresholdLabel;// e.g. 'critical high', 'warning low'
     final double thresholdValue;// the exact number crossed
     final String icon;          // AppAssets path, reuse Home's per-metric icons
     final String body;          // full sentence for the notification, now explicitly stating the threshold value
   }
   ```
2. Update the 4 zone functions to read the 3 user-adjustable bounds from an injected `ThresholdSettingsService` (Task 6) instead of literals — `_temperatureZone` uses `thresholdSettings.maxTemperature` in place of the old fixed `30`; `_humidityZone` uses `thresholdSettings.maxHumidity` in place of `75`; `_soilMoistureZone` uses `thresholdSettings.minMoisture` in place of `60`. All other boundaries (both criticals, and the non-adjustable warning side of each metric) stay as fixed literals from the unified table above. `_lightZone` is unchanged (no Settings UI for light, per the plan's scope).
3. Rewrite each zone function's messages to explicitly state the threshold value that was crossed (satisfies "include... threshold that triggered the notification"), e.g.: `'Temperature is 37°C — above the critical threshold of 36°C. Crops may be heat-stressed; take immediate action.'` for critical-high, `'Temperature is 32°C — above your configured threshold of 30°C.'` for warning-high (using the LIVE `thresholdSettings.maxTemperature` value in the message, not a hardcoded number).
4. In `_handleReading`, on a zone transition to Warning or Critical (unchanged trigger condition — `result.zone != AlertZone.normal && result.zone != previousZone`), do **two** things instead of one:
   - `notificationHandler.show(title: ..., body: result.body, payload: metric)` (existing, unchanged — OS popup).
   - **New:** `alertsStore.addAlert(AlertItem(title: result.title, message: result.body, timeLabel: relativeTime(DateTime.now()), timestamp: DateTime.now(), severity: result.zone == AlertZone.critical ? AlertSeverity.critical : AlertSeverity.warning, icon: result.icon))` — this is what makes the same event show up in the Alerts tab (both "All" and its own Warning/Critical tab, entirely via the existing, unmodified `AlertsProvider._applyFilter` logic from Task 7 step 5).
5. Constructor gains two new required deps: `ThresholdSettingsService thresholdSettings` and `AlertsStore alertsStore` (plus, per Task 1, resolve the RTDB user key the same way Home/Analytics do — inject `AuthSessionProvider` too, and call `sensorDatabase.resolveUserKey(...)` before `watchCurrent()` in `start()`).
6. Update `injection_container.dart`'s `SensorAlertMonitor` registration to inject `ThresholdSettingsService`, `AlertsStore`, and `AuthSessionProvider`.

This satisfies every part of the "Critical & Warning Notification System" requirement: severity is already correctly classified (zone table, now partly user-configurable), notifications already appear as an OS popup, and — once wired to `AlertsStore` — they now also appear in the in-app Notifications/Alerts screen, correctly bucketed into All/Warning/Critical by the pre-existing (and already correct) filter logic, with sensor name/value/threshold/severity/timestamp all present on the `AlertItem`.

---

## Suggested build order

1. Foundational: unify thresholds (`ThresholdSettingsService`, `LocalStorageService` additions, delete `SensorThresholds`) — Task 6 steps 1–3, since Tasks 1/7 depend on it.
2. Task 1 (per-user resolution) + Task 4 (30s heartbeat) + Task 3 (remove Water Log) — independent, low-risk, do together.
3. Task 6 remaining steps (Settings UI: add Max Humidity slider, wire commit-on-release).
4. Task 7 (`AlertsStore`, live Alerts datasource/provider, `SensorAlertMonitor` rewrite) — depends on step 1 and step 3.
5. Task 5 (Analytics: live streaming + Light Intensity card) — largest, independent of 1–4, can be done in parallel by a second engineer/session if desired.
6. Full `flutter analyze` + `flutter test test/features/` pass, fixing any fallout (expected: the `_Failing*Repo` test fakes in Home/Analytics/Alerts domain+integration tests need one-line overrides for each new `watchX()` interface method, per the notes above).
7. Update `HOME_ANALYTICS_INTEGRATION.md` and `NOTIFICATIONS_LOCAL_ALERTS.md` to reflect the new behavior (per-user resolution + fallback, 30s heartbeat, Settings-driven thresholds, Alerts tab wiring, Light Intensity analytics).

## Things to confirm with the user before/while implementing

- Confirm the 30-second heartbeat (vs. the earlier casual "2 minutes") is really what's wanted — sensor cadence is 10–15 minutes, so at 30s the "Online" state will only be true for a few seconds after each write, which is expected but worth double-checking is the intended UX.
- Confirm the Settings default realignment (`minMoisture` 30→60, `maxTemperature` 35→30) is acceptable, since it changes what a fresh install shows before the user touches any slider.
- Confirm whether Light Intensity should also get a Settings-configurable threshold in a future pass, or stay fixed indefinitely (out of scope here either way).
