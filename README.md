# Scoop (un)installer

## Installation

### Prerequisites

- [PowerShell](https://aka.ms/powershell) latest version or [Windows PowerShell 5.1](https://aka.ms/wmf5download)

PowerShell execution policy is required to be one of: `Unrestricted`, `RemoteSigned` or `ByPass` to execute the installer. For example:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Typical Installation

Run this command from a **non-admin** PowerShell to install scoop with default configuration,
scoop will be install to `C:\Users\<YOUR USERNAME>\scoop`.

```powershell
iwr -useb get.scoop.sh | iex
```

### Advanced Installation

If you want to have an advanced installation. You can download the installer and manually execute it with parameters.

```powershell
iwr -useb get.scoop.sh -outfile 'install.ps1'
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
iwr -useb get.scoop.sh | iex
```

#### For Admin

Installation under the administrator console has been disabled by default for security considerations. If you know what you are doing and want to install Scoop as administrator. Please download the installer and manually execute it with the `-RunAsAdmin` parameter in an elevated console. Here is the example:

```powershell
iwr -useb get.scoop.sh -outfile 'install.ps1'
.\install.ps1 -RunAsAdmin [-OtherParameters ...]
```

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
