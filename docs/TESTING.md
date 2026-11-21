# Stage 1 verification

Date: 2026-11-21 (Asia/Seoul).

- Flutter analysis: no issues.
- Short-video sampling test: passed. Clip starts/ends stay inside inputs from 0.2 to 10 seconds; short inputs reduce the scene count.
- Windows release build: passed with bundled native FFmpeg and mpv libraries. The media_kit dependency emits non-fatal CMake developer policy warnings.
- Native integration: a synthetic six-second 640x360, 24 FPS video was processed by the Windows executable, not an emulator. Both generated formats were decoded by Flutter: PNG 960x544 (one frame), animated WebP 960x544 (48 frames / two-second loop). The default adaptive sampler selected three scenes for this six-second source.
- Original playback duration: 6,000 ms. Saving the same completed result twice produced two separate copies without overwriting.
- The app accessibility tree exposed the input, completion status, original/result toggle and export controls. Desktop screenshot capture returned another foreground window, so no unrelated screenshot is retained and no full visual sign-off is claimed.

Reproduce with a short test video after building:

```powershell
.\tool\verify_windows.ps1 -VideoPath C:\path\to\short-video.mp4
```

This runs the real processor for both formats, validates animated frame count and checks original playback duration and duplicate-name export. Reports and exports stay under the Git-ignored verification directory. The app remains open for inspection.

This is a focused foundation check. Capacity fitting, long-video performance, audio synchronization, HDR/Dolby Vision, exotic codecs and Microsoft Store certification have not been validated in stage 1.

## Stage 2 — Wooingbee-style interaction

- Replaced the previous dashboard with a centered, outlined workbench. The complete welcome surface is one clickable and keyboard-accessible file-picker action.
- Added Windows file drag-and-drop, a two-column file-card list, an add tile and per-file exclusion. Input exclusion changes the queue only; it does not delete source videos.
- Moved the single generate action beneath the preview. Completed results appear in a selectable gallery with select-all and selected-only export.
- Focused checks: welcome whitespace click/Enter activation; compact 930x480 editor at 150% text scale without overflow; add/remove lock during processing; selected-only export and duplicate-name preservation. All four automated tests, including the existing sampling check, passed. Flutter analysis found no issues.
- Native verification writes welcome/editor/results PNGs directly from the running Flutter render tree, so other desktop windows do not contaminate the screenshots. It also checks the first video frame, actual output decoding and export.
- OS-level dragging from Explorer and the native file/folder dialogs have not been fully automated in this check.

Native stage-2 run passed: firstVideoFrameRendered=true, playbackDurationMs=6000, PNG 960x544, WebP 960x544 with 48 frames, and exportedCopies=2. Application render-tree captures of the welcome, editor and result screens are retained under docs/screenshots/stage2-*.png.


## Independent studio layout revision

The upload screen now centers the octopus and one add action across a full-width clickable surface. The editor uses a horizontal video filmstrip below the preview and a right-side output panel. Mint surfaces, thin borders and green actions replace the earlier outlined frame and split promotional hero. The source selection and checked-result export behavior are unchanged.

The four focused tests passed, including the 930x480 editor at 150% text scale. Flutter analysis passed. The Windows verification confirmed a rendered first video frame, PNG and 48-frame WebP output, and two collision-safe exported copies. Current application-rendered views are in docs/screenshots/studio-*.png.

## Stages 3–5 and Fluent revision (2026-11-21)

Focused checks: 8 tests passed. They cover short-video sample bounds; full-width flexible rows across portrait/landscape/square and prime counts; measured-fit acceptance and cleanup on rejection/cancellation; bounded optimization fallbacks; preference restore/reset; English default with explicit language persistence; upload click/keyboard activation; compact editor at 150% text size; selected-only collision-safe export. Flutter analysis passed.

Native batch verification used a six-second clip, a 90-second clip and an unreadable MP4. The unreadable input was isolated, while both valid sources produced PNG and animated WebP outputs under 1,000,000 bytes. The six-second animated sheet retained 3 scenes and measured 645,194 bytes after 3 attempts (768x654, 18 FPS, 36 frames). The 90-second sheet retained 12 scenes and measured 716,846 bytes after 3 attempts (768x328, 18 FPS, 36 frames). Four exported copies were distinct. English/Japanese result views were rendered.

The final interface uses fluent_ui 4.13.0 with Windows blue and neutral surfaces. Version 4.16.1 resolved successfully but used Flutter framework APIs absent from the installed 3.41.9 toolchain, so compilation checks required pinning a compatible release. This does not affect the original Mosaic project or Flutter installation.

A development MSIX was generated. It has a development identity and no signature. It is not a Store certification result. Final package identity, installed-package/WACK checks, public privacy-policy hosting and complete native source/relinking distribution review remain release gates. No certificates were installed and no Store submission was made.

## Control spacing and Mixkit capture

The final focused suite has 9 passing tests. Queue remove actions live in a dedicated header above each thumbnail with 10 logical pixels of card inset. Result checkboxes have a centered 36x36 allocation, 14-pixel card inset and 12-pixel separation from the filename. Zoom actions share the header; no controls overlay result imagery. The preview close action occupies its own title row with 16-pixel interior padding. Geometry checks at 150% text scale verify separation and absence of overflow.

