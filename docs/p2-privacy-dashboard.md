# P2 Privacy Dashboard Plan

Date: 2026-05-30

## Goal

Make trust inspectable.

The user should understand in one screen:

- who can see me
- which circle can see me
- what precision they receive
- when sharing expires
- who viewed me recently
- how to stop sharing immediately

## Required Controls

- per-circle precision
- per-person block/remove
- sharing expiration
- pause all sharing
- view log
- history delete/export
- ad personalization off

## UX Rules

- Privacy controls must not be buried under account settings.
- Save/stop/delete flows must not contain ads.
- `숨김` must stop live updates and make the UI visibly non-live.
- Viewer logs should be easy to understand but not accusatory.

## Next Implementation

- Replace static privacy rows with real circle/member data.
- Add per-circle precision editor.
- Add viewer log retention setting.
- Add delete/export entry point.

## Current Implementation

- `PrivacyScreen` includes a local battery-mode segmented control: `실시간`, `균형`, `절전`.
- The same screen reads `LocationBridge.getPermissionSnapshot()` on Android/iOS and displays foreground, background, precise, and notification permission state.
- Copy avoids forcing OS settings; low-power and permission limits are framed as reasons updates may be slower.
