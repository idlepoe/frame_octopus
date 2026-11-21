param([switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
  if (!$SkipBuild) { & flutter build windows --release; if ($LASTEXITCODE -ne 0) { throw 'Windows build failed.' } }
  & dart run msix:create --build-windows false --sign-msix false --install-certificate false
  if ($LASTEXITCODE -ne 0) { throw 'Development MSIX creation failed.' }
  # msix's cleanup removes app-local CRT files from Release after packaging.
  # Restore the complete install layout before creating the portable ZIP.
  $cache = Get-Content -LiteralPath (Join-Path $projectRoot 'build\windows\x64\CMakeCache.txt')
  $cmakeLine = $cache | Where-Object { $_ -like 'CMAKE_COMMAND:INTERNAL=*' } | Select-Object -First 1
  if (!$cmakeLine) { throw 'CMake tool path was not recorded by the Windows build.' }
  $cmakePath = $cmakeLine.Substring('CMAKE_COMMAND:INTERNAL='.Length)
  & $cmakePath --install (Join-Path $projectRoot 'build\windows\x64') --config Release --component Runtime | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Could not restore runtime files after MSIX cleanup.' }
  $releasePath = Join-Path $projectRoot 'build\windows\x64\runner\Release'
  $distributionPath = Join-Path $projectRoot 'build\distribution'
  $privateFiles = @(Get-ChildItem -LiteralPath $releasePath -Recurse -File | Where-Object { $_.Extension -in @('.pfx','.p12','.key','.pem','.jks','.keystore') })
  if ($privateFiles.Length -gt 0) { throw 'Private signing material must not be packaged.' }
  Compress-Archive -Path (Join-Path $releasePath '*') -DestinationPath (Join-Path $distributionPath 'Frame-Octopus-0.2.0-Windows-x64-portable.zip') -Force
  Get-ChildItem -LiteralPath $distributionPath -File | Where-Object { $_.Extension -in @('.zip','.msix') } | Get-FileHash -Algorithm SHA256 | Select-Object @{Name='file';Expression={Split-Path $_.Path -Leaf}},Hash | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $distributionPath 'SHA256.json')
} finally { Pop-Location }
