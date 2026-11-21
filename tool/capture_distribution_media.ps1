param([string]$SourceFolder = (Join-Path (Split-Path $PSScriptRoot -Parent) 'distribution-media\source'))
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$mediaRoot = Join-Path $projectRoot 'distribution-media'
$verificationRoot = Join-Path $projectRoot 'verification'
New-Item -ItemType Directory -Force -Path $verificationRoot | Out-Null
foreach ($directory in @('screenshots','videos','outputs')) { New-Item -ItemType Directory -Force -Path (Join-Path $mediaRoot $directory) | Out-Null }
$inputs = @((Join-Path $SourceFolder 'dog-river.mp4'), (Join-Path $SourceFolder 'cat-garden.mp4'))
foreach ($inputFile in $inputs) { if (!(Test-Path -LiteralPath $inputFile)) { throw "Missing local sample: $inputFile" } }
$identifier = [guid]::NewGuid().ToString('N')
$manifest = Join-Path $verificationRoot ('demo-input-' + $identifier + '.json')
$reportPath = Join-Path $verificationRoot ('demo-report-' + $identifier + '.json')
ConvertTo-Json -InputObject $inputs | Set-Content -Encoding utf8 $manifest
$executable = Join-Path $projectRoot 'build\windows\x64\runner\Release\frame_octopus.exe'
$captureProcess = Start-Process -PassThru -FilePath $executable -WorkingDirectory (Split-Path $executable) -ArgumentList @('--capture-demo', ('"' + $manifest + '"'), ('"' + $reportPath + '"'))
$startedAt = Get-Date
$deadline = $startedAt.AddMinutes(8)
while (!(Test-Path -LiteralPath $reportPath)) {
  if ($captureProcess.HasExited) { throw 'Capture app exited before producing its report.' }
  if ((Get-Date) -gt $startedAt.AddSeconds(30) -and !(Test-Path -LiteralPath ($reportPath + '.frames'))) { throw 'App capture did not start.' }
  if ((Get-Date) -gt $deadline) { throw 'Media capture timed out. Check the app.' }
  Start-Sleep -Milliseconds 500
}
$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
if (!$report.ok) { $report | ConvertTo-Json -Depth 8; throw 'App media capture failed.' }
foreach ($screen in @('welcome','editor','results','preview','results-en','results-ja')) {
  $destination = Join-Path $mediaRoot ('screenshots\' + $screen + '.png')
  Copy-Item -LiteralPath ($reportPath + '.' + $screen + '.png') -Destination $destination -Force
}
foreach ($screen in @('welcome','editor','results')) {
  Copy-Item -LiteralPath ($reportPath + '.' + $screen + '.png') -Destination (Join-Path $projectRoot ('docs\screenshots\studio-' + $screen + '.png')) -Force
}
foreach ($outputFile in $report.outputs) { Copy-Item -LiteralPath $outputFile.path -Destination (Join-Path $mediaRoot 'outputs') -Force }
$framing = 'scale=1920:1080:force_original_aspect_ratio=decrease:force_divisible_by=2:flags=lanczos,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0xf3f3f3,setsar=1'
foreach ($screen in @('welcome','editor','results','preview')) {
  & ffmpeg -hide_banner -loglevel error -y -i (Join-Path $mediaRoot ('screenshots\' + $screen + '.png')) -vf $framing -frames:v 1 (Join-Path $mediaRoot ('screenshots\store-' + $screen + '-1920x1080.png'))
  if ($LASTEXITCODE -ne 0) { throw 'Store screenshot framing failed.' }
}
$frames = Join-Path ($reportPath + '.frames') '%06d.png'
& ffmpeg -hide_banner -loglevel error -y -framerate 10 -i $frames -vf $framing -c:v libx264 -preset fast -crf 20 -pix_fmt yuv420p -an -movflags +faststart (Join-Path $mediaRoot 'videos\frame-octopus-demo-1080p.mp4')
if ($LASTEXITCODE -ne 0) { throw 'Demo video encoding failed.' }
# The public report omits machine-specific storage paths.
$publicReport = [ordered]@{ ok=$report.ok; inputs=@('dog-river.mp4','cat-garden.mp4'); firstVideoFrameRendered=$report.firstVideoFrameRendered; exportedCopies=$report.exportedCopies; demoFrames=$report.demoFrames; outputs=@($report.outputs | ForEach-Object { [ordered]@{ filename=(Split-Path $_.path -Leaf); bytes=$_.bytes; width=$_.width; height=$_.height; frames=$_.frames; attempts=$_.attempts; quality=$_.quality; qualityScore=$_.qualityScore; sceneCount=$_.sceneCount; fps=$_.fps; sourceSeconds=$_.sourceSeconds } }) }
$publicReport | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $mediaRoot 'verification.json')
$publicReport | ConvertTo-Json -Depth 8
