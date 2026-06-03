# P1.5 Check-In And Status Plan

Date: 2026-05-30

## Goal

Reduce anxiety without making the product feel like surveillance.

P1.5 adds:

- `도착 확인`
- automatic arrival notification later
- battery and signal explanation
- stale-location copy

## UX Rules

- Use `무사 도착`, `확인 필요`, `신호가 잠시 약해요`.
- Do not use `감지`, `추적`, `감시`, or guaranteed safety language.
- Check-in sends a small reassurance update, not a full route export.
- If location is stale, explain likely causes: battery, signal, permission, or device offline.

## Product Behavior

Manual check-in:

1. User taps `도착 확인`.
2. Active companion session ends.
3. Circle receives a short reassurance event.
4. Route tail is no longer live.

Automatic check-in later:

- trigger when the member enters a saved place radius
- wait briefly to avoid false positives
- notify only circles that already have permission
- do not show ads in the flow

## QA Gates

- Check-in must not reveal more precision than the current sharing mode.
- Check-in must be undoable or followed by a clear sent state.
- A stale location must never look like a live exact location.
- Battery/offline copy must reduce blame and confusion.

## Current Implementation

- Manual `도착 확인` is available from the companion mode panel while a session is active.
- `perform_check_in` creates a coordinate-free `check_in_events` row and ends the active companion session.
- `CircleScreen` shows recent safety check-ins as `무사 도착`, `확인 필요`, or `신호가 잠시 약해요`.
- `HistoryScreen` includes recent check-ins in today's activity feed.
- Automatic arrival check-in remains deferred until place radius, dwell-time, target consent, and notification QA are in place.
- Map member cards now separate freshness states: after 5 minutes they show `위치 업데이트 대기 중`, and after 30 minutes they show `마지막 위치만 표시 중`.
- Stale members do not render live route tails, and low-battery states explain that updates can be slower instead of blaming the member.
