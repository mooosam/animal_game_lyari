param([string]$Platform = 'Android')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$engine = 'C:\Users\Home\Downloads\Godot_v4.7.2-stable_win64_console.exe'
New-Item -ItemType Directory -Force (Join-Path $root 'builds') | Out-Null
$extension = 'apk'
if ($Platform -eq 'Windows') { $extension = 'exe' }
& $engine --headless --path (Join-Path $root 'game') --export-debug $Platform (Join-Path $root "builds/AnimalSwitch.$extension")
if ($LASTEXITCODE -ne 0) { throw "$Platform export failed" }
Write-Output "BUILD_COMPLETE $Platform"
