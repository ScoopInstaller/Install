# Scoop (un)installer

Installation
------------

Run this command from your PowerShell to install scoop with default configuration, scoop will be install to `C:\Users\<user>\scoop`.

**Typical Installation**

```powershell
iwr -useb 'https://raw.githubusercontent.com/scoopinstaller/install/master/install.ps1' | iex
```

**Advanced Installation**

If you want to have an advanced installation, You can download the installer and manually execute it with parameters.

```powershell
iwr -useb 'https://raw.githubusercontent.com/scoopinstaller/install/master/install.ps1' -outfile 'install.ps1'
```

To see all configurable parameters of the installer.

```powershell
.\install.ps1 -?
```

For example, install scoop to a custom directory, configure scoop to install global programs to a custom directory, and bypass system proxy while installation.

```powershell
.\install.ps1 -ScoopDir 'D:\Applications\Scoop' -ScoopGlobalDir 'F:\GlobalScoopApps' -NoProxy
```
