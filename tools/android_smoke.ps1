param([string]$Mode = 'status')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$androidRoot = Join-Path $PSScriptRoot 'android'
$env:JAVA_HOME = (Get-ChildItem (Join-Path $androidRoot 'java') -Directory | Select-Object -First 1).FullName
$env:ANDROID_USER_HOME = Join-Path $androidRoot 'user'
$env:ANDROID_AVD_HOME = Join-Path $androidRoot 'avd'
$adb = Join-Path $androidRoot 'sdk/platform-tools/adb.exe'
& $adb start-server
& $adb -s emulator-5554 wait-for-device
if ($Mode -eq 'status') {
    & $adb devices
    & $adb -s emulator-5554 shell getprop sys.boot_completed
} elseif ($Mode -eq 'install') {
    & $adb -s emulator-5554 install -r (Join-Path $root 'builds/AnimalSwitch.apk')
    if ($LASTEXITCODE -ne 0) { throw 'APK install failed' }
    & $adb -s emulator-5554 logcat -c
    & $adb -s emulator-5554 shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p com.animalswitch.game
    if ($LASTEXITCODE -ne 0) { throw 'Android launch failed' }
} elseif ($Mode -eq 'capture') {
    & $adb -s emulator-5554 shell screencap -p /sdcard/animal-switch.png
    & $adb -s emulator-5554 pull /sdcard/animal-switch.png (Join-Path $root 'tools/screenshots/android.png')
    & $adb -s emulator-5554 logcat -d -s godot AndroidRuntime | Set-Content (Join-Path $PSScriptRoot 'android_runtime.log')
    & $adb -s emulator-5554 logcat -d | Set-Content (Join-Path $PSScriptRoot 'android_full.log')
    & $adb -s emulator-5554 shell pidof com.animalswitch.game
    & $adb -s emulator-5554 shell dumpsys activity activities | Select-String 'topResumedActivity'
} elseif ($Mode -eq 'race') {
    & $adb -s emulator-5554 shell am force-stop com.animalswitch.game
    & $adb -s emulator-5554 logcat -c
    & $adb -s emulator-5554 shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p com.animalswitch.game --esa command_line '--,--auto-level=10'
} elseif ($Mode -eq 'silentrace') {
    & $adb -s emulator-5554 shell am force-stop com.animalswitch.game
    & $adb -s emulator-5554 logcat -c
    & $adb -s emulator-5554 shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p com.animalswitch.game --esa command_line '--audio-driver,Dummy,--,--auto-level=10'
} elseif ($Mode -eq 'tapplay') {
    & $adb -s emulator-5554 shell input tap 540 1450
} elseif ($Mode -eq 'dismiss') {
    & $adb -s emulator-5554 shell input tap 920 520
} elseif ($Mode -eq 'pause') {
    & $adb -s emulator-5554 shell input tap 95 130
} elseif ($Mode -eq 'resume') {
    & $adb -s emulator-5554 shell input tap 540 1010
} elseif ($Mode -eq 'wrong') {
    & $adb -s emulator-5554 shell input tap 540 2020
} elseif ($Mode -eq 'correct') {
    & $adb -s emulator-5554 shell input tap 204 2020
} elseif ($Mode -eq 'progress') {
    & $adb -s emulator-5554 shell run-as com.animalswitch.game cat files/progress.json
}
