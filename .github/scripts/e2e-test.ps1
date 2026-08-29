#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

if ($env:CI -ne $true -or $env:GITHUB_ACTIONS -ne $true) {
    throw 'This script is intended to be run in GitHub Actions CI environment only'
}

$WorkingRoot = "$PSScriptRoot\..\.."

# Typical installation
Write-Output '# Testing typical installation'
& "$WorkingRoot\install.ps1"
Write-Output "$Env:USERPROFILE\scoop\shims" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
$configFilePath = "$Env:USERPROFILE\scoop\config.json"
if (-not (Test-Path -Path $configFilePath)) {
    throw 'Scoop config file should exist after installation'
}
scoop help
scoop config use_sqlite_cache true
Write-Output "Config file: $configFilePath"
Get-Content -Raw -Path $configFilePath | Write-Output
Remove-Item -Path "$Env:USERPROFILE\scoop" -Recurse -Force -ErrorAction SilentlyContinue

# Fall back to download zips when git not available
git config --global protocol.https.allow never
# Custom installation directory
$CustomScoopDir = "$Env:USERPROFILE\custom_scoop"
$env:XDG_CONFIG_HOME = "$Env:USERPROFILE\.config"
Write-Output '# Testing installation with custom directory and XDG_CONFIG_HOME set'
& "$WorkingRoot\install.ps1" -ScoopDir $CustomScoopDir
Write-Output "$CustomScoopDir\shims" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
$configFilePath = "$env:XDG_CONFIG_HOME\scoop\config.json"
if (-not (Test-Path -Path $configFilePath)) {
    throw 'Scoop config file should exist after installation (XDG)'
}
scoop help
Write-Output "Config file: $configFilePath"
Get-Content -Raw -Path $configFilePath | Write-Output
