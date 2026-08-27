BeforeAll {
    $script:OriginalScoop = $env:SCOOP
    $script:OriginalScoopGlobal = $env:SCOOP_GLOBAL

    $env:SCOOP = Join-Path $TestDrive 'scoop'
    $env:SCOOP_GLOBAL = Join-Path $TestDrive 'scoop-global'

    # Load SUT
    $sut = (Split-Path -Leaf $PSCommandPath).Replace('.Tests.ps1', '.ps1')
    . ".\$sut"
}

AfterAll {
    if ($null -eq $script:OriginalScoop) {
        Remove-Item Env:SCOOP -ErrorAction SilentlyContinue
    } else {
        $env:SCOOP = $script:OriginalScoop
    }

    if ($null -eq $script:OriginalScoopGlobal) {
        Remove-Item Env:SCOOP_GLOBAL -ErrorAction SilentlyContinue
    } else {
        $env:SCOOP_GLOBAL = $script:OriginalScoopGlobal
    }
}

Describe 'Get-Downloader' -Tag 'Proxy' {
    Context 'No proxy given via script parameter' {
        It 'Returns WebClient without proxy' {
            $NoProxy = $true
            Test-ValidateParameter
            (Get-Downloader).Proxy | Should -Be $null
        }
        It 'Returns WebClient without proxy although proxy is given' {
            $NoProxy = $true
            $Proxy = New-Object System.Uri('http://donotcare')
            Test-ValidateParameter
            (Get-Downloader).Proxy | Should -Be $null
        }
    }
    Context 'Proxy given via script parameter' {
        It 'Returns WebClient with proxy' {
            $ProxyString = 'http://some.proxy.with.port:8080'
            $Proxy = New-Object System.Uri($ProxyString)
            Test-ValidateParameter
            (Get-Downloader).Proxy.Address | Should -Be "$ProxyString/"
        }
    }
}

Describe 'Test-CommandAvailable' -Tag 'CommandLine' {
    Context 'Command available' {
        It 'Returns $true' {
            Test-CommandAvailable -Command 'git' | Should -Be $true
        }
    }
    Context 'Command not available' {
        It 'Returns $false' {
            Test-CommandAvailable -Command 'notavailable' | Should -Be $false
        }
    }
}
