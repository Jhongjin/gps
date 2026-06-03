# P2 Place Alerts Plan

Date: 2026-06-03

## Goal

Make place alerts useful without making them feel like covert monitoring.

## Required Controls

- place radius
- target members
- arrival alert
- departure alert
- late arrival alert
- long stay alert
- quiet hours
- temporary pause

## UX Rules

- Show the radius on the map before saving.
- Explain who receives the alert.
- Explain which member the rule applies to.
- Use neutral copy: `늦음 확인`, not `이탈 감지`.
- Do not put ads near save/delete/radius controls.

## QA Gates

- Place alert creation requires consent for the tracked member or guardian-safe child account handling.
- Home, school, hospital, and workplace are sensitive; avoid exposing exact addresses in unnecessary notifications.
- Alerts must be easy to pause.

## Current Implementation

- `PlaceAlertRepository.listPlaceAlerts` reads circle-scoped rules from Supabase under RLS.
- `PlaceAlertRepository.createPlaceAlert` writes through `create_place_alert_with_targets`.
- `CircleScreen` shows real alert rules when present and a backend-aware empty state when the circle has no rules.
- `MapScreen` includes radius preview for 100m, 300m, and 500m place alerts.
- `MapScreen` can save a place alert when a real Supabase circle and live server member ids are available.
- Direct client inserts into `place_alerts` are blocked; targets are written only by the RPC after same-circle, shareability, and guardian checks.

## Next Implementation

- Register saved alerts with Android Geofencing API and iOS region monitoring.
- Add pause/delete flows through creator-scoped RPCs.
- Add quiet-hours editing after notification delivery rules are implemented.
