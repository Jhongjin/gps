# P0 Map Implementation Plan

Date: 2026-05-30

## Goal

Turn the first MVP into a real map-based location product without weakening the privacy promise.

P0 scope:

- real map surface
- member markers
- my current location marker
- place alert radius overlays
- per-circle precision controls
- route-ready data model

## Prototype Choice

The web prototype uses Leaflet with OpenStreetMap tiles so it can run immediately without a paid map key.

This is a prototype convenience only. It lets reviewers inspect interaction, layout, and route/zone behavior now.

The Flutter scaffold now uses `flutter_map` with OpenStreetMap tiles for the first runnable mobile map surface. This keeps the MVP keyless while the Naver native-provider spike is prepared.

## Production Map Choice

For Korea-first production, use Naver Maps SDK as the primary provider.

Why:

- Korean address/POI quality is stronger for domestic family safety use cases.
- Mobile/Web Dynamic Map includes a meaningful free tier for early validation.
- Directions/Geocoding can be phased in after the real-time map experience works.

Fallback candidates:

- OpenStreetMap via `flutter_map`: good for keyless MVP validation, but confirm tile policy, attribution, caching, and traffic limits before public launch.
- Google Maps: stronger global fallback, useful after Korea-market validation.
- Mapbox: strong custom styling and routing, but navigation/trip pricing needs careful control.

## P0 UX Rules

- Map is the primary surface, not decoration.
- The user always sees the current sharing precision.
- Approximate sharing must use radius rings, not fake precise pins.
- Place alert radii are visible before saving.
- Ads are not shown over the map, near SOS, or near privacy-save controls.
- Member route display is explicit and temporary.

## Data Model

Each member needs:

- `id`
- display name
- status: safe, moving, alert, offline
- battery
- last update time
- precision: exact, balanced, area, hidden
- current coordinate
- recent route samples

Each saved place needs:

- `id`
- name
- center coordinate
- radius in meters
- alert rules
- enabled state

## Real-Time Flow

1. Device location worker samples position based on precision, motion, and battery.
2. App writes the newest point to a real-time location channel.
3. The Flutter map receives `CircleRepository`, loads the user's first active circle, and polls `get_circle_latest_locations` until private Realtime is enabled.
4. For each visible member, the map requests a bounded shared-coordinate route tail through `get_circle_member_route_tail`.
5. The map updates marker position, last updated text, multi-member route polylines, and stale-state warnings from `MemberLocationSnapshot` plus route-tail points.
6. Stale positions are not presented as live routes: after 5 minutes the member card moves into `위치 업데이트 대기 중`, and after 30 minutes it shows `마지막 위치만 표시 중`.
7. The map renders precision/accuracy circles before member pins, so exact, balanced, and area sharing have visible trust boundaries.
8. History storage is separate from live presence, with shorter default retention.

Current route tails are rendered from `MapMemberTrack.routeTail`. Demo mode still includes one local route tail; Supabase mode now uses an authorized RPC instead of broad `location_history` subscriptions. If multiple members have route tails, the map renders each path with that member's marker color.

When Supabase is connected but the user has no circle yet, the map hides demo members and shows a first-circle CTA wired to the Circle tab. The Circle tab also switches from demo members to an empty member state until a real invite is accepted.

## Next P1

- 동행 모드: 15분, 30분, 도착할 때까지
- ETA and moving direction
- real route polyline from sampled points
- route playback on history
- sensitive-place blurring around home, school, hospital
