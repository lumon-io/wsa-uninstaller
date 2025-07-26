# WSAway - Windows Subsystem for Android Complete Removal Tool

<p align="center">
  <img src="https://img.shields.io/badge/version-3.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/platform-Windows%2010%2F11-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/PowerShell-5.0+-blue.svg" alt="PowerShell">
</p>

**WSAway** is a comprehensive removal tool for Windows Subsystem for Android (WSA) that ensures complete cleanup of all WSA components, including packages, folders, registry entries, firewall rules, and more.

## ✨ Features

### Core Features
- 🛡️ **Self-Protection**: Never deletes its own directory or parent folders
- 🎯 **Smart Detection**: Automatically finds WSA installations across your system
- 🔍 **Deep Scan Mode**: Thoroughly searches all drives for WSA components
- 💾 **Data Backup**: Backs up user data before removal (with restoration tool)
- 🔄 **System Restore**: Creates restore points before making changes
- 📝 **Detailed Logging**: Tracks all operations for troubleshooting

### Advanced Cleanup
- 🔥 **Firewall Rules**: Removes WSA-related Windows Firewall rules
- 🚀 **Startup Entries**: Cleans Task Scheduler and registry startup items
- 💻 **Hyper-V Settings**: Removes virtual switches and NAT configurations
- 🔧 **Environment Variables**: Cleans PATH and other environment settings
- 📁 **Registry Cleanup**: Removes all WSA-related registry entries

### User Experience
- 🖥️ **GUI Mode**: User-friendly graphical interface for easy operation
- 💬 **Interactive CLI**: Choose exactly what to remove
- 🏃 **Dry Run Mode**: Preview changes without executing them
- 🔄 **Update Checker**: Stay current with the latest version

## 🚀 Quick Start

### GUI Mode (Recommended for most users)
```batch
WSAway-GUI.bat
```

### CLI Mode
```batch
# Basic removal
WSAway.bat

# Interactive mode with backup
WSAway.bat -Interactive -BackupData

# Dry run to preview changes
WSAway.bat -DryRun -ScanForWSA

# Full cleanup with all options
WSAway.bat -BackupData -CreateRestorePoint -CleanFirewall -CleanStartup -CleanHyperV
```

## 📥 Installation

1. Download the latest release from [Releases](https://github.com/lumon-io/wsaway/releases)
2. Extract to a folder (NOT inside your WSA installation directory)
3. Run `WSAway-GUI.bat` for GUI or `WSAway.bat` for CLI

## 🖼️ Screenshots

### GUI Mode
The graphical interface provides:
- Real-time WSA status checking
- Checkbox options for all features
- Folder selection with safety warnings
- Progress tracking and detailed logs
- Multiple tabs for different functions

### CLI Mode
Command-line interface offers:
- Full parameter control
- Scriptable operations
- Interactive folder selection
- Colored output for clarity

## 📋 Command Line Options

| Option | Description |
|--------|-------------|
| `-GUI` | Launch graphical interface |
| `-BackupData` | Backup user data before removal |
| `-BackupPath <path>` | Custom backup location |
| `-ScanForWSA` | Deep scan all drives |
| `-Interactive` | Interactive folder selection |
| `-CreateRestorePoint` | Create system restore point |
| `-CleanFirewall` | Remove firewall rules |
| `-CleanStartup` | Remove startup entries |
| `-CleanHyperV` | Clean Hyper-V settings |
| `-DryRun` | Preview mode (no changes) |
| `-CustomPaths <paths>` | Additional paths to check |
| `-Help` | Show help information |
| `-Version` | Show version number |

## 🔄 Restoring Backed Up Data

To restore your WSA data after reinstalling:

```powershell
.\WSAway-Restore.ps1 -BackupFile "C:\Path\To\Your\WSA_userdata_backup.vhdx"
```

## 🛡️ Safety Features

1. **Self-Protection**: WSAway will never delete:
   - Its own directory
   - Parent directories
   - Any folder containing WSAway files

2. **Smart Detection**: Only targets folders with actual WSA components:
   - Install.ps1
   - Run.bat
   - WsaClient.exe
   - Kernel files
   - MSIX packages

3. **Interactive Warnings**: Protected folders are clearly marked with ⚠️

## 📁 What Gets Removed

### Packages & Applications
- Windows Subsystem for Android AppX package
- All associated Android apps

### Folders
- `%LOCALAPPDATA%\Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_*`
- WSA installation directories
- Custom installation locations

### System Components
- Firewall rules for WSA
- Scheduled tasks and startup entries
- Hyper-V virtual switches for WSA
- Environment variable entries
- Registry keys related to WSA

## 🔧 Requirements

- Windows 10/11
- PowerShell 5.0 or later
- Administrator privileges
- .NET Framework (for GUI mode)

## 🐛 Troubleshooting

### WSA processes won't stop
1. Close all Android apps manually
2. Open Task Manager and end WSA processes
3. Run WSAway again

### Permission errors
1. Ensure you're running as Administrator
2. Close any programs accessing WSA folders
3. Restart your computer if needed

### Can't find WSA folders
1. Use `-ScanForWSA` for deep scan
2. Add custom paths with `-CustomPaths`
3. Check the logs for scan results

## 📝 Logs

Logs are saved to:
- `%USERPROFILE%\Desktop\WSAway_Logs\`
- One log file per day
- Detailed operation tracking

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🙏 Credits

- Based on [WSABuilds](https://github.com/MustardChef/WSABuilds) uninstallation documentation
- Community feedback and contributions

## 📞 Support

- 🐛 Report issues: [GitHub Issues](https://github.com/lumon-io/wsaway/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/lumon-io/wsaway/discussions)
- 📧 Email: support@wsaway.app (if applicable)

---

**⚠️ Disclaimer**: This tool makes system-level changes. Always backup important data and create a system restore point before use. Use at your own risk.