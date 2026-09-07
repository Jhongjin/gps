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

## Verified (2026-09-06)

Flutter SDK found at `D:/Codex/toolchains/flutter`.

- `flutter analyze` — No issues found
- `flutter test` — 86/86 passing
- `python tools/check_hardcoded_strings.py` — 0 hardcoded literals
- `python tools/check_rpc_contract.py` — 17 RPCs, 63 arguments, all matching
- `gradlew :app:testDebugUnitTest` — 14/14 Kotlin tests (8 snapshot, 6
  Robolectric render). See `docs/ci-validation.md` for the JDK 25 gotchas.
- `flutter build apk` — debug and release both link. The release APK was opened
  and checked: R8 and resource shrinking keep the widget provider, its intent
  filters, layout, drawables and strings.
- `flutter build web --release` — succeeds, and the shell was checked in a browser

**Correction to an earlier note here.** This file used to say `flutter build
apk` fails in this workspace with `ProcessException: access denied` from the
native-assets hook runner, and that `flutter config --no-enable-native-assets`
was the fix. Neither holds. The denial comes from the agent tool sandbox
blocking process spawns, not from Flutter or from this project — the same
commands run normally outside it, and `flutter config --list` shows
`enable-native-assets: (Not set)`, so no global SDK setting was left changed.

Fonts are bundled now: `Pretendard-Regular.otf` and `-Bold.otf` under
`assets/fonts` (SIL OFL 1.1), and the theme names `Pretendard` again. That also
resolved the tofu glyphs in the web build — the earlier CanvasKit/Noto-slice
diagnosis was only half of it; the real cause was that no font shipped at all.
Noto subsets for `ja`/`hi`/`ar` are still open.

## Movement and ETA (2026-09-06)

The map's route tail carried coordinates only, so nothing downstream could tell
how fast anyone was going. The server had been sending `recordedAt` on every
`MemberRoutePoint` all along and the mapping layer dropped it — the same shape
as the discarded `batteryPercent`: a fact already in hand, thrown away on the
way to the screen. `MapMemberTrack.routeTail` is `List<MapRoutePoint>` now, and
`routeLine` is what the polyline takes.

`lib/src/features/map/movement.dart` derives speed, heading, and time-to-arrive
from those samples. It holds no strings — it produces facts, and the screen
words them, for the same reason `GyeoteTone` exists.

What it refuses to do matters more than what it computes:

- **No routing service.** A directions API means sending a member's coordinates
  to a third party, which is not a trade this app makes for one feature. The
  estimate is straight-line distance times a 1.35 detour factor, and the meetup
  card says so on screen.
- **Stationary GPS jitter is not walking.** Path length alone reads a phone
  sitting on a table as a slow walk. Net displacement under 30 m is reported as
  stopped.
- **"Unknown" and "stopped" are different values.** With fewer than two samples
  in the last ten minutes the line is not drawn at all.
- **Minutes appear only while approaching.** Moving away or sideways shows
  distance or a direction instead, because a remaining-time figure computed
  against a path someone is not on is worse than no figure.
- **Nothing is drawn for a stale position.** Writing "walking" under a
  twenty-minute-old fix invents a present that does not exist.

Surfaces: the member sheet gets a movement line with the soonest meetup as its
destination, and the meetup card shows the viewer's own ETA. `meetupNoneBody`
had been promising this since the meetup feature shipped.


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

## Private places, and the raw coordinates that were never read (2026-09-06)

Two things landed together because either one alone is theatre.

**The precise fix was being uploaded.** `latest_locations` and
`location_history` have carried `raw_lat`/`raw_lng` since `001`, and no RPC,
view, policy or trigger in the schema ever read them. The comment on
`get_circle_member_route_tail` says "Raw coordinates stay server-side" — the
design intent was that they stay on the *device*. In practice a user could set
sharing precision to area-only or hidden and the exact coordinate still went up
and sat there for thirty days. What the screen promised and what the database
held were different things.

`018_drop_raw_coordinates.sql` drops the four columns. The Dart and Kotlin
upload paths stopped sending them first — that order matters, because reversing
it makes older clients fail their inserts, and a failed insert is a location
upload that silently stops. `tools/check_precise_coordinates.py` fails CI if
either column or `rawCoordinate` reappears in an upload-row builder; it was
proved by reintroducing the column and watching the check fail.

**Private places.** `PrivatePlace` marks a home, school, or clinic. Inside one,
the shared coordinate snaps to the place's centre.

- **Snapping, not rounding.** Rounding builds a grid: different points inside
  one house land on a handful of distinct values, and the original position is
  recoverable from their distribution. Snapping makes every point in the radius
  produce the identical value, which cannot be inverted. It is also idempotent,
  which is what lets the masking run twice safely.
