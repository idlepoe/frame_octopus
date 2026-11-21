param([string]$VideoPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'distribution-media\source\dog-river.mp4'), [int[]]$LimitsMb = @(1,20), [switch]$AutoClip, [switch]$AutoFps)
$VideoPaths = @($VideoPath)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$work = Join-Path $projectRoot 'verification'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$identifier = [guid]::NewGuid().ToString('N')
$manifest = Join-Path $work ('quality-input-' + $identifier + '.json')
$reportPath = Join-Path $work ('quality-report-' + $identifier + '.json')
$resolved = @($VideoPaths | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
ConvertTo-Json -InputObject @{inputs=$resolved;budgets=$LimitsMb;autoClip=[bool]$AutoClip;autoFps=[bool]$AutoFps} | Set-Content -Encoding utf8 $manifest
$exePath = Join-Path $projectRoot 'build\windows\x64\runner\Release\frame_octopus.exe'
Start-Process -FilePath $exePath -WorkingDirectory (Split-Path $exePath) -ArgumentList @('--verify-quality', ('"' + $manifest + '"'), ('"' + $reportPath + '"')) | Out-Null
$deadline = (Get-Date).AddMinutes(10)
while (!(Test-Path -LiteralPath $reportPath)) {
  if ((Get-Date) -gt $deadline) { throw 'Quality verification timed out. Check the app window.' }
  Start-Sleep -Milliseconds 500
}
$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
$report | ConvertTo-Json -Depth 8
if (!$report.ok) { throw 'Quality verification failed.' }
