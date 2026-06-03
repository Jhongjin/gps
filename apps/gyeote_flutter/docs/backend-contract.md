# Backend Contract

Date: 2026-05-30

This document maps the Flutter app contracts to the Supabase baseline in `supabase/migrations`.

## Repositories

Flutter depends on repository interfaces in `lib/src/core/backend/backend_contract.dart`.

- `CircleRepository`: circle list, latest member locations, and live map stream.
- `InvitationRepository`: hashed invite creation, acceptance, and revoke.
- `PlaceAlertRepository`: circle-scoped place alert rules and target counts.
- `CheckInRepository`: coordinate-free manual safety check-ins and recent circle check-in events.
- `DeviceRepository`: app install registration and last-seen updates.
- `LocationIngestRepository`: active flush/status bridge for the native location uploader.
- `PrivacyRepository`: sharing precision, pause/resume, and data requests.
- `CompanionRepository`: time-boxed companion sessions and mutual consent.

Concrete Supabase implementations should live outside UI widgets. The UI should not directly call tables that contain raw coordinates.

Production location samples have one writer: native iOS/Android code. Dart must not upload the same sample in parallel.

Supabase implementation files:

- `lib/src/core/backend/backend_config.dart`
- `lib/src/core/backend/supabase_backend.dart`
- `lib/src/features/auth/auth_gate.dart`
- `lib/src/features/auth/sign_in_screen.dart`
- `supabase/migrations/003_backend_rpcs.sql`
- `supabase/migrations/004_auth_profile_bootstrap.sql`
- `supabase/migrations/005_circle_creation_rpc.sql`

## Auth Bootstrap

When `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` are provided, the Flutter app shows a Supabase email/password login and signup gate before the map shell.

New users are created through Supabase Auth. The `on_auth_user_created` trigger calls `handle_new_auth_user`, which creates:

- one `profiles` row with the auth user id
- one default `ad_preferences` row with privacy-safe defaults

UI widgets should treat `profiles.id` as equal to `auth.uid()` and should not create profile rows directly.

## Circle Creation

New users may have no circles after signup. `CircleRepository.createCircle` calls `create_circle_with_owner`, which creates:

- one `circles` row
- one owner `circle_members` row for `auth.uid()`
- one default `sharing_policies` row
- one `consent_events` row for audit history

`CircleScreen` uses this RPC before creating the first invite, so the first logged-in action can be "서클 만들기" or "초대하기" without bypassing RLS. The same screen accepts a raw invite token or an invite URL with `?token=...`, then calls `accept_circle_invite` and refreshes the circle list.

## Location Upload

Before uploading locations, native code must call `DeviceRepository.registerDevice` or reuse a previously persisted registered `deviceId`. Location RLS rejects uploads unless `device_id` belongs to the authenticated user.

`LocationUpload` must include:

- `deviceId`: registered device owned by the authenticated user.
- `idempotencyKey`: usually `deviceId + sequence + recordedAt`.
- `sample.rawCoordinate`: native GPS/fused coordinate.
- `sample.sharedCoordinate`: coordinate adjusted by current sharing mode.
- `sample.permissionSnapshot`: foreground/background/precise/notification state.
- `sample.consentVersion`: policy version used when native collected the sample.
- `sharingMode`: persisted as `sharing_precision`; hidden mode stores no shared coordinates.
- optional `companionSessionId`: only for active companion mode.

Supabase tables:

- `latest_locations`: one row per profile, used by live map.
- `location_history`: append-only history with retention.

RLS requires `profile_id = auth.uid()` and a matching `devices.id`.

`SupabaseLocationIngestRepository` upserts `latest_locations` by `profile_id` and upserts `location_history` by `(profile_id, idempotency_key)` so native upload retries do not duplicate route samples.

## Live Map

The app should subscribe to a circle-scoped stream that only emits shared coordinates. Do not subscribe broadly to `location_history`.

MVP implementation polls `get_circle_latest_locations` every five seconds through `SupabaseCircleRepository.watchLatestLocations`. `MapScreen` receives `CircleRepository`, picks the first active circle, and maps `MemberLocationSnapshot` values into `MapMemberTrack` UI models in `features/map/map_models.dart`.

For route tails, `MapScreen` calls `get_circle_member_route_tail` per visible member through `CircleRepository.getMemberRouteTail`. The RPC returns only shared coordinates, is bounded by `route_limit`, and requires the viewer to be authorized for the target circle/member.

