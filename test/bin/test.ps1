#Requires -Version 5.1
#Requires -Modules @{ ModuleName = 'BuildHelpers'; ModuleVersion = '2.0.1' }
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }
#Requires -Modules @{ ModuleName = 'PSScriptAnalyzer'; ModuleVersion = '1.17.1' }

param(
    [String] $TestPath = "$PSScriptRoot\.."
)

$pesterConfig = New-PesterConfiguration -Hashtable @{
    Run    = @{
        Path     = $TestPath
        PassThru = $true
    }
    Output = @{
        Verbosity = 'Detailed'
    }
}
$excludes = @()

if ($env:CI -eq $true) {
    Set-BuildEnvironment -Force

    $commit = $env:BHCommitHash
    $commitMessage = $env:BHCommitMessage

    if ($commitMessage -match '!linter') {
        Write-Warning "Skipping code linting per commit flag '!linter'"
        $excludes += 'Linter'
    }

    $changed_scripts = (Get-GitChangedFile -Include '*.ps1', '*.psd1', '*.psm1' -Commit $commit)
    if (!$changed_scripts) {
        Write-Warning "Skipping tests and code linting for PowerShell scripts because they didn't change"
        $excludes += 'Linter'
    }

    if ($excludes.Length -gt 0) {
        $pesterConfig.Filter.ExcludeTag = $excludes
    }
}
if ($env:BHBuildSystem -eq 'AppVeyor') {
    # AppVeyor
    $resultsXml = "$PSScriptRoot\TestResults.xml"
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = $resultsXml
    $result = Invoke-Pester -Configuration $pesterConfig
    Add-TestResultToAppveyor -TestFile $resultsXml
} else {
    # GitHub Actions / Local
    $result = Invoke-Pester -Configuration $pesterConfig
}

exit $result.FailedCount
