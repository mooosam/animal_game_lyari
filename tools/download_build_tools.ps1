$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$toolsRoot = Join-Path $PSScriptRoot 'android'
New-Item -ItemType Directory -Force -Path $toolsRoot | Out-Null
$release = Invoke-RestMethod 'https://api.github.com/repos/godotengine/godot-builds/releases/tags/4.7.2-stable'
$template = $release.assets | Where-Object name -EQ 'Godot_v4.7.2-stable_export_templates.tpz'
if (-not $template) { throw 'Matching Godot export templates not found' }
Invoke-WebRequest $template.browser_download_url -OutFile (Join-Path $toolsRoot 'templates.zip')
Expand-Archive (Join-Path $toolsRoot 'templates.zip') (Join-Path $toolsRoot 'templates') -Force
Invoke-WebRequest 'https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip' -OutFile (Join-Path $toolsRoot 'cmdline.zip')
Expand-Archive (Join-Path $toolsRoot 'cmdline.zip') (Join-Path $toolsRoot 'unpacked') -Force
New-Item -ItemType Directory -Force -Path (Join-Path $toolsRoot 'sdk/cmdline-tools') | Out-Null
Move-Item -LiteralPath (Join-Path $toolsRoot 'unpacked/cmdline-tools') -Destination (Join-Path $toolsRoot 'sdk/cmdline-tools/latest')
$jdkAssets = Invoke-RestMethod 'https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse'
Invoke-WebRequest $jdkAssets[0].binary.package.link -OutFile (Join-Path $toolsRoot 'jdk.zip')
Expand-Archive (Join-Path $toolsRoot 'jdk.zip') (Join-Path $toolsRoot 'java') -Force
Write-Output 'DOWNLOADS_COMPLETE'
