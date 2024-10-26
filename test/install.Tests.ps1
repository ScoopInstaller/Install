BeforeAll {
    # Load SUT
    $sut = (Split-Path -Leaf $PSCommandPath).Replace('.Tests.ps1', '.ps1')
    . ".\$sut"
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

Describe 'Get-Scoop-Source' -Tag 'Scoop' {
    Context 'No source parameters provided' {
        It 'Returns default source URLs' {
            $expectedSource = @{
                AppRepoZip        = "https://github.com/ScoopInstaller/Scoop/archive/master.zip"
                AppRepoGit        = "https://github.com/ScoopInstaller/Scoop.git"
                MainBucketRepoZip = "https://github.com/ScoopInstaller/Main/archive/master.zip"
                MainBucketRepoGit = "https://github.com/ScoopInstaller/Main.git"
            }
            $actualSource = Get-Scoop-Source
            $actualSourceJson = $actualSource | ConvertTo-Json
            $expectedSourceJson = $expectedSource | ConvertTo-Json
            $actualSourceJson | Should -Be $expectedSourceJson
        }
    }

    Context 'Selected source parameters provided' {
        It 'Provide all source parameters as arguments' {
            $providedSource = @{
                AppRepoZip        = "https://example.com/apprepo.zip"
                AppRepoGit        = "https://example.com/apprepo.git"
                MainBucketRepoZip = "https://example.com/mainbucket.zip"
                MainBucketRepoGit = "https://example.com/mainbucket.git"
            }
            $actualSource = Get-Scoop-Source -ScoopAppRepoZip $providedSource.AppRepoZip `
                -ScoopAppRepoGit $providedSource.AppRepoGit `
                -ScoopMainBucketRepoZip $providedSource.MainBucketRepoZip `
                -ScoopMainBucketRepoGit $providedSource.MainBucketRepoGit
            $actualSourceJson = $actualSource | ConvertTo-Json
            $expectedSourceJson = $providedSource | ConvertTo-Json
            $actualSourceJson | Should -Be $expectedSourceJson
        }

        It 'Provide app repo zip url as argument' {
            $actualSource = Get-Scoop-Source -ScoopAppRepoZip "https://example.com/apprepo.zip"
            $actualSourceJson = $actualSource | ConvertTo-Json
            $expectedSourceJson = @{
                AppRepoZip        = "https://example.com/apprepo.zip"
                AppRepoGit        = $null
                MainBucketRepoZip = $null
                MainBucketRepoGit = $null
            } | ConvertTo-Json
            $actualSourceJson | Should -Be $expectedSourceJson
        }

        It 'Provide app repo git url as argument' {
            $actualSource = Get-Scoop-Source -ScoopAppRepoGit "https://example.com/apprepo.git"
            $actualSourceJson = $actualSource | ConvertTo-Json
            $expectedSourceJson = @{
                AppRepoZip        = $null
                AppRepoGit        = "https://example.com/apprepo.git"
                MainBucketRepoZip = $null
                MainBucketRepoGit = $null
            } | ConvertTo-Json
            $actualSourceJson | Should -Be $expectedSourceJson
        }

        It 'Provide main bucket repo zip url as argument' {
            $actualSource = Get-Scoop-Source -ScoopMainBucketRepoZip "https://example.com/mainbucket.zip"
            $actualSourceJson = $actualSource | ConvertTo-Json
            $expectedSourceJson = @{
                AppRepoZip        = "https://github.com/ScoopInstaller/Scoop/archive/master.zip"
                AppRepoGit        = "https://github.com/ScoopInstaller/Scoop.git"
                MainBucketRepoZip = "https://example.com/mainbucket.zip"
                MainBucketRepoGit = "https://github.com/ScoopInstaller/Main.git"
            } | ConvertTo-Json
            $actualSourceJson | Should -Be $expectedSourceJson
        }
    }
}
