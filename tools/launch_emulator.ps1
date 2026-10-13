$ErrorActionPreference = 'Stop'
$androidRoot = Join-Path $PSScriptRoot 'android'
$env:ANDROID_HOME = Join-Path $androidRoot 'sdk'
$env:ANDROID_AVD_HOME = Join-Path $androidRoot 'avd'
$env:ANDROID_USER_HOME = Join-Path $androidRoot 'user'
$emulator = Join-Path $env:ANDROID_HOME 'emulator/emulator.exe'
$process = Start-Process -FilePath $emulator -ArgumentList '-avd AnimalSwitchTest -no-window -no-audio -no-boot-anim -no-snapshot -gpu host -accel auto -memory 1536 -cores 2 -port 5554' -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $PSScriptRoot 'emulator.log') -RedirectStandardError (Join-Path $PSScriptRoot 'emulator_error.log')
$process.Id | Set-Content (Join-Path $PSScriptRoot 'emulator.pid')
Write-Output "EMULATOR_PID $($process.Id)"


