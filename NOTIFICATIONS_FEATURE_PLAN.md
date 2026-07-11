# Notifications Feature — Implementation Plan

Status: **plan only, not implemented.**

Goal: notify a user when a sensor value crosses a threshold (e.g. temperature goes above 35°C), even if the app isn't open.

## What already exists (unused scaffolding)

The groundwork is already in the repo, just never wired up:

- `lib/core/services/notifications/notification_local_handler.dart` — fully implemented. Sets up Android notification channels, requests iOS permissions, has a working `.show(title, body, payload)` method. Never instantiated anywhere.
- `lib/core/services/notifications/notification_background_handler.dart` — a working top-level FCM background handler (`firebaseMessagingBackgroundHandler`). Never registered via `FirebaseMessaging.onBackgroundMessage(...)`.
- `lib/core/services/notifications/notification_service.dart` — currently just `class NotificationService {}`, an empty stub.
- `firebase_messaging`, `flutter_local_notifications`, `permission_handler` are all already in `pubspec.yaml`.
- `lib/features/settings/domain/entities/settings_dashboard.dart` already models `minMoisture`, `maxTemperature`, and `pushNotificationsEnabled` — the Settings screen already has sliders for these (`SettingsThresholdCard`), just not persisted anywhere real yet.
- `lib/features/alerts/domain/entities/alert_item.dart` already models exactly what a threshold event needs: `title`, `message`, `timeLabel`, `severity`, `icon`. The Alerts tab is fully built, just showing mock data.

So this feature is mostly about **wiring existing pieces together and adding one new server-side piece**, not building from scratch.

## The standard architecture (and why)

The natural instinct is "have the app watch the RTDB value and show a notification when it crosses a threshold" — but that only works while the app's Dart code is actually running. Once the app is swiped away, its RTDB listeners stop, and there is nothing left to notice the crossing. This is true on both Android and iOS: background execution for arbitrary app code is unreliable and OS-restricted by design.

The standard pattern for "notify me when data changes, even if my app is closed" is:

```
ESP32 writes to RTDB (current)
        ↓
Cloud Function triggers on that write (server-side, always running)
        ↓
Function checks the new value against the user's thresholds
        ↓
If crossed: call Firebase Cloud Messaging (FCM) to push a notification
        ↓
Phone receives it via FCM — even if the app is fully closed —
and the OS shows it using the app's registered notification channel
```

This is the same shape used by essentially every "alert me" mobile feature backed by Firebase (or any push-based backend). The two client-side handlers already sitting in this repo (`notification_local_handler.dart`, `notification_background_handler.dart`) are exactly the two ends of this pipe that receive the FCM push and render it — they were clearly written with this architecture in mind, just never connected to a sender.

A pure client-side alternative (skip Cloud Functions, just show a local notification when the app happens to be open and notices a crossing) is *not* recommended as the real feature — it only works while the app is alive, which defeats the point of "notify me." It's fine as a quick way to test `NotificationLocalHandler` in isolation during development, but shouldn't be the shipped behavior.

## Avoiding notification spam (this is the part people usually get wrong)

The sensor reports every 10–15 minutes. If temperature is stuck above the threshold for 3 hours, a naive implementation fires ~12–18 notifications for the same event. Standard fixes, both needed:

1. **Edge-detection, not level-detection.** Only notify on the *transition* from normal → crossed, not on every reading while it stays crossed. Requires storing "was this already in an alerted state?" somewhere the Cloud Function can check between invocations — e.g. an RTDB node `alertState/{fieldId}/{metric} = "normal" | "alerted"`.
2. **Hysteresis.** Don't let a value bouncing right at the threshold (34.9°C, 35.1°C, 34.9°C...) re-trigger repeatedly. Require it to drop back below `threshold − buffer` (e.g. 33°C) before it's allowed to re-alert. This is standard practice in any threshold-monitoring system.
3. **Respect the mute switch.** `SettingsDashboard.pushNotificationsEnabled` already exists in the UI — the Function should check it (via a persisted Settings node) before sending.