Replace the polling stream with an authorized private Realtime channel after the first device QA pass.

Expected event shape:

```json
{
  "type": "location.updated",
  "circleId": "uuid",
  "profileId": "uuid",
  "sharedCoordinate": { "latitude": 37.5665, "longitude": 126.978 },
  "sharingMode": "balanced",
  "accuracyM": 35,
  "batteryPercent": 71,
  "recordedAt": "2026-05-30T12:00:00Z"
}
```

## Companion Mode

Companion mode must be session-based:

1. Create `companion_sessions`.
2. Each participant inserts or updates only their own `companion_session_members` row.
3. Session becomes visible only when required participants have `consented_at`.
4. Ending a session stops high-frequency native location collection and closes the route stream.

The database trigger prevents changing `circle_id`, `subject_profile_id`, or `started_by` after creation.

Current app flow: `MapScreen` creates a companion session for the current user in the active circle, records self consent, activates the session, and passes `companionSessionId` to the native bridge. Native upload queues include that id on `location_history` rows while the session is active.

## Place Alerts

`CircleScreen` reads `place_alerts` through `PlaceAlertRepository.listPlaceAlerts`. The query is scoped by the active circle and includes only the visible rule metadata plus `place_alert_targets(profile_id)` for target counts.

`MapScreen` creates new rules through `create_place_alert_with_targets`. The app sends the selected map radius, place name, target profile ids from the live circle location stream, and event toggles. Demo ids are never saved.

Direct `place_alerts` inserts are blocked by RLS. The RPC validates circle membership, target membership, current shareability, and minor guardian ownership before inserting `place_alerts` and `place_alert_targets` atomically.

After a successful save on Android/iOS, `MapScreen` reloads visible alert rules and calls `LocationBridge.registerGeofences` with up to 20 enabled arrival/departure rules. iOS currently maps those to `CLCircularRegion`; Android acknowledges the bridge call and still needs the native Geofencing API queue.

## Check-In Events

Manual check-in uses `perform_check_in`. The RPC writes a short `check_in_events` row without raw or shared coordinates and ends the caller's companion session when a `companionSessionId` is provided.

`MapScreen` exposes `도착 확인` while companion mode is active. After a successful check-in, it stops native companion collection, clears the live route tail, and shows `무사 도착을 보냈어요. 동행 공유는 종료됐습니다.`

`CircleScreen` and `HistoryScreen` read recent events through `list_circle_check_ins`. The event list is intentionally status-only; location precision is shown as copy, not as a coordinate.

Migration `009_check_in_events.sql` also narrows direct `latest_locations` table reads to the owner row. Circle member location reads should use `get_circle_latest_locations`, which returns shared-coordinate fields only.

## Invitations

The app may show `invite_code_hint`, but raw invite URLs or bearer tokens must not be stored. Store only `invite_token_hash`; invite acceptance should be an RPC or server function that hashes the presented token and performs membership creation atomically.

Flow:

1. App asks the backend to create a raw invite token.
2. Server stores only `invite_token_hash`, `invite_code_hint`, expiry, and use limits.
3. Server returns an `InviteCreationResult` with the non-secret invite row and one-time raw invite URL.
4. Accept flow submits the raw token to an RPC/server function.
5. Server hashes the token, validates expiry/use count, creates membership, and writes a consent event.

RPC names:

- `create_circle_with_owner`
- `create_circle_invite`
- `accept_circle_invite`
- `get_circle_latest_locations`
- `get_circle_member_route_tail`
- `create_place_alert_with_targets`
- `perform_check_in`
- `list_circle_check_ins`
- `record_viewer_log`

## Ads And Analytics

Ad SDK events are not part of this contract. Keep them behind consent checks and do not join ad events with raw or shared location tables.

## Privacy Actions

`PrivacyScreen` receives `CircleRepository` and `PrivacyRepository`.

- The ad switches load and update `ad_preferences`; `precise_location_ads_enabled` is always written as `false`.
- "공유 멈춤" loads the first active circle and writes a hidden, disabled `SharingPolicy` with a one-hour `pausedUntil`.
- "내보내기" inserts a `data_requests` row with `request_type = export`.
- "기록 삭제" inserts a `data_requests` row with `request_type = delete_history`.

Server workers should process `data_requests` asynchronously and update status/result fields; the mobile client only submits the request.
