# Stack Decision

Date: 2026-05-30

## Decision

Production recommendation: Flutter with native iOS/Android location bridges.

Prototype in this workspace: Expo React Native shell plus a no-build HTML prototype.

Production scaffold in this workspace: `apps/gyeote_flutter`, a Flutter UI shell with Swift/Kotlin native location bridge contracts.

## Why Flutter For Production

This product's highest technical risk is not normal UI delivery. It is reliable background location, geofencing, battery behavior, platform permission review, and separation of ad SDK data from location data. Flutter keeps cross-platform UI velocity while making it practical to own a Swift/Kotlin location bridge for the critical path.

Use Flutter when the team starts production implementation, especially for:

- Android foreground service and OEM battery restrictions
- iOS `Always` location and significant-change behavior
- geofence reliability
- long-running QA on real devices
- strict ad SDK and analytics isolation

## Why Expo Exists Here

The local environment does not expose working `node`, `npm`, `git`, Flutter, Xcode, or Android Studio commands. The Expo app shell is included as a readable MVP structure and a quick way for a web/mobile team to understand the screens, data shape, and permissions. It is not a final technical lock-in.

The no-build prototype at `prototype/index.html` is the quickest artifact for stakeholder review today.

## 2-Week Production Spike

Before committing a full team, run this spike:

1. Build a minimal Flutter app with Swift/Kotlin location bridge.
2. Verify iOS foreground, background, low-power, precise-off, and force-close behavior.
3. Verify Android foreground service, Doze, background location permission, and Samsung/Xiaomi/Pixel behavior.
4. Add AdMob/UMP/ATT in a test build and confirm no precise location payload reaches ad SDK calls.
5. Produce Google Play background-location review video and Apple review notes draft.

Ship production only after this spike passes on real devices.