## Phased plan

**Phase 1 — Persist Settings to Firebase.**
`SettingsDashboard` (minMoisture, maxTemperature, pushNotificationsEnabled) is currently local/mock-only. Move it to an RTDB node (e.g. `userSettings/{uid}`) so both the app and the Cloud Function read the same source of truth. Follow the same optional-remote-datasource pattern used for Home/Analytics in this integration — keeps the existing settings tests working.

**Phase 2 — Client-side wiring.**
- Flesh out `NotificationService` as the orchestrator: request notification permission (`permission_handler`, needed for Android 13+'s `POST_NOTIFICATIONS` runtime permission), fetch the FCM token, subscribe to a topic, initialize `NotificationLocalHandler`, and route incoming foreground messages to it.
- Register `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)` in `main.dart`, before `runApp`.
- Register `NotificationService` in `injection_container.dart` alongside the other core services, and call its init during app startup (mirroring how `AuthSessionProvider`/`NetworkService` are set up today).
- Targeting: since every user currently shares one field, the simplest start is an FCM **topic** (e.g. `field_alerts_field_01`) every signed-in device subscribes to. Once device linking exists (see `DEVICES_FEATURE_PLAN.md`), switch to per-user targeting via a stored FCM token under `deviceLinks/{uid}/fcmToken`, since different farmers will eventually have different fields.

**Phase 3 — Cloud Function (the new piece).**
- Add a `functions/` directory (Firebase Functions, Node or Python).
- Trigger: RTDB `onValueWritten` on `.../current`.
- Logic: read the new value + the user's persisted thresholds (Phase 1) + `alertState` (edge-detection above); if a real transition occurred and hysteresis/cooldown allow it, call the FCM Admin SDK to send to the topic/token, and write a new `AlertItem`-shaped entry into an `alerts/{uid}` (or shared, pre-linking) RTDB node.
- Requires the Firebase project to be on the **Blaze (pay-as-you-go) plan** — Cloud Functions triggers aren't available on the free Spark plan. Worth flagging given the SRS's student-budget constraint (§2.5); Blaze usage for a function this small and infrequent (one trigger per sensor write, ~100/day) is effectively free-tier-covered in practice, but the plan itself must be upgraded.

**Phase 4 — Wire the Alerts tab to real data.**
`AlertsLocalDataSourceImpl` (`lib/features/alerts/data/datasources/`) is mocked the same way Home/Analytics were before this integration. Once Phase 3 is writing real `AlertItem`s to RTDB, add an `AlertsRemoteDataSource` following the exact same pattern used for `HomeRemoteDataSource`/`AnalyticsRemoteDataSource` in this codebase (optional param on the repository, so tests keep passing).

**Phase 5 — Platform setup (not code, but required).**
- Android: add the `POST_NOTIFICATIONS` permission and request it at runtime on first launch (Android 13+ shows no notifications at all without this).
- iOS: enable the Push Notifications and Background Modes → Remote Notifications capabilities in Xcode, and upload an APNs Auth Key to the Firebase console — FCM cannot deliver to iOS without this, and it's an Apple Developer account step, not something fixable in code.

## Suggested order

1. Phase 1 (Settings persistence) — small, and Phase 3 depends on it.
2. Phase 5's platform setup — do this early since it involves waiting on Apple Developer account access.
3. Phase 2 (client wiring) — can be built and tested with manually-sent test messages from the Firebase console before the Function exists.
4. Phase 3 (Cloud Function) — the core "why this feature exists" piece.
5. Phase 4 (Alerts tab) — smallest, do last.

## Open questions to resolve before starting

- Is the Firebase project able to move to the Blaze plan (billing account required)?
- Node.js or Python for the Cloud Function — does whoever maintains this have a preference?
- What should the cooldown/hysteresis values actually be (e.g. 1-hour minimum between repeat alerts of the same type)? No numbers are specified anywhere in the SRS — same situation as the sensor thresholds themselves.
