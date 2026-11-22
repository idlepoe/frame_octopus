# Android release provenance and notices

Frame Octopus application code is distributed under the root MIT LICENSE. Native libraries retain their own terms. The Android release uses `ffmpeg_kit_flutter_new_full` 2.5.8 and Maven `com.antonkarpenko:ffmpeg-kit-full:2.2.3`. The AAR POM and arm64 libavcodec build-configuration/license-string evidence are retained here. The selected native binary reports LGPL version 3 or later; libavutil includes version n8.1.2. Do not substitute the separate full-gpl variant based on an upstream default-branch README.

Upstream sources and build references:

- Flutter wrapper: https://github.com/sk3llo/ffmpeg_kit_flutter
- Android wrapper/full variant: https://github.com/sk3llo/ffmpeg_kit_flutter_android/tree/full
- Native FFmpegKit build repository and Android/Apple source/license work: https://github.com/sk3llo/ffmpeg-kit/tree/5c0978866cbb16ff20282b2150b5a7c213647063
- FFmpeg source: https://github.com/FFmpeg/FFmpeg/tree/n8.1.2
- The native build repository contains the dependency download/build scripts; the recorded full-variant configure flags identify enabled external libraries. The repository's existing android-2.2.2/min notice is not presented as a complete full-2.2.3 notice.

The release notice archive includes the application's LICENSE/THIRD_PARTY_NOTICES, this provenance, LGPL/GPL texts, the package POM and Flutter's compiled package notices from the APK. It does not replace component licenses with MIT or claim a separate legal certification. Preserve these materials when redistributing the APK, and use the actual source/build references for the selected native components.

To rebuild the application, check out the release tag, use the pinned dependency versions in pubspec.lock, install Flutter/Android tooling, and run `flutter build apk --release --target-platform android-arm64 --split-per-abi`. Supply your own ignored `android/key.properties`/keystore. The app loads FFmpeg through shared libraries; rebuilding/replacing native libraries and resigning a modified APK is not restricted by an app-level integrity check. Debugging modifications to LGPL components is permitted. The developer's private signing key is not required or supplied for such a rebuild. A differently signed APK requires its own installation rather than an in-place update of this release.

Android uses video_player for playback. The Windows libmpv binary and MSVC runtime are not Android release assets. Flutter/Firebase/video_player/share_plus and other resolved Dart/Android dependencies retain their own notices. See pubspec.lock and the compiled Flutter notices for package versions and licenses.
