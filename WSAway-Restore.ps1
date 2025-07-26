# WSAway Restore Tool
# Restores WSA user data from backup

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
WSAway Restore Tool - Restore WSA user data from backup

Usage: WSAway-Restore.ps1 -BackupFile <path>

Parameters:
  -BackupFile    Path to the backed up userdata.vhdx file
  -Help          Show this help message

Example:
  .\WSAway-Restore.ps1 -BackupFile "C:\Users\User\Desktop\WSA_Backup\WSA_userdata_20240101_120000.vhdx"

Note: WSA must be installed before restoring user data.
"@
    exit
}

Write-Host "WSAway Restore Tool" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

# Check if backup file exists
if (-not (Test-Path $BackupFile)) {
    Write-Host "Error: Backup file not found: $BackupFile" -ForegroundColor Red
    exit 1
}

# Check if WSA is installed
$wsaPackage = Get-AppxPackage -Name "MicrosoftCorporationII.WindowsSubsystemForAndroid" -ErrorAction SilentlyContinue
if (-not $wsaPackage) {
    Write-Host "Error: WSA is not installed. Please install WSA first before restoring data." -ForegroundColor Red
    exit 1
}

# Find WSA data folder
$wsaDataPath = "$env:LOCALAPPDATA\Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe\LocalCache"
if (-not (Test-Path $wsaDataPath)) {
    Write-Host "Error: WSA data folder not found. Please run WSA at least once." -ForegroundColor Red
    exit 1
}

# Check if WSA is running
$wsaRunning = Get-Process -Name "WsaClient", "WsaService" -ErrorAction SilentlyContinue
if ($wsaRunning) {
    Write-Host "WSA is currently running. Please close all Android apps and WSA settings." -ForegroundColor Yellow
    $confirm = Read-Host "Press Y when ready to continue, or N to cancel"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        exit
    }
}

# Backup current data if exists
$currentUserData = Join-Path $wsaDataPath "userdata.vhdx"
if (Test-Path $currentUserData) {
    $backupName = "userdata_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').vhdx"
    $backupPath = Join-Path (Split-Path $BackupFile -Parent) $backupName
    
    Write-Host "Backing up current user data to: $backupPath" -ForegroundColor Yellow
    Copy-Item -Path $currentUserData -Destination $backupPath -Force
}

# Restore user data
try {
    Write-Host "Restoring user data from backup..." -ForegroundColor Cyan
    Copy-Item -Path $BackupFile -Destination $currentUserData -Force
    Write-Host "User data restored successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Please restart WSA to load the restored data." -ForegroundColor Yellow
}
catch {
    Write-Host "Error restoring user data: $_" -ForegroundColor Red
    exit 1
}