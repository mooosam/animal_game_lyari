$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$androidRoot = Join-Path $PSScriptRoot 'android'
$zip = Join-Path $androidRoot 'cmdline.zip'
& curl.exe -L --fail --retry 3 -C - -o $zip 'https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip'
if ($LASTEXITCODE -ne 0) { throw 'SDK download failed' }
if ((Get-FileHash $zip -Algorithm SHA256).Hash.ToLower() -ne '90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a') { throw 'SDK archive checksum mismatch' }
Expand-Archive $zip (Join-Path $androidRoot 'unpacked') -Force
New-Item -ItemType Directory -Force -Path (Join-Path $androidRoot 'sdk/cmdline-tools') | Out-Null
$source = [IO.Path]::GetFullPath((Join-Path $androidRoot 'unpacked/cmdline-tools'))
$destination = [IO.Path]::GetFullPath((Join-Path $androidRoot 'sdk/cmdline-tools/latest'))
if (-not $source.StartsWith([IO.Path]::GetFullPath($androidRoot)) -or -not $destination.StartsWith([IO.Path]::GetFullPath($androidRoot))) { throw 'Invalid SDK paths' }
if (-not (Test-Path $destination)) { Move-Item -LiteralPath $source -Destination $destination }
$jdkAssets = Invoke-RestMethod 'https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse'
$jdkZip = Join-Path $androidRoot 'jdk.zip'
& curl.exe -L --fail --retry 3 -o $jdkZip $jdkAssets[0].binary.package.link
if ($LASTEXITCODE -ne 0) { throw 'JDK download failed' }
if ((Get-FileHash $jdkZip -Algorithm SHA256).Hash.ToLower() -ne $jdkAssets[0].binary.package.checksum) { throw 'JDK checksum mismatch' }
Expand-Archive $jdkZip (Join-Path $androidRoot 'java') -Force
Write-Output 'DOWNLOADS_COMPLETE'
