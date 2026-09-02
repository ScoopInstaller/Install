#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

if ($env:CI -ne $true -or $env:GITHUB_ACTIONS -ne $true) {
    throw 'This script is intended to be run in GitHub Actions CI environment only'
}

Write-Output "$Env:USERPROFILE\scoop\shims" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
$WorkingRoot = "$PSScriptRoot\..\.."

# Typical installation
& "$WorkingRoot\install.ps1"
if (-not (Test-Path -Path "$Env:USERPROFILE\.config\scoop\config.json")) {
    throw 'Scoop config file should exist after installation'
}
scoop help
Remove-Item -Path "$Env:USERPROFILE\scoop" -Recurse -Force -ErrorAction SilentlyContinue

# Fall back to download zips when git not available
git config --global protocol.https.allow never
# Custom installation directory
$CustomScoopDir = "$Env:USERPROFILE\custom_scoop"
& "$WorkingRoot\install.ps1" -ScoopDir $CustomScoopDir
Write-Output "$CustomScoopDir\shims" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
scoop help
Get-Content -Raw -Path "$env:USERPROFILE\.config\scoop\config.json" | Write-Output
