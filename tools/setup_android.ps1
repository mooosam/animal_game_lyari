$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = Split-Path $PSScriptRoot -Parent
$androidRoot = Join-Path $PSScriptRoot 'android'
$jdkRoot = (Get-ChildItem (Join-Path $androidRoot 'java') -Directory | Select-Object -First 1).FullName
$env:JAVA_HOME = $jdkRoot
$env:ANDROID_HOME = Join-Path $androidRoot 'sdk'
$manager = Join-Path $env:ANDROID_HOME 'cmdline-tools/latest/bin/sdkmanager.bat'
(1..100 | ForEach-Object { 'y' }) | & $manager --sdk_root=$env:ANDROID_HOME --licenses
& $manager --sdk_root=$env:ANDROID_HOME 'platform-tools' 'build-tools;35.0.1' 'platforms;android-35'
if ($LASTEXITCODE -ne 0) { throw 'SDK package installation failed' }
$keystore = Join-Path $androidRoot 'debug.keystore'
if (-not (Test-Path $keystore)) {
    & (Join-Path $jdkRoot 'bin/keytool.exe') -genkeypair -keystore $keystore -storepass android -alias androiddebugkey -keypass android -dname 'CN=Android Debug,O=Animal Switch,C=US' -keyalg RSA -keysize 2048 -validity 10000
}
$configRoot = Join-Path $env:APPDATA 'Godot'
New-Item -ItemType Directory -Force $configRoot | Out-Null
$configPath = Join-Path $configRoot 'editor_settings-4.7.tres'
if (Test-Path $configPath) { $settings = Get-Content $configPath -Raw }
else { $settings = "[gd_resource type=`"EditorSettings`" format=3]`n`n[resource]`n" }
$values = @{'export/android/android_sdk_path'=$env:ANDROID_HOME; 'export/android/java_sdk_path'=$jdkRoot; 'export/android/debug_keystore'=$keystore}
foreach ($key in $values.Keys) {
    $entry = $key + ' = "' + $values[$key].Replace('\','/') + '"'
    $pattern = '(?m)^' + [regex]::Escape($key) + ' = .*?$'
    if ($settings -match $pattern) { $settings = [regex]::Replace($settings,$pattern,[System.Text.RegularExpressions.MatchEvaluator]{param($m) $entry}) }
    else { $settings += $entry + "`n" }
}
[IO.File]::WriteAllText($configPath,$settings)
& (Join-Path $env:ANDROID_HOME 'platform-tools/adb.exe') devices
Write-Output 'ANDROID_SETUP_COMPLETE'
