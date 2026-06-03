# 곁에 Strategy

Date: 2026-05-30

## Market Read

The market is real, crowded, and still growing.

- iSharing positions itself as a family, child, senior-care, travel, lost-phone, SOS, place alert, driving report, and location-history product. Its Korean site advertises 60 million cumulative downloads and separates features across free, silver, gold, and platinum plans. Free includes basic live location, SOS, messages, and groups; higher plans unlock more place alerts, longer history, street view, driving reports, web access, and priority support.
- iSharing's Google Play listing shows ads plus in-app purchases, 10M+ Android downloads, 234K reviews, and an update on May 25, 2026. The listing says it uses a foreground service for continuous background location and states mutual consent is required.
- Life360 is the category giant. Google Play shows 100M+ Android downloads, ads, in-app purchases, and 2M+ reviews. Life360 reported 97.8M monthly active users, 3.0M paying circles, $143.1M Q1 2026 revenue, and $19.7M advertising revenue, up 329% year over year.
- Built-in competitors matter: Apple Find My and Google Maps/Family Link are free, trusted, and preinstalled or already familiar. Their weakness is that they are less cross-platform, less configurable for family-care workflows, and less monetized into a full safety product.

Sources:

- iSharing Korean site: https://isharingsoft.com/ko/
- iSharing Google Play listing: https://play.google.com/store/apps/details?id=com.isharing.isharing
- Life360 Google Play listing: https://play.google.com/store/apps/details?id=com.life360.android.safetymapd
- Life360 Q1 2026 results: https://life360.gcs-web.com/news-releases/news-release-details/life360-reports-record-q1-2026-results
- Expo SDK reference: https://expo.dev/sdk

## Strategic Opening

Most competitors ask users to accept one of two bad feelings:

1. Pay to unlock the safety feature you actually need.
2. Share highly sensitive location data while wondering who benefits from it.

곁에 should not simply be "Life360 but free." The defensible wedge is:

> A family and friend locator where safety features are never paywalled, and privacy controls are visible enough that people can actually trust them.

## Differentiation

1. Feature parity without paywalls

   Live map, place alerts, SOS, low-battery alerts, inactivity alerts, basic driving safety, web viewer, and history are included for free. Limits can exist for cost control, but not in a way that blocks safety.

2. Privacy dashboard as a core screen

   Every user sees who can view them, who viewed them recently, what precision each circle receives, and when background sharing is active. This turns "tracking" into negotiated sharing.

3. Precision modes per circle

   Users can share exact, neighborhood-level, ETA-only, or hidden status per circle. Parents can require exact sharing only for a child account with verified guardian consent; adult friends default to balanced or ETA-only.

4. Battery-aware update model

   Competitor reviews show battery drain and always-on tracking anxiety. Use motion-aware intervals, geofence-first updates, explicit live sessions, and "ping me now" requests instead of naive constant GPS.

5. Ads that do not contaminate trust

   Ads appear in low-risk surfaces: history summaries, insights, settings support panel, and optional rewarded placements for cosmetic extras. Ads never appear on SOS, permission, invitation consent, live map emergency state, or while driving.

6. Care mode for seniors

   Make "phone inactive", "battery is low", "left safe area", "arrived at clinic", and "call helper" first-class. Existing apps mention this, but the UX can be calmer and more caregiver-oriented.

7. Travel and meet-up mode

   Temporary groups with auto-expiry, airport/hotel places, rendezvous ETA, offline last-known card, and check-in prompts. This is friendlier than permanent family surveillance.

## Ad Model

Do:

- Use contextual ads based on app surface, language, broad region, and non-sensitive cohorts.
- Prefer mediation with family-safe demand controls.
- Offer "ads fund this feature" transparency.
- Support ad-free sponsorships later for schools, elder-care services, travel insurance, or telcos without blocking consumer features.

Do not:

- Sell precise location data.
- Use precise location for ad targeting.
- Show personalized ads to users declared or inferred as children.
- Put ads in emergency, consent, live driving, or permission flows.
- Use rewarded ads to unlock safety-critical features.

Cost control:

- Store raw high-frequency location for short windows only.
- Compress older history into route segments.
- Default to adaptive update intervals.
- Use geofence events and significant-change APIs where possible.
- Cap map tile and realtime fanout cost by circle size and refresh frequency.

## Policy Constraints

Google Play:

- Background location must be core, user-benefiting, clearly disclosed, and approved. Requests solely for ads are denied.
- Apps directed at children have extra restrictions, and Google Play guidance says child-targeted apps should not request device location. This app should be positioned as a family safety tool for guardians and mixed-age households, with child accounts requiring guardian setup and strict Families policy review if child age groups are targeted.
- If children or unknown-age users can see ads, use Families Self-Certified Ads SDKs and child-appropriate ad handling.

Apple:

- Location Services should be directly relevant to app features.
- Notify and obtain consent before collecting, transmitting, or using location data.
- Avoid claiming emergency-service replacement. SOS is a trusted-contact alert, not 911/112 dispatch.
- App Review needs a complete app, working backend, demo account, privacy policy, and clear permission rationale.

Sources:

- Google Play background location policy: https://support.google.com/googleplay/android-developer/answer/9799150
- Google Play sensitive permissions: https://support.google.com/googleplay/android-developer/answer/9888170
- Google Play target audience settings: https://support.google.com/googleplay/android-developer/answer/9867159
- Android background location docs: https://developer.android.com/develop/sensors-and-location/location/background
- Apple App Review Guidelines: https://developer.apple.com/appstore/resources/approval/guidelines.html

## MVP

Phase 0: Prototype

- Interactive no-build prototype.
- React Native shell.
- Product docs, policy checklist, QA matrix, copy deck.

Phase 1: Private Alpha

- Phone/email auth.
- Create circle, invite by link/code.
- Foreground location sharing.
- Manual "share live for 1 hour" sessions.
- Basic map, member status, battery, last updated.
- Explicit privacy dashboard.
- Test ads only in settings/history.

Phase 2: Background Safety

- Background location declaration and review assets.
- Place alerts.
- Low battery and inactivity alerts.
- SOS trusted-contact push.
- Route history with retention controls.

Phase 3: Public Launch

- Korea-first and English-ready.
- Family/caregiver positioning, not spy/tracker language.
- Android closed test first, then iOS TestFlight.
- Measure activation by circles with at least two members and one successful place alert.

## Success Metrics

- Circle activation: 2+ members sharing within 24 hours.
- Trust activation: percent of users who open privacy dashboard and set a precision mode.
- Battery complaint rate: app store reviews and in-app survey.
- Alert reliability: place alert fired within target window.
- Ad tolerance: ad impressions per DAU, ad complaint rate, retention delta.
- Safety engagement: SOS setup completion and trusted-contact test completion.
