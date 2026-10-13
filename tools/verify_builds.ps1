$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$androidRoot = Join-Path $PSScriptRoot 'android'
$env:JAVA_HOME = (Get-ChildItem (Join-Path $androidRoot 'java') -Directory | Select-Object -First 1).FullName
$buildTools = Join-Path $androidRoot 'sdk/build-tools/35.0.1'
$apk = Join-Path $root 'builds/AnimalSwitch.apk'
& (Join-Path $buildTools 'apksigner.bat') verify $apk
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed' }
& (Join-Path $buildTools 'aapt.exe') dump badging $apk | Select-String 'package:|sdkVersion|targetSdkVersion|application-label|launchable-activity|native-code'
& (Join-Path $buildTools 'aapt.exe') dump permissions $apk
Get-FileHash $apk,(Join-Path $root 'builds/AnimalSwitch.exe') -Algorithm SHA256
Write-Output 'BUILD_VERIFICATION_PASS'
