$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$androidRoot = Join-Path $PSScriptRoot 'android'
$env:JAVA_HOME = (Get-ChildItem (Join-Path $androidRoot 'java') -Directory | Select-Object -First 1).FullName
$env:ANDROID_HOME = Join-Path $androidRoot 'sdk'
$env:ANDROID_AVD_HOME = Join-Path $androidRoot 'avd'
$env:ANDROID_USER_HOME = Join-Path $androidRoot 'user'
New-Item -ItemType Directory -Force $env:ANDROID_AVD_HOME,$env:ANDROID_USER_HOME | Out-Null
$manager = Join-Path $env:ANDROID_HOME 'cmdline-tools/latest/bin/sdkmanager.bat'
& $manager --sdk_root=$env:ANDROID_HOME 'emulator' 'system-images;android-35;default;x86_64'
if ($LASTEXITCODE -ne 0) { throw 'Emulator installation failed' }
'no' | & (Join-Path $env:ANDROID_HOME 'cmdline-tools/latest/bin/avdmanager.bat') create avd --force --name AnimalSwitchTest --package 'system-images;android-35;default;x86_64' --device 'pixel_4'
if ($LASTEXITCODE -ne 0) { throw 'AVD creation failed' }
Write-Output 'EMULATOR_SETUP_COMPLETE'