- **Masking happens in native, before the coordinate exists in a payload.**
  The upload queue is native and never passes through Dart, so Dart-only
  masking would leave the actual upload untouched. `GyeoteLocationCore
  .sharedCoordinate` applies it, and *before* the precision reduction — the
  other order lets a rounded point drift outside the radius and escape masking.
  `LocationBridge` applies it again on the way in, as the only line of defence
  on a platform without the native path.
- **The list never leaves the device.** There is no table for it. A list of the
  places someone wants hidden is a more concentrated disclosure than any single
  coordinate it was meant to hide. It lives in `SharedPreferences`, and the cost
  — re-adding them on a new device — is worth paying.
- **Names never cross the channel.** `toChannel()` sends latitude, longitude,
  and radius. Native does not need a name to mask a coordinate, and "clinic" or
  "shelter" is exactly the kind of string that ends up in a crash report.
- **Registration uses the raw fix, not the shared one.** Centring on an
  already-masked coordinate would offset the radius so the real place could sit
  outside it.

The 안심 screen has the card; adding uses the current position rather than a map
picker, because whoever sets this up is usually standing in the place.

## The viewer log was a promise with nothing behind it (2026-09-07)

`record_viewer_log` has been in `003` since the beginning. Nothing called it.
Nothing read the log either. Meanwhile the sign-in screen carried a trust badge
saying the app shows who looked at your location, the member sheet had a "오늘
이 위치를 본 사람" row, and the 안심 screen rendered **three demo names with
fabricated timestamps** as if they were a real viewing record, behind a "전체"
button wired to `onPressed: () {}`.

Fabricating a privacy record is worse than having none. It is now real:

- `recordViewerLog` fires when a member sheet opens — that is the moment someone
  actually looks. Your own location is excluded, or the count stops meaning
  "times someone else looked". A failure never blocks the sheet: a missing log
  line is bad, but not being able to see where your family is, is worse.
- `019_viewer_log_read_rpc.sql` adds `list_viewer_log`, scoped to `auth.uid()`
  as the *viewed* profile, so nobody can read anyone else's log. It goes through
  an RPC rather than a direct select because attaching the viewer's name means
  joining `profiles`, which is a different policy's problem.
- The 안심 card shows the real last three and opens a full sheet. In demo mode it
  says the record starts once you join a circle, instead of inventing names.
- **A load failure is never drawn as "nobody looked."** That is the dangerous
  failure on this screen: it would tell someone they were not watched when the
  app simply could not check. There is a test for it.

Five ARB keys that existed only to feed the fake card were deleted.

## Route playback (2026-09-07)

The last item on the P1 list from `p0-map-implementation.md`. It is also the
most surveillance-shaped feature in the product, which decided how it is built.

`RoutePlaybackTimeline` is pure and interpolates **over wall-clock time, not
sample index**. Index-based playback runs a ten-second gap and a three-hour gap
at the same speed, which erases where someone actually spent their day — in a
screen whose whole purpose is to show that, it is a distortion of fact, not a
rendering detail.

Gaps are not drawn as travel. When samples are more than twenty minutes apart
the app does not know what happened in between, so the marker holds at the last
known position, the screen says so, and the distance total excludes the gap —
otherwise a phone that was off for three hours produces "20 km travelled" out of
one straight line.

The playback surface states that replaying someone else's movement appears in
their viewing record, which is only true because the viewer log now works. The
history tab's entry point replays **your own** day; viewing another member
starts from their member sheet, so the default framing is not "watch someone".

Coordinates come back already reduced by sharing precision and already masked by
private places, so playback inherits both. It shows what was stored; it does not
reconstruct anything finer.

## Screen-reader labels now say what the ring draws (2026-09-07)

The marker ring encodes battery as fill and staleness as colour. Sighted users
read it; nothing read it aloud. `a11yBatteryLevel`, `a11yStaleLocation` and
`a11yAttentionBadge` had been written for exactly this and sat unused in ARB.
`MapMemberTrack.semanticsLabel` / `semanticsDetail` now carry name, status,
staleness and battery, and every member surface — marker, avatar rail, sheet
row — uses them; the attention badge reads as a sentence instead of a bare
number. `test/semantics_test.dart` asserts the labels reach the semantics tree,
because a string existing and a string being spoken are different things.

`meetupNone` became the empty-state heading it was written for; `pendingLabel`
had no consumer and was removed. No ARB key is unreferenced now.

## Contrast was written down but never measured (2026-09-07)

The design skill's §6 checklist said `muted` on `surfaceAlt` "must be measured".
Measuring it: in light mode `muted` sat at 3.5–4.0:1 on every ground it is used
on, `warm` at 3.2–3.7 (the attention badge is warm-on-warmSoft at 11px), `brand`
on `brandSoft` at 4.1, `alert` on `alertSoft` at 4.47. Sixty-three captions were
below the body-text floor. Dark mode passed everywhere.

