param([string]$Mode = 'test', [int]$Level = 4, [string]$Resolution = '540x960')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$engine = 'C:\Users\Home\Downloads\Godot_v4.7.2-stable_win64_console.exe'
$game = Join-Path $root 'game'
if ($Mode -eq 'test') {
    & $engine --headless --path $game --script res://tests/test_game.gd
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed' }
    & $engine --headless --path $game --script res://tests/test_ui.gd
    if ($LASTEXITCODE -ne 0) { throw 'UI integration checks failed' }
    & $engine --headless --path $game --script res://tests/test_natural_motion.gd
    if ($LASTEXITCODE -ne 0) { throw 'Natural motion checks failed' }
    & $engine --headless --path $game --script res://tests/test_foreleg_direction.gd
    if ($LASTEXITCODE -ne 0) { throw 'Foreleg direction checks failed' }
    & $engine --headless --path $game --script res://tests/test_roster50.gd
    if ($LASTEXITCODE -ne 0) { throw '50-animal asset checks failed' }
    foreach ($n in 1..10) {
        & $engine --headless --path $game --fixed-fps 60 -- "--auto-level=$n"
        if ($LASTEXITCODE -ne 0) { throw "Auto race $n failed" }
    }
} elseif ($Mode -eq 'capture') {
    $shot = (Join-Path $root "tools/screenshots/level-$Level-$Resolution.png").Replace('\','/')
    & $engine --path $game --resolution $Resolution --quit-after 700 -- "--auto-level=$Level" "--screenshot=$shot"
} elseif ($Mode -eq 'play') {
    & $engine --path $game --resolution $Resolution
} elseif ($Mode -eq 'import') {
    & $engine --headless --editor --path $game --import
}
