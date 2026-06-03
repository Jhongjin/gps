# P1 Companion Mode Plan

Date: 2026-05-30

## Product Decision

Companion mode is session-based, not always-on tracking.

Required properties:

- explicit start
- visible viewer and sharing duration
- 15 minutes, 30 minutes, or until arrival
- one-tap end
- approximate ETA copy such as `약 12분`
- short route tail only during the active session
- no ads over the map, SOS, permissions, or privacy controls

## UX Contract

The app should say:

- `함께 이동 중`
- `공유 동의됨`
- `약 12분 예상`
- `언제든 종료할 수 있어요`

Avoid:

- tracking
- surveillance
- watching
- movement detected
- precise arrival guarantee

## Screen Behavior

Collapsed panel:

- selected member
- approximate ETA
- last update
- live state

Expanded panel:

- companion duration
- progress
- route tail
- speed/network/battery status
- end companion mode

## Data Handling

Live route samples are session data. They should expire quickly unless the user explicitly saves them to history.

Current implementation note: the Flutter map now creates a Supabase companion session for the active circle, records the current user's consent, activates the session, and sends `companionSessionId` to the native location bridge. Android and iOS native upload queues attach that id to history rows during the active session.

Default retention proposal:

- live presence: seconds to minutes
- companion route tail: active session only
- daily safety summary: 30 days by default
- raw route export/delete: user controlled

## QA Gates

- The active session always shows who can view location.
- The session end button is visible without scrolling.
- ETA copy is approximate.
- Route display turns off when the session ends.
- Background location stops or returns to normal interval after the session.
- Ad SDK never receives exact location, live route, SOS, or permission state.
- Minor accounts require guardian-safe consent and ad restrictions.
