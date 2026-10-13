$root = Split-Path $PSScriptRoot -Parent
Start-Process -FilePath (Join-Path $root 'builds/AnimalSwitch.exe') -WorkingDirectory (Join-Path $root 'builds')
