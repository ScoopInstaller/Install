Describe 'PSScriptAnalyzer' -Tag 'Linter' {
    BeforeDiscovery {
        $scriptDir = @('.', 'test')
    }

    BeforeAll {
        $lintSettings = "$PSScriptRoot\..\PSScriptAnalyzerSettings.psd1"
    }

    It 'PSScriptAnalyzerSettings.ps1 should exist' {
        $lintSettings | Should -Exist
    }

    Context 'Linting all *.psd1, *.psm1 and *.ps1 files' {
        BeforeEach {
            $analysis = Invoke-ScriptAnalyzer -Path "$PSScriptRoot\..\$_" -Settings $lintSettings
        }
        It 'Should pass: <_>' -TestCases $scriptDir {
            if ($analysis) {
                foreach ($result in $analysis) {
                    switch -wildCard ($result.ScriptName) {
                        '*.psm1' { $type = 'Module' }
                        '*.ps1' { $type = 'Script' }
                        '*.psd1' { $type = 'Manifest' }
                    }
                    $t = $Host.UI.RawUI.ForegroundColor
                    $Host.UI.RawUI.ForegroundColor = 'Yellow'
                    Write-Output "     [*] $($result.Severity): $($result.Message)"
                    Write-Output "         $($result.RuleName) in $type`: $directory\$($result.ScriptName):$($result.Line)"
                    $Host.UI.RawUI.ForegroundColor = $t
                }
            }
            $analysis | Should -HaveCount 0
        }
    }
}
