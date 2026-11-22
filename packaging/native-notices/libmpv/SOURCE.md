# libmpv source and library replacement

Binary: media_kit_libs_windows_video 1.0.11, upstream mpv-dev-x86_64-20230924-git-652a1dd.7z.
mpv source: https://github.com/mpv-player/mpv/tree/652a1dd90711839acdccc08004056d25514ef2d8
Build system: https://github.com/media-kit/libmpv-win32-video-cmake
Build/release repository: https://github.com/media-kit/libmpv-win32-video-build
Release: https://github.com/media-kit/libmpv-win32-video-build/releases/tag/2023-09-24
Embedded FFmpeg source: https://github.com/FFmpeg/FFmpeg/tree/n6.0

The DLL build configuration is retained in ffmpeg-build-configuration.txt. This selected DLL disables GPL and nonfree codecs and uses LGPL version 3 or later for embedded FFmpeg. mpv copyright/license files are included. The separately downloaded mpv.exe is not shipped by Frame Octopus.

Frame Octopus links dynamically to libmpv-2.dll and the FFmpegKit DLLs. Reverse engineering for debugging modifications to LGPL components is permitted. To test a compatible replacement, use a writable copy of the complete application layout, replace the relevant DLL with a compatible build and run frame_octopus.exe. Preserve dependent DLLs and notices. A modified MSIX must be repackaged and signed for local installation; do not alter the Store-installed package in place.
