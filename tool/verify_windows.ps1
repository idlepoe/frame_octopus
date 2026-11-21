param([Parameter(Mandatory=$true)][string]$VideoPath)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$inputVideo = (Resolve-Path -LiteralPath $VideoPath).Path
$exePath = Join-Path $projectRoot 'build\windows\x64\runner\Release\frame_octopus.exe'
$reportDirectory = Join-Path $projectRoot 'verification'
New-Item -ItemType Directory -Force -Path $reportDirectory | Out-Null
$reportPath = Join-Path $reportDirectory ('engine-' + [guid]::NewGuid().ToString('N') + '.json')
if (!(Test-Path -LiteralPath $exePath)) { throw 'Build first: flutter build windows --release' }
$arguments = @('--verify-engine', ('"' + $inputVideo + '"'), ('"' + $reportPath + '"'))
Start-Process -FilePath $exePath -WorkingDirectory (Split-Path $exePath) -ArgumentList $arguments | Out-Null
$deadline = (Get-Date).AddMinutes(3)
while (!(Test-Path -LiteralPath $reportPath)) {
  if ((Get-Date) -gt $deadline) { throw 'Native verification timed out. Check the app window.' }
  Start-Sleep -Milliseconds 500
}
$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
$report | ConvertTo-Json -Depth 8
if (!$report.ok) { throw 'Native generation verification failed.' }