Four light tokens were darkened by the smallest amount that clears 4.5:1 on all
their grounds — `muted` #736A60, `warm` #9A5E0E, `brand` #007B57, `alert`
#BE3C2C — and the skill table now carries those. `test/contrast_test.dart`
measures every text × ground pair in both themes plus each status colour on its
own soft ground, so the next token change fails a test instead of a checklist.

## Quiet hours: the fifth display-as-identity bug, and a feature nothing enforces

`PlaceAlertQuietHours` persisted the *rendered* preset label and the cycle
function compared it against the current locale's translation. A Korean
creator's "야간" never equals an English member's "Night", so cycling from
another language always fell back to the first preset. It now stores a
`preset` key; the label is produced from the key in the reader's locale, and
rows written before this have their preset inferred from start/end times —
a locale-free fact — never from the label. `quiet_hours` is `jsonb`, so no
migration was needed.

It also stored `timeZone: 'Asia/Seoul'` for every device on earth. That value
is gone: there is no source for an IANA zone name in the app yet, and a wrong
value is worse than a missing one.

While doing this: **nothing enforced quiet hours.** No Kotlin path and no SQL
function read the field. It was stored, displayed, and cycled, and had no
effect on any notification. Fixed in the next section.

## Quiet hours are enforced now, natively (2026-09-07)

Geofence transitions are handled by `GeofenceBroadcastReceiver`, which runs
with the app dead, so the quiet window has to reach native storage rather than
Dart memory. `GeofenceSpec` carries `quietStart`/`quietEnd`; `registerGeofences`
persists them per request id in `SharedPreferences`; the receiver asks
`GyeoteQuietHours.isQuietNow` before posting.

Inside the window the alert is **not dropped** — it goes to a second channel,
`gyeote_place_alerts_quiet`, at `IMPORTANCE_LOW`. A safety app cannot discard
"your child arrived" because the parent was asleep; it can decline to wake them.
Two channels rather than one because Android freezes a channel's importance
after creation, and a separate channel is also something the user can tune in
system settings.

The overnight case is the one that matters: 22:00–07:00 is the common preset,
and a naive `start <= now < end` never fires for it. `Window.contains` handles
the wrap, and the Robolectric test pins 23:00, 03:00, 22:00 inside and 07:00,
12:00 outside. Malformed times produce no window at all rather than a wrong one.
If several overlapping geofences fire together and any one is quiet, the
notification is quiet — the other way round makes the setting untrustworthy.

Along the way the native notification strings (place-alert title and bodies,
foreground-service statuses, the upload-auth error) were Korean literals in
Kotlin. They are in `res/values/strings.xml` (en) and `values-ko` now, and
`tools/check_hardcoded_strings.py` scans Kotlin under `android/app/src/main`
as well as Dart, so the widget and the notifications cannot silently re-pin
themselves to one language.

## iOS caught up, and is now verifiable from this machine (2026-09-07)

Every privacy change this week had landed on Android and Dart only. iOS was
still uploading `raw_lat`/`raw_lng` — after `018` drops those columns, every
iOS insert is rejected and location sharing on iOS stops silently. It also had
no private-place masking, no quiet hours, and Korean-only notification strings.

`AppDelegate.swift` now: masks the shared coordinate inside a private place
before precision reduction (same ordering argument as Android); handles
`setPrivatePlaces` by merging only the places; persists quiet windows in
`UserDefaults` at `registerGeofences` and delivers place alerts inside a window
without sound at `.passive` interruption level — not dropped; picks
notification copy from an in-code en/ko table keyed like the Android
resources; and sends no raw coordinate in the upload row.

The part that matters for the future is *how it was verified*. The logic that
carries the privacy guarantees lives in a Foundation-only `GyeotePortable`
section at the end of the file. `tools/check_ios_logic.py` extracts exactly
that section from the shipped source, compiles it with Swift and runs
`tools/ios_logic_tests.swift` against it. On this Windows machine that needed
the Swift toolchain plus VS Build Tools for the UCRT headers; both are
installed now and the check passes. Flipping the overnight-window `||` to `&&`
makes it fail, so it is measuring something. It runs in CI on Linux Swift.

`tools/check_precise_coordinates.py` now inspects the Swift `rowFromPayload`
body as well, and `tools/check_hardcoded_strings.py` scans Swift, with the
`"ko":` rows of the string table as the one exemption.

What this does **not** verify: anything touching CoreLocation, UIKit or
UserNotifications — region monitoring, the notification request itself,
`interruptionLevel`. Those still need a Mac. The boundary is explicit in the
file: the portable section may not reference those frameworks, and the check
fails if it does.
