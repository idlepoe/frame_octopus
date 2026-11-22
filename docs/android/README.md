# Frame Octopus for Android

Android beta of the Windows contact-sheet studio, implemented in the same Flutter project. The original `C:\Workspace\mosaic` project is unchanged. Processing models, scene layout, capacity estimation and FFmpeg composition are shared with Windows. Android uses its own entry screen, video player and gallery bridge.

## Workflow

1. Tap the large selection area and choose videos from the system gallery picker (up to 50).
2. Keep the 20 MB per-file default or choose another limit; choose animated WebP or still PNG.
3. Tap **Create collection**. Scene count, layout, FPS and scene duration are automatic.
4. Select completed results and save to **Pictures/Frame Octopus**, share through Android's chooser, or delete the selected app results. Saved gallery copies and original videos are retained when app results are deleted.

This creates multiple representative scenes in one image. Animated scenes play together without audio. It is not a start/end video trimmer or a full-timeline video-to-WebP converter. Wooingbee informed the simple selection/create/save flow; its editing features and visual assets were not copied.

## Advanced controls

- Maximum scenes: Automatic / 4 / 8 / 12 / 24. Short sources can produce fewer scenes.
- Individual scene aspect: original / square / landscape / portrait.
- Collection layout: automatic / wide / tall; existing flexible-last-row layout fills unused cells.
- Maximum output width: 960 / **1280 default** / 1920 px. Capacity fitting can reduce it further. Windows retains its 1920 px default.
- Automatic FPS uses source nominal FPS, a 30 FPS ceiling and an approximately 80-frame-per-scene work budget on Android (120 on Windows). Manual FPS requests 4–30, still capped by the source.
- Automatic scene duration uses source length and usable scene count; manual duration is 0.5–10 seconds.
- Animation controls are disabled for PNG. Automatic and manual modes are separate, and retained manual values are not overwritten.
- English default, Korean and Japanese, persistent preferences and existing octopus mascot.

The default 1280 px mobile width is a processing-time/memory tradeoff, not a claim of maximum possible quality. Choose 1920 px when higher detail is preferred. The size limit is a ceiling, not a requirement to fill every available byte.

## Processing lifecycle and storage

V1 processes in the foreground, keeps the screen awake while creating, and cancels unfinished work when the app moves to the background. Completed results remain in the current session. It does not yet provide a persistent Android background service or resume an interrupted encode.

Selected videos are copied into app cache for local FFmpeg access. Gallery imports and processing run sequentially. Processing job intermediates are cleaned by the shared engine. Old session imports, thumbnails, intermediates and private results are removed on the next cold start; save wanted results to the gallery before exiting. No original media or gallery exports are removed by this cleanup.

The picker grants access to selected videos. Android 10+ gallery saving uses MediaStore without broad library permission. Android 7–9 requests legacy write permission only when saving. Mosaic's APK updater and install permission were not included.

## Design status

The Android shell now uses `fluent_ui` 4.13.0: FluentApp, ComboBox/InfoLabel, FilledButton/Button/HyperlinkButton, ToggleSwitch, Slider, Checkbox, ProgressBar/ProgressRing, InfoBar and ContentDialog. Cards and panels use a 4 px corner radius, thin neutral borders, white surfaces and a Windows-blue accent. Fluent icons and typography replace Material 3 presentation. Touch buttons retain at least 44 px height; settings labels wrap separately from their toggles. Material is retained only for Flutter layout/gesture and video infrastructure, not as the visual control theme.

The existing screenshots below record the initial Android beta. Current Fluent captures are in [screenshots/fluent](screenshots/fluent/01-welcome.png).

## Build

Requires the project's Flutter SDK/toolchain and Android SDK; minimum Android API 24. Current real-device verification used Samsung SM-A346N, Android 16, arm64.

```powershell
flutter pub get
flutter run -d <device-id>
flutter build apk --debug --target-platform android-arm64
```

Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`. It is a development build, not a signed store release. Release tasks require an untracked `android/key.properties` with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`. Keystores and signing properties are ignored by Git. No signing keys were copied during Android development.

Before store distribution: verify native-library license/source obligations and current Android store compatibility, test long videos and low-memory devices, and configure release signing and store assets. Store submission has not been performed for Android.

## Verification and screenshots

On 2026-11-22, the real device completed two WebP results below 20 MB (17,365,776 and 13,608,496 bytes) using the initial 1920 px build and saved both to MediaStore. The revised 1280 px default produced a 1280 × 724 animated WebP with 66 frames and 12,741,266 bytes; saving and opening the native share chooser were verified. No share recipient was selected. A 1,195,006-byte still PNG was also generated and saved. Deleting the selected app result removed its private file while leaving the saved gallery copy intact.

Manual settings reached 30 FPS and 10 seconds; automatic settings were restored. Static checks and 16 Flutter tests passed, including a 360 px layout at 150% text scale. Windows debug compilation also passed after adding Android dependencies. These are brief smoke checks, not a full Android compatibility certification.

scrcpy was launched in **read-only** mode:

```powershell
scrcpy -s <device-id> --no-control --no-audio --max-size=1200
```

Device-only ADB input was used for test interactions; no Windows pointer automation was used.

- [Welcome](screenshots/01-welcome.png)
- [Editor](screenshots/02-editor.png)
- [Gallery save notification](screenshots/03-gallery-saved.png)
- [Layout settings](screenshots/04-advanced-layout.png)
- [Animation settings](screenshots/05-advanced-animation.png)
- [Animated result](screenshots/06-results.png)
- [Verification record](verification.json)

Sources: [Mosaic upstream](https://github.com/mosaicvideo/mosaic), local Mosaic Android gallery/rotation integration, Frame Octopus shared engine. Sample media licensing is documented in `distribution-media/README.md`. No personal gallery video was used for output screenshots.

## Firebase and privacy website

Android is registered in Firebase project `frame-octopus` with package `ink.frameoctopus.frame_octopus`. Firebase Core is initialized only by the Android entry path. Automatic Firebase data collection defaults to false; Analytics, Crashlytics, Authentication and media-upload services are not enabled. Windows is not initialized against Firebase. The Android Advanced panel opens the hosted privacy policy in the app's selected language.

- English: https://frame-octopus.web.app/privacy
- Korean: https://frame-octopus.web.app/ko/privacy
- Japanese: https://frame-octopus.web.app/ja/privacy

Hosting source/configuration and deployment steps are documented in `hosting/README.md`.

The Fluent/Firebase revision passed 17 Flutter tests and Android/Windows debug builds. Firebase initialization and the Advanced → Privacy policy browser link were verified on SM-A346N.
