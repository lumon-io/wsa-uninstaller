# WSA Uninstaller

Automated uninstallation script for Windows Subsystem for Android (WSA), including WSABuilds installations.

## Features

- Automatically detects and uninstalls WSA
- Stops running WSA processes
- Optional backup of user data (userdata.vhdx)
- Cleans up leftover folders
- Administrator privilege handling
- Support for both Microsoft Store and WSABuild installations

## Usage

### Basic Uninstall (No Backup)
```batch
uninstall-wsa.bat
```

### Uninstall with Data Backup
```batch
uninstall-wsa.bat -backup
```

Or run the PowerShell script directly:
```powershell
.\uninstall-wsa.ps1 -BackupData
```

## What Gets Removed

1. Windows Subsystem for Android package
2. WSA data folder at `%LOCALAPPDATA%\Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe`
3. All WSA processes

## Data Backup

If you use the `-backup` flag, your user data (userdata.vhdx) will be saved to:
`%USERPROFILE%\Desktop\WSA_Backup\WSA_userdata_[timestamp].vhdx`

This file can be restored if you reinstall WSA in the future.

## Requirements

- Windows 10/11
- PowerShell 5.0 or later
- Administrator privileges (script will auto-elevate)

## Notes

- The script will prompt you to manually delete the WSABuild extraction folder if applicable
- Make sure to close all Android apps before running
- The script will attempt to stop WSA automatically, but may require manual intervention if apps are unresponsive

## Credits

Based on the uninstallation documentation from [WSABuilds](https://github.com/MustardChef/WSABuilds)