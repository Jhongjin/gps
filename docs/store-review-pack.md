# 스토어 심사 패키지

Date: 2026-05-30 — 단계별 등록 절차와 코드 기준 양식 답은 `docs/store-submission-guide.md` 에 있다. 이 문서의 초안 문구는 그 가이드가 그대로 인용한다.

## 제출 포지션

곁에는 가족과 친구가 명시적으로 동의한 시간과 범위 안에서 위치를 공유하는 안전 앱이다. 모든 안전 기능은 무료이며 광고는 SOS, 권한 요청, 초대 수락, 데이터 삭제/내보내기, 동행 종료 화면에 표시하지 않는다.

## Apple App Review Notes Draft

Use this in App Store Connect review notes:

```text
This app uses Location Services for consent-based family and friend safety sharing.

Core flows to test:
1. Create a circle and invite another test user.
2. Accept the invite after reviewing sharing scope.
3. Start Companion Mode for 15 minutes.
4. Put the app in the background and verify the active sharing indicator.
5. End Companion Mode and verify background updates stop.
6. Open Privacy and pause all sharing.

Precise location is used only for safety sharing features. It is not sent to ad SDKs or used for ad targeting. SOS, privacy, permissions, and data deletion flows do not display ads.
```

## Google Play Background Location Declaration Draft

Use this for the permission declaration and review video script:

```text
Background location is used only for Companion Mode and Place Alerts.

Companion Mode lets a user share live safety status with selected circle members for a limited time, such as while traveling home. Place Alerts notify trusted circle members when a selected person arrives at or leaves a saved place.

The app shows an in-app disclosure before requesting background location. Users can stop sharing at any time from the map, companion panel, or privacy screen. Precise location is not used to provide ads or support advertising.
```

## Prominent Disclosure Copy

Display before the Android background location permission request:

```text
곁에는 동행 모드와 장소 알림을 위해 앱이 닫혀 있거나 사용 중이 아닐 때도 location 데이터를 수집할 수 있습니다. 이 위치는 사용자가 선택한 서클 멤버에게 안전 상태, 도착/이탈 알림, 제한 시간 동행 경로를 보여주는 데만 사용됩니다. 정밀 위치는 광고 제공 또는 광고 타게팅에 사용하지 않습니다.
```

## Review Video Checklist

- Fresh install and sign in.
- Create a circle.
- Invite and accept with second account.
- Show location permission rationale.
- Start Companion Mode from a visible user action.
- Show Android foreground service notification or iOS background indicator.
- Background the app and show location still updates for the active feature.
- Show the map renders sharing precision/accuracy rings and stale positions do not appear as live routes.
- Tap `도착 확인` and show Companion Mode stops with a coordinate-free safety check-in.
- Open the place radius preview and show 100m/300m/500m circles without saving a rule.
- Return to app and end Companion Mode.
- Pause sharing from Privacy.
- Open Privacy and show permission snapshot plus battery mode controls.
- Show ads are absent from SOS, permission, privacy, and deletion screens.

## Current Implementation Notes

- Flutter map: real map surface, member pins, route tails, stale-state copy, accuracy/precision rings, and non-saving place-radius preview.
- Native location: Android debug build and iOS source bridge include permission snapshots, companion sessions, SOS fix request, saved-place geofence registration, and encrypted upload queues.
- Backend: Supabase migrations through `011_place_alert_target_rpc.sql` are applied, including coordinate-free check-ins, raw-location select hardening, and guarded place alert creation.
- Ads: ad preferences are stored with precise-location ads forced off; the first safe ad slot is isolated to the history surface and no ad SDK is wired into SOS, permissions, privacy, active companion, or data deletion flows.

## Data Safety / App Privacy Draft

Declare collected data categories:

- Location: approximate and precise location for safety sharing, place alerts, SOS, and companion mode.
- Personal info: display name, account identifier, optional phone/social login provider data.
- App activity: consent events, viewer logs, privacy controls, crash diagnostics.
- Device or other IDs: push token, device id, ad id only when consent and age policy allow.

Declare sharing:

- Location is shared only with user-selected circle members under sharing policy.
- Ad SDK receives no raw location, shared location, circle id, session id, SOS state, or minor/guardian relationship.
- Service providers may process authentication, push notifications, crash reporting, and hosting.

## Required Artifacts

- Privacy policy URL in app and store listing.
- Google Play background location review video URL.
- Test account pair with one existing circle.
- App Store review notes.
- Google Play Data safety form.
- Apple App Privacy answers.
- SDK inventory showing map, push, crash, analytics, and ads.

## Official References

- Apple App Review Guidelines: https://developer.apple.com/appstore/resources/approval/guidelines.html
- Google Play background location permissions: https://support.google.com/googleplay/android-developer/answer/9799150
- Android background location guidance: https://developer.android.com/develop/sensors-and-location/location/background
- Google Play Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
