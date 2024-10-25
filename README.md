# Scoop (un)installer

[![ci-badge](https://github.com/ScoopInstaller/Install/actions/workflows/ci.yml/badge.svg)](https://github.com/ScoopInstaller/Install/actions/workflows/ci.yml)

## Installation

### Prerequisites

[PowerShell](https://aka.ms/powershell) latest version or [Windows PowerShell 5.1](https://aka.ms/wmf5download)

- The PowerShell [Language Mode] is required to be `FullLanguage` to run the installer and Scoop.
- The PowerShell [Execution Policy] is required to be one of `RemoteSigned`, `Unrestricted` or `ByPass` to run the installer. For example, it can be set to `RemoteSigned` via:

  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

### Typical Installation

Run this command from a **non-admin** PowerShell to install scoop with default configuration,
scoop will be install to `C:\Users\<YOUR USERNAME>\scoop`.

```powershell
irm get.scoop.sh | iex
# You can use proxies if you have network trouble in accessing GitHub, e.g.
irm get.scoop.sh -Proxy 'http://<ip:port>' | iex
```

### Advanced Installation

If you want to have an advanced installation, you can download the installer and manually execute it with parameters.

```powershell
irm get.scoop.sh -outfile 'install.ps1'
```

To see all configurable parameters of the installer.

```powershell
.\install.ps1 -?
```

For example, you could install scoop to a custom directory, configure scoop to install
global programs to a custom directory, and bypass system proxy during installation.

```powershell
.\install.ps1 -ScoopDir 'D:\Applications\Scoop' -ScoopGlobalDir 'F:\GlobalScoopApps' -NoProxy
```

Or you can use the legacy method to configure custom directory by setting Environment Variables. (**Not Recommended**)

```powershell
$env:SCOOP='D:\Applications\Scoop'
$env:SCOOP_GLOBAL='F:\GlobalScoopApps'
[Environment]::SetEnvironmentVariable('SCOOP_GLOBAL', $env:SCOOP_GLOBAL, 'Machine')
irm get.scoop.sh | iex
```

#### For Admin

Installation under the administrator console has been disabled by default for security considerations. If you know what you are doing and want to install Scoop as administrator. Please download the installer and manually execute it with the `-RunAsAdmin` parameter in an elevated console. Here is the example:

```powershell
irm get.scoop.sh -outfile 'install.ps1'
.\install.ps1 -RunAsAdmin [-OtherParameters ...]
# I don't care about other parameters and want a one-line command
iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
```

#### Offline installation

By default, the installer will download content from the official Scoop Git repos.
For a full offline installation you can pre-download the following files:

- https://github.com/ScoopInstaller/Scoop/archive/master.zip as `ScoopInstaller-Scoop.zip`
- https://github.com/ScoopInstaller/Main/archive/master.zip as `ScoopInstaller-Main.zip`

And then run:

```shell
# From a local folder
.\install.ps1 -OfflineSourceFolder 'C:\Local\Path\To\Zip\Files'

# From a network path
.\install.ps1 -OfflineSourceFolder '\\UNC\Path\To\Zip\Files'
```

The installer will copy/extract the provided ZIP files as needed. They are not deleted afterwards.

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

## License

The project is released under the [Unlicense License](LICENSE) and into the public domain.

[Language Mode]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes
[Execution Policy]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies
