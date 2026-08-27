BeforeAll {
    $script:OriginalScoop = $env:SCOOP
    $script:OriginalScoopGlobal = $env:SCOOP_GLOBAL
    $script:OriginalScoopNoInstall = $env:SCOOP_NOINSTALL

    $env:SCOOP = Join-Path $TestDrive 'scoop'
    $env:SCOOP_GLOBAL = Join-Path $TestDrive 'scoop-global'
    $env:SCOOP_NOINSTALL = 'true'

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

    if ($null -eq $script:OriginalScoopNoInstall) {
        Remove-Item Env:SCOOP_NOINSTALL -ErrorAction SilentlyContinue
    } else {
        $env:SCOOP_NOINSTALL = $script:OriginalScoopNoInstall
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

Describe 'Test-ValidateParameter' -Tag 'PathValidation' {
    It 'rejects invalid characters in <PathVariable>' -TestCases @(
        @{ PathVariable = 'SCOOP_DIR'; InvalidLeaf = 'invalid-root-with*asterisk' }
        @{ PathVariable = 'SCOOP_GLOBAL_DIR'; InvalidLeaf = 'invalid-global-with*asterisk' }
        @{ PathVariable = 'SCOOP_CACHE_DIR'; InvalidLeaf = 'invalid-cache-with*asterisk' }
    ) {
        param(
            [string] $PathVariable,
            [string] $InvalidLeaf
        )

        Mock Deny-Install {}

        $InvalidPath = Join-Path $TestDrive $InvalidLeaf

        Set-Variable -Name $PathVariable -Value $InvalidPath

        Test-ValidateParameter

        Should -Invoke Deny-Install -Times 1 -Exactly -ParameterFilter {
            $Message -like "*'$InvalidPath' is not a valid path*"
        }
    }

    It 'rejects when path <PathVariable> is a file' -TestCases @(
        @{ PathVariable = 'SCOOP_DIR'; InvalidLeaf = 'invalid-root-file.txt' }
        @{ PathVariable = 'SCOOP_GLOBAL_DIR'; InvalidLeaf = 'invalid-global-file.txt' }
        @{ PathVariable = 'SCOOP_CACHE_DIR'; InvalidLeaf = 'invalid-cache-file.txt' }
    ) {
        param(
            [string] $PathVariable,
            [string] $InvalidLeaf
        )

        Mock Deny-Install {}

        $InvalidPath = Join-Path $TestDrive $InvalidLeaf
        New-Item -Path $InvalidPath -ItemType File | Out-Null

        Set-Variable -Name $PathVariable -Value $InvalidPath

        Test-ValidateParameter

        Should -Invoke Deny-Install -Times 1 -Exactly -ParameterFilter {
            $Message -like "*'$InvalidPath' is a file*"
        }
    }

    It 'rejects when path <PathVariable> is not empty' -TestCases @(
        @{ PathVariable = 'SCOOP_DIR'; InvalidLeaf = 'invalid-root-nonempty' }
        @{ PathVariable = 'SCOOP_GLOBAL_DIR'; InvalidLeaf = 'invalid-global-nonempty' }
    ) {
        param(
            [string] $PathVariable,
            [string] $InvalidLeaf
        )

        Mock Deny-Install {}

        $InvalidPath = Join-Path $TestDrive $InvalidLeaf
        New-Item -Path $InvalidPath -ItemType Directory | Out-Null
        New-Item -Path (Join-Path $InvalidPath 'dummy.txt') -ItemType File | Out-Null

        Set-Variable -Name $PathVariable -Value $InvalidPath

        Test-ValidateParameter

        Should -Invoke Deny-Install -Times 1 -Exactly -ParameterFilter {
            $Message -like "*'$InvalidPath' exists and is not empty*"
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
