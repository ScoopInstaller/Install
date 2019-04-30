# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org/>

<#
.SYNOPSIS
    Scoop installer.
.DESCRIPTION
    The installer of Scoop. For details please check the website and wiki.
.PARAMETER ScoopDir
    Specifies directory to install.
    Scoop will be installed to '$env:USERPROFILE\scoop' if not specificed.
.PARAMETER ScoopGlobalDir
    Specifies global app directory.
    Global app will be installed to '$env:ProgramData\scoop' if not specificed.
.PARAMETER ScoopCacheDir
    Specifies cache directory.
    Cache directory will be '$ScoopDir\cache' if not specificed.
.PARAMETER NoProxy
    Specifies bypass system proxy or not while installation.
.PARAMETER Proxy
    Specifies proxy to use while installation.
.PARAMETER ProxyCredential
    Specifies credential for the prxoy.
.PARAMETER ProxyUseDefaultCredentials
    Use the credentials of the current user for the proxy server that is specified by the -Proxy parameter.
.PARAMETER RunAsAdmin
    Force to run the installer as administrator.
.LINK
    https://scoop.sh
.LINK
    https://github.com/lukesampson/scoop/wiki
#>
param(
    [String] $ScoopDir = "$env:USERPROFILE\scoop",
    [String] $ScoopGlobalDir = "$env:ALLUSERSPROFILE\scoop",
    [String] $ScoopCacheDir = "$ScoopDir\cache",
    [Switch] $NoProxy,
    [Uri] $Proxy,
    [System.Management.Automation.PSCredential] $ProxyCredential,
    [Switch] $ProxyUseDefaultCredentials,
    [Switch] $RunAsAdmin
)

$IS_EXECUTED_FROM_IEX = ($null -eq $MyInvocation.MyCommand.Path)
# Prepare environment variables
$SCOOP_DIR = $ScoopDir # Scoop root directory
$SCOOP_GLOBAL_DIR = $ScoopGlobalDir # Scoop global apps directory
$SCOOP_CACHE_DIR = $ScoopCacheDir # Scoop cache directory
$SCOOP_SHIMS_DIR = "$ScoopDir\shims" # Scoop shims directory
$SCOOP_APP_DIR = "$ScoopDir\apps\scoop\current" # Scoop itself directory
$SCOOP_MAIN_BUCKET_DIR = "$ScoopDir\buckets\main" # Scoop main bucket directory

# TODO: Use a specific version of Scoop and the main bucket
$SCOOP_PACKAGE_REPO = "https://github.com/lukesampson/scoop/archive/master.zip"
$SCOOP_MAIN_BUCKET_REPO = "https://github.com/scoopinstaller/scoop-main/archive/master.zip"

function Deny-Install {
    param(
        [String] $message,
        [Int] $errorCode = 1
    )

    Write-Host $message -f DarkRed
    Write-Output "Abort."

    # Don't abort if invoked with iex that would close the PS session
    if ($IS_EXECUTED_FROM_IEX) {
        break
    } else {
        exit $errorCode
    }
}

function Test-ValidateParameter {
    if ($null -eq $Proxy -and ($null -ne $ProxyCredential -or $ProxyUseDefaultCredentials)) {
        Deny-Install "Provide a valid proxy URI for the -Proxy parameter when using the -ProxyCredential or -ProxyUseDefaultCredentials."
    }

    if ($ProxyUseDefaultCredentials -and $null -ne $ProxyCredential) {
        Deny-Install "ProxyUseDefaultCredentials is conflict with ProxyCredential. Don't use the -ProxyCredential and -ProxyUseDefaultCredentials together."
    }
}

function Test-Prerequisite {
    # Scoop requires PowerShell 5 at least
    if (($PSVersionTable.PSVersion.Major) -lt 5) {
        Deny-Install "PowerShell 5 or greater is required to run Scoop. Go to https://docs.microsoft.com/en-us/powershell/ to get the latest version of PowerShell."
    }

    # Scoop requires TLS 1.2 SecurityProtocol, which exists in .NET Framework 4.5+
    if ([System.Enum]::GetNames([System.Net.SecurityProtocolType]) -notcontains 'Tls12') {
        Deny-Install "Scoop requires .NET Framework 4.5+ to work. Go to https://www.microsoft.com/net/download to get the latest version of .NET Framework."
    }

    # Ensure Robocopy.exe is accessible
    if (!([bool](Get-Command -Name 'robocopy' -ErrorAction SilentlyContinue))) {
        Deny-Install "Scoop requires 'C:\Windows\System32\Robocopy.exe' to work. Please make sure 'C:\Windows\System32' is in your PATH."
    }

    # Detect if RunAsAdministrator, there is no need to run as administrator when installing Scoop.
    if (!$RunAsAdmin -and ([Security.Principal.WindowsPrincipal]`
        [Security.Principal.WindowsIdentity]::GetCurrent()`
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Deny-Install "Don't run the installer as administrator!"
    }

    # Show notification to change execution policy
    if ((Get-ExecutionPolicy) -gt 'RemoteSigned' -or (Get-ExecutionPolicy) -eq 'ByPass') {
        Deny-Install "PowerShell requires an execution policy of 'RemoteSigned' to install Scoop. To change this please run 'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser'."
    }

    # Test if scoop is installed, by checking if scoop command exists.
    if ([bool](Get-Command -Name 'scoop' -ErrorAction SilentlyContinue)) {
        Deny-Install "Scoop is already installed. Run 'scoop update' to get the latest version."
    }
}

function Optimize-SecurityProtocol {
    # .NET Framework 4.7+ has a default security protocol called 'SystemDefault',
    # which allows the operating system to choose the best protocol to use.
    # If SecurityProtocolType contains 'SystemDefault' (means .NET4.7+ detected)
    # and the value of SecurityProtocol is 'SystemDefault', just do nothing on SecurityProtocol,
    # 'SystemDefault' will use TLS 1.2 if the webrequest requires.
    $isNewerNetFramework = ([System.Enum]::GetNames([System.Net.SecurityProtocolType]) -contains 'SystemDefault')
    $isSystemDefault = ([System.Net.ServicePointManager]::SecurityProtocol.Equals([System.Net.SecurityProtocolType]::SystemDefault))

    # If not, change it to support TLS 1.2
    if (!($isNewerNetFramework -and $isSystemDefault)) {
        # Set to TLS 1.2 (3072), then TLS 1.1 (768), and TLS 1.0 (192). Ssl3 has been superseded,
        # https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=netframework-4.5
        [System.Net.ServicePointManager]::SecurityProtocol = 3072 -bor 768 -bor 192
    }
}

function Get-Downloader {
    $downloadSession = New-Object System.Net.WebClient

    # Set proxy to null if NoProxy is specificed
    if ($NoProxy) {
        $downloadSession.Proxy = $null
    } elseif ($Proxy) {
        # Prepend protocol if not provided
        if (!$Proxy.IsAbsoluteUri) {
            $Proxy = New-Object System.Uri("http://" + $Proxy.OriginalString)
        }

        $Proxy = New-Object System.Net.WebProxy($Proxy)

        if ($null -ne $ProxyCredential) {
            $Proxy.Credentials = $ProxyCredential.GetNetworkCredential()
        } elseif ($ProxyUseDefaultCredentials) {
            $Proxy.UseDefaultCredentials = $true
        }

        $downloadSession.Proxy = $Proxy
    }

    return $downloadSession
}

function Test-isFileLocked {
    param(
        [String] $path
    )

    $file = New-Object System.IO.FileInfo $path

    if (!(Test-Path $path)) {
        return $false
    }

    try {
        $stream = $file.Open(
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None
        )
        if ($stream) {
            $stream.Close()
        }
        return $false
    }
    catch {
        # The file is locked by a process.
        return $true
    }
}

function Expand-Zipfile {
    param(
        [String] $path,
        [String] $to
    )

    if (!(Test-Path $path)) {
        Deny-Install "Unzip failed: can't find $path to unzip."
    }

    # Check if the zip file is locked, by antivirus software for example
    $retries = 0
    while ($retries -le 10) {
        if ($retries -eq 10) {
            Deny-Install "Unzip failed: can't unzip because a process is locking the file."
        }
        if (Test-isFileLocked $path) {
            Write-Output "Waiting for $path to be unlocked by another process... ($retries/10)"
            $retries++
            Start-Sleep -Seconds 2
        } else {
            break
        }
    }

    # PowerShell 5+: use Expand-Archive to extract zip files
    Microsoft.PowerShell.Archive\Expand-Archive -Path $path -DestinationPath $to -Force
}

function Import-ScoopShim($path) {
    if (!(Test-Path $SCOOP_SHIMS_DIR)) {
        New-Item -Type Directory $SCOOP_SHIMS_DIR | Out-Null
    }

    # The scoop shim
    $shim = "$SCOOP_SHIMS_DIR\scoop"

    # Convert to relative path
    Push-Location $SCOOP_SHIMS_DIR
    $relativePath = Resolve-Path -Relative $path
    Pop-Location

    # Setting PSScriptRoot in Shim if it is not defined, so the shim doesn't break in PowerShell 2.0
    Write-Output "if (!(Test-Path Variable:PSScriptRoot)) { `$PSScriptRoot = Split-Path `$MyInvocation.MyCommand.Path -Parent }" | Out-File "$shim.ps1" -Encoding utf8
    Write-Output "`$path = join-path `"`$PSScriptRoot`" `"$relativePath`"" | Out-File "$shim.ps1" -Encoding utf8 -Append
    Write-Output "if (`$MyInvocation.ExpectingInput) { `$input | & `$path @args } else { & `$path @args }" | Out-File "$shim.ps1" -Encoding utf8 -Append

    # Make scoop accessible from cmd.exe
    Write-Output "@echo off
setlocal enabledelayedexpansion
set args=%*
:: replace problem characters in arguments
set args=%args:`"='%
set args=%args:(=``(%
set args=%args:)=``)%
set invalid=`"='
if !args! == !invalid! ( set args= )
powershell -noprofile -ex unrestricted `"& '$path' %args%;exit `$lastexitcode`"" | Out-File "$shim.cmd" -Encoding ascii

    # Make scoop accessible from bash or other posix shell
    Write-Output "#!/bin/sh`npowershell.exe -ex unrestricted `"$path`" `"$@`"" | Out-File $shim -Encoding ascii
}

function Add-ShimsDirToPath {
    # Get $env:PATH of current user
    $userEnvPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')

    if($userEnvPath -notmatch [regex]::escape($SCOOP_SHIMS_DIR)) {
        $h = (Get-PsProvider 'FileSystem').Home
        if (!$h.endswith('\')) { $h += '\' }
        if (!($h -eq '\')) {
            $friendlyPath = "$SCOOP_SHIMS_DIR" -Replace ([regex]::escape($h)), "~\"
            Write-Output "Adding $friendlyPath to your path."
        } else {
            Write-Output "Adding $SCOOP_SHIMS_DIR to your path."
        }

        # For future sessions
        [System.Environment]::SetEnvironmentVariable('PATH', $SCOOP_SHIMS_DIR, 'User')
        # For current session
        $env:PATH = "$SCOOP_SHIMS_DIR;$env:PATH"
    }
}

function Install-Scoop {
    Write-Output 'Initializing...'
    Test-ValidateParameter
    Test-Prerequisite
    Optimize-SecurityProtocol

    # Download scoop zip from GitHub
    Write-Output 'Downloading...'
    $downloader = Get-Downloader
    # 1. download scoop
    $scoopZipfile = "$SCOOP_APP_DIR\scoop.zip"
    if (!(Test-Path $SCOOP_APP_DIR)) {
        New-Item -Type Directory $SCOOP_APP_DIR | Out-Null
    }
    $downloader.downloadFile($SCOOP_PACKAGE_REPO, $scoopZipfile)
    # 2. download scoop main bucket
    $scoopMainZipfile = "$SCOOP_MAIN_BUCKET_DIR\scoop-main.zip"
    if (!(Test-Path $SCOOP_MAIN_BUCKET_DIR)) {
        New-Item -Type Directory $SCOOP_MAIN_BUCKET_DIR | Out-Null
    }
    $downloader.downloadFile($SCOOP_MAIN_BUCKET_REPO, $scoopMainZipfile)

    # Extract files from downloaded zip
    Write-Output 'Extracting...'
    # 1. extract scoop
    $scoopUnzipTempDir = "$SCOOP_APP_DIR\_tmp"
    Expand-Zipfile $scoopZipfile $scoopUnzipTempDir
    Copy-Item "$scoopUnzipTempDir\scoop-*\*" $SCOOP_APP_DIR -Recurse -Force
    # 2. extract scoop main bucket
    $scoopMainUnzipTempDir = "$SCOOP_MAIN_BUCKET_DIR\_tmp"
    Expand-Zipfile $scoopMainZipfile $scoopMainUnzipTempDir
    Copy-Item "$scoopMainUnzipTempDir\scoop-main-*\*" $SCOOP_MAIN_BUCKET_DIR -Recurse -Force

    # Cleanup
    Remove-Item $scoopUnzipTempDir -Recurse -Force
    Remove-Item $scoopZipfile
    Remove-Item $scoopMainUnzipTempDir -Recurse -Force
    Remove-Item $scoopMainZipfile

    # Create the scoop shim
    Write-Output 'Creating shim...'
    Import-ScoopShim "$SCOOP_APP_DIR\bin\scoop.ps1"

    # Finially ensure scoop shims is in the PATH
    Add-ShimsDirToPath
    # Setup 'lastupdate' config
    scoop config lastupdate ([System.DateTime]::Now.ToString('o'))

    Write-Host 'Scoop was installed successfully!' -f DarkGreen
    Write-Output "Type 'scoop help' for instructions."
}

# Quit if anything goes wrong
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

# Bootstrap function
Install-Scoop

# Reset $ErrorActionPreference to original value
$ErrorActionPreference = $oldErrorActionPreference
