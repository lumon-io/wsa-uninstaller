# WSA Uninstaller v2.1

Advanced uninstallation script for Windows Subsystem for Android (WSA), including WSABuilds and custom installations.

> **Important**: This script is designed to be safe and will NOT delete its own directory or any folder containing the uninstaller files.

## Features

- **Self-Protection**: Will NOT delete its own directory or parent directory
- **Automatic Detection**: Finds WSA installations in common and custom locations
- **Deep Scan Mode**: Searches all drives for WSA folders
- **Interactive Mode**: Select which folders to remove (with safety warnings)
- **Process Management**: Automatically stops running WSA processes
- **Data Backup**: Optional backup of user data (userdata.vhdx)
- **Registry Cleanup**: Removes WSA-related registry entries
- **Custom Path Support**: Specify additional paths to check
- **Multi-Installation Support**: Handles various WSA installation methods

## Usage

### Basic Uninstall (Quick Mode)
```batch
uninstall-wsa.bat
```

### Interactive Mode
Let the script find WSA folders and choose which to remove:
```batch
uninstall-wsa.bat -interactive
# or shorthand
uninstall-wsa.bat -i
```

### Deep Scan Mode
Perform a thorough scan of all drives for WSA installations:
```batch
uninstall-wsa.bat -scan
```

### Backup User Data
```batch
uninstall-wsa.bat -backup
```

### Combined Options
```batch
# Interactive mode with backup and deep scan
uninstall-wsa.bat -backup -scan -interactive
```

### PowerShell Direct Usage
```powershell
# Basic
.\uninstall-wsa.ps1

# With options
.\uninstall-wsa.ps1 -BackupData -ScanForWSA -Interactive

# Custom paths
.\uninstall-wsa.ps1 -CustomPaths @("D:\MyWSA", "E:\AndroidSubsystem")
```

## What Gets Detected and Removed

### Automatic Detection Locations
- `%ProgramFiles%\WSA`
- `%ProgramFiles%\WindowsSubsystemForAndroid`
- `%USERPROFILE%\WSA`
- `%USERPROFILE%\Downloads\WSA*`
- `%USERPROFILE%\Desktop\WSA*`
- Common drive roots (C:\WSA, D:\WSA, etc.)

### Detection Criteria
The script identifies WSA folders by looking for:
- Install.ps1 files
- Run.bat files
- WsaClient.exe
- Kernel files
- MSIX packages

### What Gets Cleaned
1. Windows Subsystem for Android AppX package
2. WSA data folder at `%LOCALAPPDATA%\Packages\`
3. WSA installation folders (with user confirmation in interactive mode)
4. Registry entries related to WSA
5. Running WSA processes

## Data Backup

When using the `-backup` flag:
- Location: `%USERPROFILE%\Desktop\WSA_Backup\`
- Filename: `WSA_userdata_[timestamp].vhdx`
- This file contains your Android apps and data
- Can be restored when reinstalling WSA

## Requirements

- Windows 10/11
- PowerShell 5.0 or later
- Administrator privileges (script will auto-elevate)

## Command Line Options

| Option | Description |
|--------|-------------|
| `-backup` | Backup user data before uninstalling |
| `-scan` | Perform deep scan across all drives |
| `-interactive` or `-i` | Interactive mode to select folders |
| `-help` or `-?` | Show help message |

## Safety Features

- **Self-Protection**: The script will never delete:
  - The directory containing `uninstall-wsa.ps1`
  - The parent directory of the uninstaller
  - Any folder that contains the uninstaller files
- **Interactive Warnings**: Folders containing the uninstaller are marked with ⚠️
- **Smart Detection**: Only identifies folders with actual WSA installation files

## Notes

- The script automatically elevates to Administrator if needed
- Close all Android apps before running
- Deep scan mode may take several minutes on large drives
- Interactive mode is recommended for custom installations
- The script will not delete folders without confirmation in interactive mode
- Place the uninstaller in a separate folder from your WSA installation for best results

## Troubleshooting

If WSA processes won't stop:
1. Close all Android apps manually
2. Open Task Manager and end any WSA-related processes
3. Run the script again

If folders can't be deleted:
1. Restart your computer
2. Run the script again
3. If issues persist, delete folders manually

## Credits

Based on the uninstallation documentation from [WSABuilds](https://github.com/MustardChef/WSABuilds)