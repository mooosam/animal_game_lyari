param([switch]$SkipInstall)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$adb = Join-Path $PSScriptRoot 'android/sdk/platform-tools/adb.exe'
& $adb start-server
& $adb reconnect offline
$ready = $false
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    $state = & $adb -s emulator-5554 get-state 2>$null
    if ($state -eq 'device') { $ready = $true; break }
    Start-Sleep -Seconds 1
}
if (-not $ready) { throw 'Emulator did not connect within 30 seconds' }
if (-not $SkipInstall) {
    & $adb -s emulator-5554 install --no-incremental --no-streaming -r (Join-Path $root 'builds/AnimalSwitch.apk')
    if ($LASTEXITCODE -ne 0) { throw 'Installation failed' }
}
$sizeText = & $adb -s emulator-5554 shell wm size
$sizeMatch = [regex]::Match(($sizeText -join ' '), '(\d+)x(\d+)')
$screenWidth = [int]$sizeMatch.Groups[1].Value
$screenHeight = [int]$sizeMatch.Groups[2].Value
$python = 'C:/Users/Home/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $adb -s emulator-5554 shell am force-stop com.animalswitch.game
$saved = & $adb -s emulator-5554 shell run-as com.animalswitch.game cat files/progress.json
$saved | Set-Content (Join-Path $PSScriptRoot 'android_visual_save_backup.json')
& $adb -s emulator-5554 logcat -c
foreach ($level in @(5,6,9)) {
    & $adb -s emulator-5554 shell am force-stop com.animalswitch.game
    $progressFile = Join-Path $PSScriptRoot 'android_visual_progress.json'
    [IO.File]::WriteAllText($progressFile, ('{"gentle":true,"highest":' + $level + ',"music":true,"sound":true,"version":1}'))
    & $adb -s emulator-5554 push $progressFile /data/local/tmp/animal_visual_progress.json
    & $adb -s emulator-5554 shell run-as com.animalswitch.game cp /data/local/tmp/animal_visual_progress.json files/progress.json
    & $adb -s emulator-5554 shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -p com.animalswitch.game
    # Wait for a rendered home screen rather than tapping on the startup splash.
    $homeReady = $false
    $homeCapture = Join-Path $root 'tools/screenshots/android-home-ready.png'
    for ($renderAttempt = 0; $renderAttempt -lt 36; $renderAttempt++) {
        Start-Sleep -Seconds 5
        & $adb -s emulator-5554 shell screencap -p /data/local/tmp/animal-home-ready.png
        if ($LASTEXITCODE -ne 0) { continue }
        & $adb -s emulator-5554 pull /data/local/tmp/animal-home-ready.png $homeCapture | Out-Null
        if ($LASTEXITCODE -ne 0) { continue }
        & $python (Join-Path $PSScriptRoot 'check_android_race_frame.py') $homeCapture --home
        if ($LASTEXITCODE -eq 0) { $homeReady = $true; break }
    }
    if (-not $homeReady) { throw "Rendered Android home screen timed out for level $level" }
    & $adb -s emulator-5554 shell input tap ([int]($screenWidth * .5)) ([int]($screenHeight * .636))
    $raceReady = $false
    $raceCapture = Join-Path $root "tools/screenshots/android-visual-$level.png"
    $python = 'C:/Users/Home/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
    for ($raceAttempt = 0; $raceAttempt -lt 36; $raceAttempt++) {
        Start-Sleep -Seconds 5
        & $adb -s emulator-5554 shell screencap -p /data/local/tmp/animal-visual.png
        if ($LASTEXITCODE -ne 0) { continue }
        & $adb -s emulator-5554 pull /data/local/tmp/animal-visual.png $raceCapture
        if ($LASTEXITCODE -ne 0) { continue }
        & $python (Join-Path $PSScriptRoot 'check_android_race_frame.py') $raceCapture
        if ($LASTEXITCODE -eq 0) { $raceReady = $true; break }
        # An emulator's first frame can appear before its input queue resumes.
        # Retry PLAY only while the screenshot still shows the actual menu.
        & $python (Join-Path $PSScriptRoot 'check_android_race_frame.py') $raceCapture --home
        if ($LASTEXITCODE -eq 0) {
            & $adb -s emulator-5554 shell input tap ([int]($screenWidth * .5)) ([int]($screenHeight * .636))
        }
    }
    if (-not $raceReady) { throw "Android level $level never rendered its race HUD" }
    if ($level -eq 5) { & $adb -s emulator-5554 shell input tap ([int]($screenWidth * .815)) ([int]($screenHeight * .885)) }
    Start-Sleep -Seconds 8
    & $adb -s emulator-5554 shell screencap -p /data/local/tmp/animal-visual.png
    & $adb -s emulator-5554 pull /data/local/tmp/animal-visual.png $raceCapture
    & $python (Join-Path $PSScriptRoot 'check_android_race_frame.py') $raceCapture
    if ($LASTEXITCODE -ne 0) { throw 'Android race HUD was lost after touch input' }
    $pidText = & $adb -s emulator-5554 shell pidof com.animalswitch.game
    if (-not $pidText) { throw "Game stopped during Android level $level" }
    Write-Output "ANDROID_VISUAL_RUNNING level=$level process=$pidText"
}
& $adb -s emulator-5554 logcat -d -s godot AndroidRuntime | Set-Content (Join-Path $PSScriptRoot 'android_visual_runtime.log')
& $adb -s emulator-5554 shell am force-stop com.animalswitch.game
# Restore the emulator's own previous progress after this visual-only check.
& $adb -s emulator-5554 push (Join-Path $PSScriptRoot 'android_visual_save_backup.json') /data/local/tmp/animal_visual_backup.json
& $adb -s emulator-5554 shell run-as com.animalswitch.game cp /data/local/tmp/animal_visual_backup.json files/progress.json
Write-Output 'ANDROID_VISUAL_CHECK_COMPLETE'
