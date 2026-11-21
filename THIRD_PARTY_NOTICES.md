# Third-party notices

## Mosaic

Original project: https://github.com/mosaicvideo/mosaic
Flutter port: https://github.com/idlepoe/mosaic

The processing engine, sampling/layout models, brand theme and octopus assets were adapted from the Flutter Mosaic port. Preserve the upstream MIT license in LICENSE. This project does not claim ownership of upstream work.

## FFmpegKit / FFmpeg

Dart package: ffmpeg_kit_flutter_new_full 2.5.8
Source: https://github.com/sk3llo/ffmpeg_kit_flutter
Windows native bundle selected by the package: FFmpegKit 8.1.2, full (without the optional GPL encoder bundle).

FFmpegKit and its native components have their own licenses, including LGPL terms. Their licenses and corresponding sources/build information must accompany distribution as applicable. The plugin installs the native license collection under the release directory's licenses folder. The application's MIT license does not replace these obligations.

## media_kit / libmpv

Dart player packages: https://github.com/media-kit/media-kit
Native libraries: https://github.com/media-kit/media-kit/libs
Native mpv: https://github.com/mpv-player/mpv

Dart packages and native binaries have separate license obligations. Preserve their license notices and provide corresponding native source/build information and other redistribution materials as required by the actual bundle. Review the selected binary's enabled components before Microsoft Store distribution.

## Fluent UI for Flutter

https://github.com/bdlukaa/fluent_ui (MIT). The app uses fluent_ui 4.13.0, pinned to a release that compiles with the installed Flutter 3.41 toolchain. The Shadcn dependency has been removed. Flutter Material primitives remain only where needed by the video package and ink surfaces; app buttons, selectors, checkboxes, sliders and advanced dialogs use Fluent controls.

Resolved package versions are recorded in pubspec.lock.

## desktop_drop

Desktop drag-and-drop integration: https://github.com/MixinNetwork/flutter-plugins/tree/main/packages/desktop_drop (Apache-2.0). Resolved version: 0.8.4.

## Window lifecycle

window_manager: https://github.com/leanflutter/window_manager (MIT). Resolved version 0.5.2. Prevents closing the app while an encoding/import/export operation is active.

## Exact Windows native build provenance

The FFmpegKit bundle installs its own `licenses/ffmpeg_kit_flutter_new_full/NOTICE.txt`, FFmpeg/FFmpegKit licenses and dependency licenses. This notice identifies FFmpeg n8.1.2, wrapper/build scripts at https://github.com/sk3llo/ffmpeg-kit/tree/windows-8.1.2-1 and the corresponding MSYS2 source packages. Retain that complete license directory with the application.

media_kit_libs_windows_video 1.0.11 resolves `mpv-dev-x86_64-20230924-git-652a1dd.7z` from https://github.com/media-kit/libmpv-win32-video-build/releases/tag/2023-09-24 (upstream package MD5 a832ef24b3a6ff97cd2560b5b9d04cd8). Build configuration strings in the selected DLL include --disable-gpl and LGPL version 3; this observation does not replace a complete source/relinking-material review. Build scripts: https://github.com/media-kit/libmpv-win32-video-build. Native source and redistribution material availability must be finalized before public Store distribution. The app itself remains open source under LICENSE.

## Microsoft C++ runtime

The Windows CMake install step uses InstallRequiredSystemLibraries to select app-local MSVC redistributables from the installed Visual Studio toolchain. These files remain subject to Microsoft's terms, not this project's MIT license. Native deployment reference: https://learn.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files
