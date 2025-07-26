# Windows Subsystem for Android (WSA) Uninstaller Script
# Automates the uninstallation process for WSABuilds

param(
    [switch]$BackupData = $false,
    [string]$BackupPath = "$env:USERPROFILE\Desktop\WSA_Backup"
)

Write-Host "Windows Subsystem for Android (WSA) Uninstaller" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Restarting as Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $($MyInvocation.UnboundArguments)" -Verb RunAs
    exit
}

$wsaPackageName = "MicrosoftCorporationII.WindowsSubsystemForAndroid"
$wsaFolderName = "MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe"
$localPackagesPath = "$env:LOCALAPPDATA\Packages\$wsaFolderName"

# Function to check if WSA is running
function Test-WSARunning {
    $wsaProcesses = @("WsaClient", "WsaService", "WsaSettings", "wsaclient", "wsaservice", "wsasettings")
    foreach ($process in $wsaProcesses) {
        if (Get-Process -Name $process -ErrorAction SilentlyContinue) {
            return $true
        }
    }
    return $false
}

# Step 1: Check if WSA is installed
Write-Host "`nChecking if WSA is installed..." -ForegroundColor Yellow
$wsaPackage = Get-AppxPackage -Name $wsaPackageName -ErrorAction SilentlyContinue

if (-not $wsaPackage) {
    Write-Host "Windows Subsystem for Android is not installed." -ForegroundColor Green
    
    # Check for leftover folders
    if (Test-Path $localPackagesPath) {
        Write-Host "Found leftover WSA folder. Cleaning up..." -ForegroundColor Yellow
        Remove-Item -Path $localPackagesPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Leftover folder removed." -ForegroundColor Green
    }
    
    exit 0
}

Write-Host "WSA is installed. Package: $($wsaPackage.PackageFullName)" -ForegroundColor Cyan

# Step 2: Check if WSA is running
Write-Host "`nChecking if WSA is running..." -ForegroundColor Yellow
if (Test-WSARunning) {
    Write-Host "WSA is currently running. Attempting to stop it..." -ForegroundColor Yellow
    
    # Try to stop WSA processes
    $wsaProcesses = @("WsaClient", "WsaService", "WsaSettings", "wsaclient", "wsaservice", "wsasettings")
    foreach ($process in $wsaProcesses) {
        Get-Process -Name $process -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    
    Start-Sleep -Seconds 3
    
    if (Test-WSARunning) {
        Write-Host "Failed to stop WSA. Please close all Android apps and WSA settings manually, then run this script again." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "WSA stopped successfully." -ForegroundColor Green
}

# Step 3: Backup user data if requested
if ($BackupData -and (Test-Path $localPackagesPath)) {
    $userDataPath = "$localPackagesPath\LocalCache\userdata.vhdx"
    
    if (Test-Path $userDataPath) {
        Write-Host "`nBacking up user data..." -ForegroundColor Yellow
        
        if (-not (Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        }
        
        $backupFileName = "WSA_userdata_$(Get-Date -Format 'yyyyMMdd_HHmmss').vhdx"
        $backupFullPath = Join-Path $BackupPath $backupFileName
        
        try {
            Copy-Item -Path $userDataPath -Destination $backupFullPath -Force
            Write-Host "User data backed up to: $backupFullPath" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to backup user data: $_" -ForegroundColor Red
            $continue = Read-Host "Continue with uninstallation anyway? (Y/N)"
            if ($continue -ne 'Y') {
                exit 1
            }
        }
    }
    else {
        Write-Host "No user data found to backup." -ForegroundColor Yellow
    }
}

# Step 4: Uninstall WSA
Write-Host "`nUninstalling Windows Subsystem for Android..." -ForegroundColor Yellow

try {
    Remove-AppxPackage -Package $wsaPackage.PackageFullName -ErrorAction Stop
    Write-Host "WSA uninstalled successfully." -ForegroundColor Green
}
catch {
    Write-Host "Failed to uninstall WSA: $_" -ForegroundColor Red
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    try {
        Get-AppxPackage -Name $wsaPackageName | Remove-AppxPackage -ErrorAction Stop
        Write-Host "WSA uninstalled successfully using alternative method." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to uninstall WSA. Error: $_" -ForegroundColor Red
        exit 1
    }
}

# Step 5: Clean up leftover folders
Write-Host "`nCleaning up leftover folders..." -ForegroundColor Yellow

if (Test-Path $localPackagesPath) {
    try {
        Remove-Item -Path $localPackagesPath -Recurse -Force -ErrorAction Stop
        Write-Host "Leftover WSA folder removed." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to remove leftover folder. You may need to delete it manually: $localPackagesPath" -ForegroundColor Yellow
        Write-Host "Error: $_" -ForegroundColor Yellow
    }
}

# Step 6: Prompt for WSA installation folder cleanup
Write-Host "`n" -ForegroundColor Yellow
Write-Host "IMPORTANT: If you installed WSA using WSABuild, you should also delete" -ForegroundColor Yellow
Write-Host "the folder where you originally extracted and ran the installation." -ForegroundColor Yellow
Write-Host "This script cannot determine that location automatically." -ForegroundColor Yellow

Write-Host "`nWSA uninstallation completed!" -ForegroundColor Green

if ($BackupData -and (Test-Path $BackupPath)) {
    Write-Host "`nYour user data has been backed up to: $BackupPath" -ForegroundColor Cyan
    Write-Host "You can restore this data if you reinstall WSA in the future." -ForegroundColor Cyan
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")