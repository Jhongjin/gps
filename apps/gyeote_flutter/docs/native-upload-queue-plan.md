# Native Upload Queue Plan

Date: 2026-05-31

The production rule is still: native code is the single writer for location samples. Flutter can display events and request a flush, but it must not upload the same native sample.

## Existing Backend Contract

Use the existing Dart/Supabase shape as the source of truth:

- `DeviceRepository.registerDevice(...)`
  - Implemented by `SupabaseDeviceRepository.registerDevice`.
  - Persists to `devices`.
  - Native must keep the returned `deviceId` locally.
- `DeviceRepository.markSeen(deviceId)`
  - Use on session start and successful flush heartbeat.
- `LocationIngestRepository.uploadLatest(LocationUpload upload)`
  - Upserts `latest_locations`.
  - Conflict target: `profile_id`.
- `LocationIngestRepository.uploadHistoryBatch(List<LocationUpload> uploads)`
  - Inserts/upserts `location_history`.
  - Conflict target: `profile_id,idempotency_key`.
  - Duplicate history uploads must be ignored.

## Supabase Tables

- `devices`
- `latest_locations`
  - `device_id`
  - `latest_locations_device_idx`
- `location_history`
  - `device_id`
  - `idempotency_key`
  - `location_history_device_recorded_idx`
  - `location_history_profile_idempotency_idx`

## Android Queue Shape

Current Android implementation:

- `GyeoteLocationState.uploadConfig` stores native upload settings passed from Flutter.
- `GyeoteLocationUploadQueue` stores a bounded Android Keystore encrypted app-file queue.
- Existing plaintext queue files are still readable and are rewritten encrypted on the next queue write.
- `LocationForegroundService` enqueues samples before emitting them to Flutter.
- `flushPendingLocations` triggers a forced queue flush through the existing MethodChannel and bypasses retry backoff.
- Flutter re-sends native upload config on Supabase auth state changes, and clears it on sign-out.
- Network upload uses PostgREST with the current Supabase access token:
  - `latest_locations?on_conflict=profile_id`
  - `location_history?on_conflict=profile_id,idempotency_key`
- Upload failures keep pending samples on disk, emit `service.statusChanged` with `pendingCount`, `uploadedCount`, and `retryInSeconds`, then retry with bounded exponential backoff.
- HTTP 401/403 failures emit `location.error` with `upload_auth_failed` and wait for Flutter to refresh upload config.

Queue item shape:

- `device_id`
- `sequence`
- `idempotency_key`
- `raw_latitude`, `raw_longitude`
- `shared_latitude`, `shared_longitude`
- `accuracy_m`
- `source`
- `sharing_precision`
- `recorded_at`
- `battery_percent`
- optional `speed_mps`, `heading_deg`, `companion_session_id`

The upload row idempotency key is now normalized to `deviceId + sequence + recordedAt` before sending to Supabase.

## Upload Flow

1. Flutter registers or retrieves `deviceId` through `DeviceRepository.registerDevice`.
2. Flutter passes upload config to native through a dedicated `configureUpload` method.
3. Native writes every collected sample to the local queue first.
4. Native uploads latest state to `latest_locations`.
5. Native uploads history batch to `location_history`.
6. Native deletes only acknowledged queue items.
7. Network errors retry with backoff; auth or RLS errors stop upload and emit `location.error`.
8. Flutter surfaces queue status in the 동행 모드 panel and exposes a manual sync action for QA and recovery.

## iOS Queue Shape

Current iOS source implementation:

- `GyeoteIOSLocationUploadQueue` lives in `ios/Runner/AppDelegate.swift` so it is included in the existing Runner target.
- Samples are normalized to JSON, stored in a bounded file-protected queue under Application Support, then flushed through PostgREST.
- Successful uploads delete acknowledged samples only.
- Network failures preserve pending samples and schedule bounded retry backoff.
- HTTP 401/403 failures emit `upload_auth_failed` and wait for Flutter to refresh `configureUpload`.
- iOS must still be compiled and device-tested in Xcode because this Windows workspace cannot build iOS.

## Supabase RLS Hardening

`supabase/migrations/007_location_upload_rls_hardening.sql` relaxes the `latest_locations` update `using` clause to `profile_id = auth.uid()` while preserving the `with check` requirement that the new `device_id` belongs to the authenticated user. This prevents early rows without `device_id` from blocking a later native upload upsert.

Current limitation: long-running upload while Flutter is not alive still depends on the last access token native received. Production background upload should add either a refresh-token handoff or a server-side edge function strategy.

## Privacy Gates

- Never upload when sharing is paused, hidden, expired, or consent is missing.
- `sosOnly` can upload only SOS samples.
- Keep raw coordinates out of ads, analytics, and logs.
- Queue retention must be bounded and deletable when the user requests history deletion.
