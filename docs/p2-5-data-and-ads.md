# P2.5 Data Rights And Ads Plan

Date: 2026-05-30

## Goal

Keep the free ad-supported model compatible with user trust.

## Data Rights

Required controls:

- export location history
- delete location history
- delete account
- pause all sharing
- leave circle
- block person
- change retention period

Default retention:

- live presence: transient
- companion route tail: session only unless saved
- history: 30 days
- viewer log: 30 days

Current history surface:

- `HistoryScreen` has activity filters for `전체`, `확인`, `장소`, `동행`, and `데이터`.
- The safety confirmation summary is ad-free; future ad placements should stay in low-risk history/insight areas.

## Ads

Rules:

- no precise-location ad targeting
- no ads in SOS, permission, privacy save/delete, onboarding consent, or active companion mode
- `SafeAdSlot` is available for low-risk surfaces such as history after the activity list; it does not receive raw/shared coordinates or member identifiers.
- personalized ads default off for minors
- sensitive categories blocked
- rewarded ads can reduce ad frequency, never unlock safety features

## QA Gates

- Ad settings must be understandable before consent.
- Deleting history must not require watching an ad.
- Ad SDK payloads must be audited before release.
