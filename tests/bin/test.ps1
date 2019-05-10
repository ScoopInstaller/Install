#requires -Version 5.0
#requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '4.4.0' }
#requires -Modules @{ ModuleName = 'PSScriptAnalyzer'; ModuleVersion = '1.17.1' }

param(
    [String] $TestPath = 'tests/'
)

$resultsXml = "$PSScriptRoot/TestResults.xml"
$excludes = @()

$splat = @{
    Path         = $TestPath
    OutputFile   = $resultsXml
    OutputFormat = 'NUnitXML'
    PassThru     = $true
}

if ($env:CI -eq $true) {
    $commit = if ($env:APPVEYOR_PULL_REQUEST_HEAD_COMMIT) { $env:APPVEYOR_PULL_REQUEST_HEAD_COMMIT } else { $env:APPVEYOR_REPO_COMMIT }
    $commitMessage = "$env:APPVEYOR_REPO_COMMIT_MESSAGE $env:APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED".TrimEnd()

    if ($commitMessage -match '!linter') {
        Write-Warning "Skipping code linting per commit flag '!linter'"
        $excludes += 'Linter'
    }

    $changed_scripts = (Get-GitChangedFile -Include '*.ps1' -Commit $commit)
    if (!$changed_scripts) {
        Write-Warning "Skipping tests and code linting for *.ps1 files because they didn't change"
        $excludes += 'Linter'
        $excludes += 'Scoop'
    }

    if ($excludes.Length -gt 0) {
        $splat.ExcludeTag = $excludes
    }
}

Write-Host 'Invoke-Pester' @splat
$result = Invoke-Pester @splat

if ($env:CI -eq $true) {
    (New-Object Net.WebClient).UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", $resultsXml)
}

if ($result.FailedCount -gt 0) {
    exit $result.FailedCount
}