The final release-media run used the developer's Mixkit dog-river and cat-garden clips, after checking each original item page's Free License designation. Both produced PNG sheets and animated WebP sheets within a strict 1,000,000-byte limit. PNG outputs measured 733,179 and 736,079 bytes. Animated outputs measured 667,686 and 657,724 bytes after three attempts, retaining four scenes at 768x436 and 18 FPS (36 frames).

The real app render tree supplied 313 video frames. The saved H.264 demo is 1920x1080, 10 FPS, 31.3 seconds. Native screenshots, full-view Store-framed screenshots, the video, output examples, footage hashes and a path-sanitized verification report are retained under distribution-media/. The snow-cats 720p source is currently Restricted License and was excluded from public-facing media. Desktop source files were preserved byte-for-byte.

Final artifact checks: Windows SDK MakeAppx unpack succeeded; both MSIX and portable ZIP passed CRC checks and contained the MSVC runtime and privacy/license notices. Neither archive contained private signing material or raw Mixkit video. The packaging script restores the CMake install layout after the msix tool's cleanup (which removes app-local CRT DLLs), so the portable ZIP retains its runtime dependencies. These are structural/dependency checks, not installed-package WACK certification. Audit: packaging/ARTIFACT_AUDIT.json; SHA-256 hashes: build/distribution/SHA256.json.

## Quality-first capacity revision (2026-11-21)

Supersedes the earlier first-fit/eight-attempt policy. Flutter analysis passed and all 11 focused tests passed. New checks cover retaining the highest measured WebP quality, replacing a first fit with a better resolution/quality balance, lossless PNG width fitting, prepared-frame reuse, cleanup on failure/cancellation, independent geometry candidates and fractional encoder-quality persistence. Existing compact-layout and button-inset checks still pass.

The optimizer preserves requested scene coverage and clip duration before comparing canvas width, source-capped FPS and encoder quality. It uses a bounded weighted heuristic with local refinement, rather than claiming an exhaustive perceptual optimum. WebP quality probes reuse prepared clips and merged rows. Tight limits can take substantially longer than the previous coarse fallback.

Native comparison on the 11.011-second dog-river sample passed at 1 MB and 20 MB. Both animated sheets retained five scenes, 24 FPS and 48 decoded frames. The 1 MB result was 998,064 bytes, 958x450, Q61.3; the 20 MB result was 19,115,124 bytes, 1918x900, Q97.9. PNG remained lossless: 996,491 bytes at 1240x584 versus 2,071,283 bytes at 1918x900. All actual files were within their limits. First-frame playback, English/Japanese views and two exported copies passed. Reports and sample outputs: distribution-media/quality-comparison/. The tight animated limit required 92 encodes; the 20 MB case required 11.

Refreshed release-media capture uses the current 20 MB default: both four-scene animated samples retain 1920x1084 and 24 FPS. Dog/cat output sizes are 19,269,990 and 19,875,180 bytes, at Q97.4/Q97.5. The demo contains 487 frames at 10 FPS (48.7 seconds), with encoding progress accelerated approximately 5x. Current screenshots and media replace the previous first-fit examples.

## Faster quality search (2026-11-21)

Supersedes fractional-quality and broad-geometry search. Start at Q95, bisect whole quality units, predict canvas area from measured overflow, compare at most five main geometry families and skip alternatives with under 2% potential score gain. The coverage-preserving minimum and scene fallback remain safety checks. Prepared clips are reused within each geometry; final acceptance always uses actual file bytes. PNG fitting is unchanged.

Flutter analysis and all 11 focused tests passed, including encode-count bounds. Windows release compilation passed. The same 11.011-second source comparison passed: 1 MB animated output required 18 encodes instead of 92, measuring 970,214 bytes at 946x446/Q61.0; 20 MB required 4 instead of 11, measuring 17,233,520 bytes at 1918x900/Q97.0. Both retained five scenes, 24 FPS and 48 frames. Previous values were 958x450/Q61.3 and 1918x900/Q97.9 respectively. This deliberately accepts small quality differences for fewer encodes. These count reductions are not elapsed-time percentages. Full verification took 115.7 seconds including PNG, playback, screenshots and export; no equivalent historical wall-time baseline was recorded. PNG results remained byte-identical. Current sanitized report and examples: distribution-media/speed-comparison/. Earlier quality-comparison and demo assets document the preceding revision.

## Automatic scene duration (2026-11-21)

Automatic clip length is now the default, including legacy preferences without an explicit mode. Manual mode and its 0.5-10 second value persist independently. Usable cut count is resolved before duration; clip length is video duration divided by usable cuts, capped at 10 seconds. Existing source-end limits and scene-spacing rules remain. Tiny floating-point rounding no longer drops a cut when equal partitions divide the source.

