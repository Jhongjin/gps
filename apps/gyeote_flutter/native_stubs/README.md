# Native Stubs

These files are not wired into a Flutter project yet because this machine does not have the Flutter SDK.

After running:

```bash
cd apps/gyeote_flutter
flutter create --platforms=ios,android .
```

move or adapt:

- `ios/GyeoteLocationBridge.swift` into `ios/Runner/`
- `ios/InfoPlist.location.snippet.xml` keys into `ios/Runner/Info.plist`
- `android/GyeoteLocationBridge.kt` into `android/app/src/main/kotlin/.../`
- `android/AndroidManifest.location.snippet.xml` entries into `android/app/src/main/AndroidManifest.xml`

The stubs define the same channel names used by Dart:

- `app.gyeote/location`
- `app.gyeote/location_events`
