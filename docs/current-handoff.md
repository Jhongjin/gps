# Current Handoff

Date: 2026-09-06

## Migration State (2026-09-06)

The blocker moved. `supabase` CLI is on PATH now (2.109.0), so the SQL-Editor
workaround is no longer needed. What is still missing is credentials — no
`.env.local`, and the DB password is deliberately not stored in one.

`tools/apply-migrations.ps1` makes the apply a two-step: it links, prints the
local-vs-remote migration list, and stops. `-Apply` pushes. Whoever holds the
credentials runs it.

Before pushing, read `supabase/README.md`. `007` through `011` were applied by
hand in the SQL Editor and are almost certainly unrecorded in the remote
migration table, so a naive `db push` would try to re-run them and `001` along
with them.

`016_quick_reply_statuses.sql` joins the pending set. It widens the
`check_in_events` status constraint and rewrites `perform_check_in` — the
function body is copied from `009` verbatim with three edits, because a first
attempt to rewrite it from memory silently dropped the dedupe-key generation,
the `end_reason`, and the `sharing_precision` column type.

`017_meetups.sql` adds the meetup object: a place, a time, RSVPs, and expiry.
Expiry is a read-time predicate (`is_meetup_over`) rather than a worker, because
a stalled worker would leave sharing on — which is the exact failure the feature
exists to prevent. `list_active_meetups` applies the predicate, so a meetup
disappears on time even if nothing is running.

Quick replies work against the old schema too: the three new statuses simply
fail the constraint until `016` lands, and the UI surfaces that as a send
failure rather than corrupting anything.

Meanwhile `tools/check_rpc_contract.py` closes the gap that unapplied migrations
actually open. RPC names and argument names are plain strings on both sides —
nothing in Dart or SQL checks that `set_place_alert_enabled(alert_id, is_enabled)`
in the app matches the function in the migration. The check compares all 13 calls
and their 47 arguments, and it runs in CI. They match today.

## Design System Rewrite — "귀갓길" (2026-09-05)

The visual system and the map shell were rebuilt. Rules now live in
`.claude/skills/gyeote-design/SKILL.md`; `DESIGN.md` carries the intent and
defers to the skill where they disagree.

What changed:

- `GyeotePalette` is a `ThemeExtension` with complete light and dark values.
  `GyeoteColors` (the old light-only static class) is gone — all 179 call sites
  were migrated to `context.palette`, and `themeMode` is now `ThemeMode.system`.
- Models no longer hold `Color`. `MapMemberTrack.tone` and `_HistoryEvent.tone`
  carry `GyeoteTone`, resolved at paint time. Holding a `Color` in a model was
  what pinned those screens to one theme.
- Retired rules: the 8px radius cap, hairline borders everywhere, w800/w900
  weights, the sage canvas, and deep-green markers (which sank into OSM's green
  landcover — a legibility defect, not a taste one).
- The map is a full-bleed `Stack` with a `DraggableScrollableSheet` instead of a
  360px card inside a `ListView`. Place-alert and companion panels moved into the
  sheet, so no functionality was dropped. Five overlay chips were removed from
  the map surface; their information moved to the sheet status line.
- Markers encode state in one ring: fill = battery, style = sharing precision
  (dashed for area sharing), color = state. `MapMemberTrack.batteryPercent` was
  added because the snapshot already carried it and the model was discarding it.
- Member detail sheet added — marker, avatar rail, and list rows all open it.
  Precision is shown as a request, not a switch, and the viewer log sits at the
  bottom of every member sheet.
- SOS is press-and-hold (600ms) plus a cancellable 3s countdown. It could
  previously fire on a single tap.

## i18n Foundation (2026-09-05)

- `flutter_localizations` + `intl` wired; ARB at `lib/l10n/app_ko.arb` and
  `app_en.arb`, generated into `lib/l10n/`. The shell is built under a `Builder`
  so `AppL10n.of(context)` reaches the navigation labels.
- `RegionSettings` keeps emergency numbers, distance units, and clock format as
  **region values, not translated strings**. Translating `112` into German
  produces a number that is wrong in Germany. It keys off country first, then
  language.
