param([Parameter(Mandatory=$true)][string[]]$VideoPaths)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$work = Join-Path $projectRoot 'verification'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$identifier = [guid]::NewGuid().ToString('N')
$manifest = Join-Path $work ('batch-' + $identifier + '.json')
$reportPath = Join-Path $work ('batch-report-' + $identifier + '.json')
$resolved = @($VideoPaths | ForEach-Object { (Resolve-Path -LiteralPath $_).Path })
ConvertTo-Json -InputObject $resolved | Set-Content -Encoding utf8 $manifest
$exePath = Join-Path $projectRoot 'build\windows\x64\runner\Release\frame_octopus.exe'
Start-Process -FilePath $exePath -WorkingDirectory (Split-Path $exePath) -ArgumentList @('--verify-batch', ('"' + $manifest + '"'), ('"' + $reportPath + '"')) | Out-Null
$deadline = (Get-Date).AddMinutes(5)
while (!(Test-Path -LiteralPath $reportPath)) {
  if ((Get-Date) -gt $deadline) { throw 'Batch verification timed out. Check the app window.' }
  Start-Sleep -Milliseconds 500
}
$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
$report | ConvertTo-Json -Depth 8
if (!$report.ok) { throw 'Batch verification failed.' }
