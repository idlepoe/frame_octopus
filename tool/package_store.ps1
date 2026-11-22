param([switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
  $identity = Get-Content packaging/STORE_IDENTITY.json -Raw | ConvertFrom-Json
  $configuration = Get-Content pubspec.yaml -Raw
  if (!$configuration.Contains($identity.identityName) -or !$configuration.Contains($identity.publisher)) { throw 'Store identity does not match Partner Center.' }
  if (!$SkipBuild) {
    & flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'Windows release build failed.' }
  }
  & dart run msix:create --store --build-windows false --sign-msix false --install-certificate false
  if ($LASTEXITCODE -ne 0) { throw 'Store MSIX creation failed.' }
  $cache = Get-Content build/windows/x64/CMakeCache.txt
  $line = $cache | Where-Object { $_ -like 'CMAKE_COMMAND:INTERNAL=*' } | Select-Object -First 1
  $cmake = $line.Substring('CMAKE_COMMAND:INTERNAL='.Length)
  & $cmake --install (Join-Path $projectRoot 'build/windows/x64') --config Release --component Runtime | Out-Null
  if ($LASTEXITCODE -ne 0) { throw 'Runtime restore failed.' }
  $files = Get-ChildItem build/distribution -Filter '*-store.msix' -File
  $files | Get-FileHash -Algorithm SHA256 | Select-Object @{Name='file';Expression={Split-Path $_.Path -Leaf}},Hash | ConvertTo-Json | Set-Content -Encoding utf8 build/distribution/STORE_SHA256.json
} finally { Pop-Location }
