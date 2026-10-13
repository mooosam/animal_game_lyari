$ErrorActionPreference = 'Stop'
$sdkEmulatorRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'android/sdk/emulator'))
Get-Process | Where-Object { $_.Path -and $_.Path.StartsWith($sdkEmulatorRoot,[StringComparison]::OrdinalIgnoreCase) } | Stop-Process -Force
Write-Output 'PROJECT_EMULATOR_STOPPED'
