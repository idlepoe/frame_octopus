# Mobile workflow comparison

Observed on 2026-11-22 at 390 × 844 browser viewport: https://wooingbee.ink/oder/dcinside

The site's own puppy example was used. No personal media was uploaded. The reference app processes the selected example locally in the browser.

1. **Select:** the large landing surface is the selection button; size and format remain at the top.
2. **Ready:** the landing surface becomes a video editor. This is where Wooingbee's start/end selection belongs; Frame Octopus retains its own automatic multi-scene settings instead.
3. **Processing:** a foreground overlay replaces the working area with a mascot, percentage/progress bar, current file index/name and Stop. Background edit controls are disabled. The captured loading example uses GIF because the example WebP completed before its opening transition could be captured reliably.
4. **Complete:** the editor is replaced with checked result cards and a save-selected/new-batch action area. The completion capture is the example's animated WebP result. The original input editor is no longer the dominant content.

Frame Octopus adopts the state-dependent content change, not the site's artwork, cropping tools or notification/background claims. Its processing is still foreground-only. A noninteractive three-label indicator shows the current state; there are no Next/Back wizard steps. Errors, partial results and cancellation remain distinguishable from complete success.

Reference captures: `01-selection.jpg`, `02-ready.jpg`, `03-processing.jpg`, `04-complete.jpg`.
Implementation captures: `docs/android/screenshots/progress-flow/`.
