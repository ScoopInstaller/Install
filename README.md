# Scoop (un)installer

## Installation

### Prerequisites

- Windows 7 SP1+ / Windows Server 2008+, Windows 10 recommended
- [PowerShell 5](https://aka.ms/wmf5download) or later, [PowerShell Core](https://github.com/PowerShell/PowerShell) included
- [.NET Framework 4.5](https://microsoft.com/net/download) or later
- PowerShell execution policy must be enabled, e.g. `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Typical Installation

Run this command from a **non-admin** PowerShell to install scoop with default configuration,
scoop will be install to `C:\Users\<YOUR USERNAME>\scoop`.

```powershell
iwr -useb 'https://raw.githubusercontent.com/scoopinstaller/install/master/install.ps1' | iex
```

### Advanced Installation

If you want to have an advanced installation. You can download the installer and manually execute it with parameters.

```powershell
iwr -useb 'https://raw.githubusercontent.com/scoopinstaller/install/master/install.ps1' -outfile 'install.ps1'
```

To see all configurable parameters of the installer.

```powershell
.\install.ps1 -?
```

For example, install scoop to a custom directory, configure scoop to install
global programs to a custom directory, and bypass system proxy while installation.

```powershell
.\install.ps1 -ScoopDir 'D:\Applications\Scoop' -ScoopGlobalDir 'F:\GlobalScoopApps' -NoProxy
```

Or you can use the legacy method to configure custom directory by setting Environment Variables. (**Not Recommended**)

```powershell
$env:SCOOP='D:\Applications\Scoop'
$env:SCOOP_GLOBAL='F:\GlobalScoopApps'
[Environment]::SetEnvironmentVariable('SCOOP_GLOBAL', $env:SCOOP_GLOBAL, 'Machine')
iwr -useb 'https://raw.githubusercontent.com/scoopinstaller/install/master/install.ps1' | iex
```

**For Admin:** Installation under the administrator console has been disabled by default for security reason. If you know what you are doing and want to install Scoop as administrator. Please download the installer and manually execute it with the `-RunAsAdmin` parameter in an elevated console.

### Silent Installation

You can redirect all outputs to Out-Null or a log file to silence the installer. And you can use `$LASTEXITCODE` to check the installation result, it will be `0` when the installation success.

```powershell
# Omit outputs
.\install.ps1 [-Parameters ...] | Out-Null
# Or collect logs
.\install.ps1 [-Parameters ...] > install.log
# Get result
$LASTEXITCODE
```