- Migrated so far: app shell, `SafeAdSlot`, `SosButton`/countdown, member sheet.
- `tools/check_hardcoded_strings.py` freezes the remaining 488 hardcoded Korean
  literals as a baseline and fails CI when the count grows. Wired into
  `.github/workflows/validate.yml`.

**The extraction is finished.** All 530 Korean literals are in ARB
(396 keys, `ko` and `en`), and the baseline in
`tools/hardcoded-strings-baseline.json` is empty, so CI now fails on the first
new literal rather than allowing a budget.

The migration surfaced the same bug shape four times, each one a display value
reused as an identity:

- `MapMemberTrack.tone` held a `Color`, pinning those screens to one theme.
- `MapMemberTrack.status`/`meta`/`safetyNote` held rendered Korean, pinning them
  to one language. They are computed from facts now.
- `_HistoryEvent.type` held a display string and the filters compared against it
  (`event.type == '확인'`), so translating the label would have silently matched
  nothing. It is an enum now.
- Three status banners picked their error color by testing the message for
  '못했습니다' / '대기 중'. Failures would have rendered in the success color once
  translated. They carry explicit flags now.

The rule is in the design skill: never use the same value for what you show and
what you branch on.

Two problems need a schema change and are documented at their call sites rather
than half-fixed:

- `PlaceAlertQuietHours.label` is persisted and then compared against a
  translated string when cycling presets, so a member using another language
  cycles back to the first preset. The preset key should be stored instead.
- Quiet hours hardcode `Asia/Seoul`, so the quiet window lands at the wrong
  local time everywhere else. This needs the device's real IANA zone.

## Android Home Widget (2026-09-06)

`GyeoteCircleWidget` shows who is sharing right now without opening the app.
Classic `RemoteViews` rather than Glance — this module has no Compose, and
adding it for one widget is not worth the build weight.

Two decisions are load-bearing.

**The widget never carries a location.** It sits on a home screen and, on many
devices, a lock screen, where anyone holding the phone can read it. So the
payload has no coordinate fields at all: `HomeWidgetSnapshot` does not define
them, and `GyeoteWidgetSnapshot.fromChannel` reads only name, status, and tone,
discarding anything else the channel sends. Tests on both sides assert that a
payload containing latitude, longitude, or accuracy still produces a snapshot
with none of it.

**The widget says how old it is.** Refreshes are push-driven — the app
broadcasts when it receives new tracks — but a push-only widget freezes at
"1 min ago" the moment the app is killed, and a safety widget that shows stale
reassurance as current is worse than one that shows nothing. Every snapshot
carries `updatedAtMillis`, the subtitle renders the age, and past thirty minutes
it says it is waiting for an update instead. `updatePeriodMillis` is set to the
system minimum purely so that age keeps aging without the app.

Kotlin unit tests run in CI via `:app:testDebugUnitTest`.

## Verified (2026-09-05)

Flutter SDK found at `D:/Codex/toolchains/flutter`.

- `flutter analyze` — No issues found
- `flutter test` — 15/15 passing (was 4; added locale, map shell, member sheet,
  SOS-safety, and region-settings tests)
- `python tools/check_hardcoded_strings.py` — 0 hardcoded literals
- `python tools/check_rpc_contract.py` — 17 RPCs, 63 arguments, all matching
- `gradlew :app:testDebugUnitTest` — 8/8 Kotlin tests
- `gradlew :app:processDebugResources` — manifest, layouts, and widget metadata

A note for whoever builds next here: `flutter build apk` fails in this
workspace with `ProcessException: access denied` from the native-assets hook
runner spawning `cmd.exe`. It is an environment restriction, not a code fault.
Gradle tasks run fine with `-x :app:compileFlutterBuildDebug`, which is how the
Kotlin and resource verification above was done. The full APK link step has not
been run here.
- `flutter build web --release` — succeeds, and the shell was checked in a browser

