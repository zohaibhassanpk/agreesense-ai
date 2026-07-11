# Devices Feature — Implementation Plan

Status: **plan only, not implemented.**

## What this feature is

Today, Home and Analytics *read* sensor data that the ESP32 writes directly to Firebase. The Devices tab is the other direction: the **phone** talks to the ESP32 over Bluetooth, and in some cases the phone is the one writing sensor data up to Firebase — either to link a device to a user account, to provision Wi-Fi so the ESP32 can talk to Firebase on its own, or to relay sensor readings when the ESP32 itself has no internet connection (SRS's offline/BLE mode).

Currently `DevicesScreen` (`lib/features/devices/`) is fully mocked: one hardcoded "paired" device and one hardcoded "available" device, no real Bluetooth calls anywhere in the codebase.

## Why this matters now

Right now every account that logs into the app sees the exact same hardware field (`zohaibhassanpk2`'s), because that key is hardcoded in `lib/core/constants/sensor_db_constants.dart`. There's no way for a second farmer to link their own ESP32. Step 1 below fixes that and should happen even before the BLE work, since it's small and unblocks everything else (including making per-device push notifications possible — see `NOTIFICATIONS_FEATURE_PLAN.md`).

## Step 1 — Device linking (do this first)

**Goal:** map a logged-in Firebase user to their hardware's RTDB key, so the app stops reading a hardcoded path.

- New RTDB node: `deviceLinks/{firebaseUid} → { hardwareKey, farmId, fieldId, linkedAt }`.
- `HomeRemoteDataSourceImpl` and `AnalyticsRemoteDataSourceImpl` currently build their path from `SensorDbConstants.fieldPath()` with hardcoded defaults — change this to first resolve the current user's `deviceLinks/{uid}` entry (via `AuthSessionProvider.user.uid`, already available), then fall back to the hardcoded default only if no link exists yet (keeps the app usable for the current single-device setup while this rolls out).
- A one-time "linking" write happens during BLE pairing (Step 3) — read the device's hardware ID over BLE, write it to `deviceLinks/{uid}`.

## Step 2 — RTDB security rules

Right now the database has no rules at all (public read/write). Once linking exists, rules should scope access per user:

```
{
  "rules": {
    "deviceLinks": {
      "$uid": { ".read": "auth.uid === $uid", ".write": "auth.uid === $uid" }
    },
    "users": {
      "$hardwareKey": { ".read": "auth != null", ".write": "auth != null" }
    }
  }
}
```
(Tighten `users/$hardwareKey` further once linking is enforced, e.g. only writable by a request whose `deviceLinks` entry matches.)

## Step 3 — BLE pairing

- Add a BLE package — `flutter_blue_plus` is the common choice for Flutter today (actively maintained, supports both platforms). Not in `pubspec.yaml` yet.
- Replace `DevicesLocalDataSourceImpl`'s mock scan result with a real scan filtered to the ESP32's advertised service UUID (needs a fixed UUID picked on the firmware side — coordinate with whoever owns the ESP32 code).
- On "Connect" (`lib/features/devices/presentation/widgets/available_device_card.dart` currently just calls a mock refresh): read the device's hardware ID characteristic, write the `deviceLinks` entry from Step 1, mark it paired.
- New `DevicesRemoteDataSource` (mirrors the pattern in `home_remote_datasource.dart` / `analytics_remote_datasource.dart`) wraps the BLE package; `DevicesRepositoryImpl` gets the same optional-remote-datasource treatment used elsewhere in this codebase so tests keep using the mock.

## Step 4 — Wi-Fi provisioning

SRS REQ-15 asks for BLE-relayed Wi-Fi setup so the ESP32 can get online on its own. During pairing, after the BLE connection is established, send SSID + password over a dedicated BLE characteristic (encrypted at the BLE layer via pairing/bonding, not sent in plaintext). This is a firmware-side feature too — the ESP32 needs a corresponding BLE characteristic that accepts credentials and attempts a Wi-Fi connection.

## Step 5 — Offline relay (the "app writes to Firebase" part)

When the phone is BLE-connected to the ESP32 but the ESP32 has no internet (offline mode, per SRS), the app should read sensor characteristics directly off the device and write them into the **same** `current` / `history` paths the ESP32 would use when online. This means Home and Analytics don't need any changes — they don't know or care whether a reading came from the hardware directly or was relayed through the phone.

- Buffer readings locally first using `sqflite` (already a dependency, currently unused) so nothing is lost if the phone also loses connectivity mid-relay.
- Sync buffered readings to Firebase once the phone regains internet — this satisfies the SRS's local-cache + reconnect-sync requirement (REQ-DB-2/3).
- Reuse `SensorDatabaseService` (`lib/core/services/realtime_db/sensor_database_service.dart`) for the actual Firebase writes — it already has a `getHistoryFrom`/read pattern; add a `writeSample()` method there rather than duplicating Firebase calls in the Devices feature.

## Suggested order

1. Device linking (small, unblocks per-user data)
2. Security rules (do this alongside linking, not after)
3. BLE pairing UI
4. Wi-Fi provisioning
5. Offline relay (most involved — save for last)

## Open questions to resolve before starting

- What BLE service/characteristic UUIDs will the firmware expose? (blocks Step 3)
- Is there a target BLE package preference, or is `flutter_blue_plus` acceptable?
- Should a farmer be able to link more than one device/field (SRS NFR-17 says the backend should support it), or is one-device-per-account enough for now?