All 12 focused tests passed and Flutter analysis passed. Tests cover 10s/four cuts/2.5s, 12s/four/3s, 60s/ten/6s, 600s/24/10s, subsecond sources, fractional duration with a higher requested scene count, manual overrides and retained manual values. The compact 930x480 view at 150% text scale opens/scrolls the Advanced dialog and toggles automatic mode without overflow. Animated result cards show actual per-scene duration; the main preview rounds it to two decimals.

Native automatic-duration verification passed on dog-river.mp4: 11.011s source, five usable scenes, 2.2022s per scene, 53 decoded frames at 24 FPS, 19,011,390 bytes under 20 MB after four encodes. First-frame playback, duplicate-safe export and English/Japanese views passed. Saved report and outputs: distribution-media/automatic-duration/. Windows release build passed.

## Advanced control separation

Sliders have dedicated 44-pixel height with 8-pixel vertical/horizontal inset. A divider and separate spacing distinguish FPS from automatic clip controls; label and switch have 16-pixel horizontal separation. Reset has its own top gap. The scrollable dialog remains usable at 930x480 with 150% text: focused geometry checks assert slider/automatic-row separation in addition to no overflow, plus manual toggling. All four workbench tests and Flutter analysis passed.

## Predictive WebP encoding (2026-11-21)

Replaces full-animation quality search. The native pipeline prepares scene clips and merged rows once. Beginning/middle/end windows contain up to 12 frames in total; short encodes at quality anchors estimate frame cost. The first WebP frame is charged once, and static files avoid a temporal multiplier. Quality and geometry are selected from estimates. Geometry changes scale the prepared composition rather than extracting clips again. A final full encode is accepted only after its actual size is measured; bounded corrections reuse the same composition. Short probes run sequentially to bound memory and preserve session cancellation. Unlimited output and lossless PNG keep their existing behavior.

Flutter analysis, Windows release build and all 14 tests passed. Tests include sample coverage, key-frame/static size accounting, one full encode for a fitting prediction, correction after an underestimated sample, one preparation across corrections, cleanup/cancellation and the existing compact UI checks.

Real dog-river comparison (manual 2s clips): PNG is unchanged. At 1 MB, WebP used six short probes and one full encode, producing 864,292 bytes at 976x460/Q61, five scenes and 24 FPS. At 20 MB it used two probes and two full encodes (one correction), producing 16,397,766 bytes at 1918x900/Q96 with the same scenes/FPS. Prior full-encode counts were 18 and 4, with Q61/946x446 and Q97/1918x900. Full verification elapsed time dropped from 115.7s to 67.8s (about 41%); this includes PNG, playback, decoding, screenshots and export, and is a local observation rather than a general speed guarantee. First-frame playback, decoded frames and export passed. Current report/output examples: distribution-media/predictive-optimization/.

## Fast single-sample policy (2026-11-22)

User preference now prioritizes speed over fine capacity utilization. One Q90 sample is taken; clearly spare capacity allows Q95 without another probe. Overflow estimates reduce canvas area directly. There is no quality/geometry search to fill unused space. One final full encode is normal; at most two measured-overflow corrections reuse the same prepared source. Scene fallback is reserved for no fitting output. Unlimited output remains a direct encode; PNG is unchanged.

Analysis, Windows build and all 14 tests passed. Same dog-river verification took 41.7s including PNG, playback, decoding, export and screenshots (previous predictive revision 67.8s; earlier measured search 115.7s, local observations). Default 20 MB required one sample and one full encode: 15,416,502 bytes at 1918x900/Q95, five scenes, 24 FPS, 48 frames. Tight 1 MB required one sample and two full encodes: 636,102 bytes at 490x232/Q85 with the same scene count/FPS. Tight budgets intentionally accept conservative resolution and unused bytes to avoid additional optimization. Actual byte caps, decoding and export passed. Report/examples: distribution-media/fast-optimization/.

## Source-aware automatic FPS (2026-11-22)

Automatic FPS defaults on, including old preferences without an explicit mode. FPS uses nominal source rate capped at 30 and approximately 120 frames per scene, based on the actual clip duration. This is metadata/length analysis, not motion estimation, and adds no encoding probe. Explicit manual FPS/mode persist independently; output still respects the source rate. Capacity fitting may reduce FPS further.

The 15 focused tests and updated workbench checks passed, including automatic/manual FPS slider gating and 150% text layout. Flutter analysis passed. Policy cases include 12/23.976/25/29.97/60/120 FPS sources, 6/10-second intervals, low-FPS inputs, mixed-source independence, retained manual FPS and reset to automatic.

Native verification passed with a generated 60 FPS/two-second source: automatic output was 30 FPS with 60 decoded frames, 320x180, 415,376 bytes and one sample/one full encode. Playback, two exported copies and English/Japanese views passed. Windows release build passed. Saved report/examples: distribution-media/automatic-fps/.

## Visible save confirmation (2026-11-22)

After a successful folder export, a top-center Fluent success InfoBar displays the actual saved file count and destination for five seconds, with a dismiss action. The existing result status remains. Cancellation and failure do not trigger the success notification. Export returns the completed copy count; focused export tests verify selected-only count and collision-safe copies. Flutter analysis and all four workbench tests passed.