Known preview-only artifact: a couple of Hangul glyphs render as tofu in the web
build. CanvasKit fetches Noto Sans KR *slices* from `fonts.gstatic.com` at
runtime and some slices arrive incomplete. Android/iOS use the system Korean
font and are unaffected. Related: no font files are bundled at all, so the
theme no longer names `Geist`/`Pretendard` — bundling them (plus Noto subsets
for ja/hi/ar) is still open.


## Latest Preview

`http://127.0.0.1:4174/?v=1780229000000`

## Verified

- `flutter analyze`
- `flutter test`
- `tools/build-flutter.ps1 -Target web`
- `tools/build-flutter.ps1 -Target android-debug`

Android debug APK builds successfully. iOS source is implemented but not compiled in this Windows workspace.

## Implemented In Flutter

- Real map with OSM tiles, member markers, route tails, precision/accuracy rings, stale-state copy, and place-alert radius creation flow.
- Circle creation, invites, invite acceptance, empty states, place alert read state, and check-in status card.
- Companion mode session creation, consent, activation, native session config, manual `도착 확인`, and session ending.
- Active companion route tails are separated from ordinary map route tails in local code and SQL.
- Android encrypted bounded native upload queue and iOS source implementation for the same queue.
- Android saved place alerts register through Google Play Services Geofencing API and emit native enter/exit transition events.
- Place alert pause/resume/delete UI and creator-scoped RPC SQL are implemented locally.
- Place alert creation supports quiet-hours presets and circle rule cards display the saved summary.
- Saved place alert quiet-hours presets can be cycled from `CircleScreen` through local creator-scoped RPC SQL.
- Native place-alert enter/exit events update the in-app status copy without showing internal geofence ids.
- Android native place-alert transitions also show a privacy-safe local notification when notification permission is granted.
- iOS region enter/exit callbacks schedule matching privacy-safe local notifications in source; this Windows workspace cannot compile iOS.
- Authenticated Flutter clients record native place-alert transitions through local `015_place_alert_event_ingest_rpc.sql` RPC SQL.
- A `SafeAdSlot` placeholder is isolated to the history surface after the activity list; safety-critical screens remain ad-free.
- Native permission snapshot surfaced in Privacy/안심 screen on Android/iOS.
- History safety summary plus filters for `전체`, `확인`, `장소`, `동행`, and `데이터`.
- Widget smoke tests for shell, history filters, and privacy permission/battery controls.

## Backend State

Applied in production Supabase:

- migrations through `011_place_alert_target_rpc.sql`

Verified in production Supabase:

- `check_in_events_installed = true`
- `perform_check_in_installed = true`
- `list_circle_check_ins_installed = true`
- `latest_locations_raw_select_hardened = true`
- `broad_latest_locations_select_removed = true`
- `check_in_session_link_guard_installed = true`
- `check_in_session_subject_predicate_installed = true`
- `check_in_session_error_installed = true`
- `check_in_session_expiry_guard_installed = true`
- rollback-only RLS/RPC negative tests: 8 assertions passed
- `place_alert_create_rpc_installed = true`
- `place_alert_create_rpc_granted = true`
- `direct_place_alert_insert_blocked = true`
- `broad_place_alert_insert_removed = true`
- `minor_guardian_check_installed = true`
- `shareability_check_installed = true`
- rollback-only place alert negative tests: 8 assertions passed

Current local limitation:

- `supabase` CLI and `psql` are still not configured in this workspace; production DDL was applied through the Supabase SQL Editor browser session.
- `012_place_alert_management_rpcs.sql`, `013_active_companion_route_tail_rpc.sql`, `014_place_alert_quiet_hours_rpc.sql`, and `015_place_alert_event_ingest_rpc.sql` are prepared locally but not applied to production yet. The Supabase SQL Editor is visible in the in-app Browser, but automated editor input is blocked by the Browser virtual clipboard limitation.

## Next Backend Priority

1. Apply the pending production SQL bundle, then run verification/negative tests for `012` through `015`.
2. Add push notification delivery rules after event ingestion is production-applied.
3. Add real-device Android/iOS QA for geofence event delivery and dedupe.
