# Map SDK Plan

Date: 2026-05-30

## Recommendation

Use Naver Maps as the primary Korea launch provider, keep Google Maps and Mapbox behind the `MapProviderController` abstraction, and use `flutter_map` with OpenStreetMap as the keyless MVP map until the Naver native spike is complete.

## Why Naver First

- Korea-first location apps need local POI, address, traffic, transit, and user expectations that are stronger in Naver's ecosystem.
- NAVER Cloud Platform documents Mobile Dynamic Map SDKs for Android and iOS.
- Naver Maps SDK supports vector rendering, multiple map types/layers, overlays, markers, paths, and event handling.

## Provider Roles

| Provider | Role | Risk |
| --- | --- | --- |
| Naver Maps | Korea MVP default | Need native/Flutter plugin spike and NCP billing guardrails |
| Google Maps | Global fallback and Android familiarity | Korea local directions/POI expectations may be weaker |
| Mapbox | Custom visual styles and route rendering fallback | MAU-based pricing needs close monitoring |
| flutter_map/OSM | Keyless Flutter MVP | Tile policy, attribution, caching, and public-traffic limits need review before launch |
| Leaflet/OSM | Web prototype only | Not production mobile SDK path |

## Pricing Snapshot

Checked on 2026-05-30. Pricing can change, so re-check before production billing setup.

- Naver Maps Mobile/Web Dynamic Map: official NCP pricing currently lists 6,000,000 free monthly uses for one representative account and 0.1 KRW per use after that.
- Google Maps Platform Maps SDK: official Google pricing currently lists the Maps SDK free usage cap as unlimited, while Routes/Places/Geocoding are separate billable SKUs.
- Mapbox Maps SDKs for Mobile: official Mapbox pricing currently lists 25,000 MAU free, then tiered per-1,000 MAU pricing.

Cost conclusion: draw live route tails from our own location samples first. Avoid Directions, Roads, Search, and reverse geocoding APIs until the product has usage telemetry and budget alerts.

## MVP Integration Order

1. Keep `MapProviderController` as the app boundary.
2. Keep the current `flutter_map` screen for keyless MVP review with markers, OSM attribution, and sampled route polylines.
3. Build a native Naver map spike on iOS/Android with markers, circles, polylines, and camera focus.
4. Verify Flutter plugin maturity or use a native platform view if the plugin blocks required interactions.
5. Add provider key injection through environment/build config, never hard-code keys in Dart.
6. Render only shared coordinates, never raw coordinates.
7. Add marker clustering only after real family-circle density testing.
8. Add route tail rendering from companion session samples.
9. Add Google/Mapbox fallback only after Naver MVP passes store review and device QA.

## Cost Controls

- Gate map refreshes by viewport, active tab, and app lifecycle.
- Avoid reinitializing the map widget on tab switches.
- Cache place names and reverse geocode results.
- Do not use paid Directions APIs for simple route tails; draw user-sampled polylines first.
- Add Remote Config for provider selection and feature flags.

## References

- NAVER Cloud Maps overview: https://guide.ncloud-docs.com/docs/en/maps-overview
- NAVER Maps Android SDK: https://guide.ncloud-docs.com/docs/en/maps-android-sdk
- NAVER Maps SDK features: https://navermaps.github.io/ios-map-sdk/guide-en/0.html
- NAVER Cloud pricing: https://www.ncloud.com/charge/region
- Google Maps Platform pricing: https://mapsplatform.google.com/pricing/
- Google Maps core services pricing list: https://developers.google.com/maps/billing-and-pricing/pricing
- Mapbox pricing: https://www.mapbox.com/pricing
