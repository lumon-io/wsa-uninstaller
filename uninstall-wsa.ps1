# Windows Subsystem for Android (WSA) Uninstaller Script
# Automates the uninstallation process for WSABuilds and custom installations

param(
    [switch]$BackupData = $false,
    [string]$BackupPath = "$env:USERPROFILE\Desktop\WSA_Backup",
    [string[]]$CustomPaths = @(),
    [switch]$ScanForWSA = $false,
    [switch]$Interactive = $false
)

Write-Host "Windows Subsystem for Android (WSA) Uninstaller v2.0" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Restarting as Administrator..." -ForegroundColor Yellow
    $args = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($BackupData) { $args += " -BackupData" }
    if ($ScanForWSA) { $args += " -ScanForWSA" }
    if ($Interactive) { $args += " -Interactive" }
    if ($CustomPaths.Count -gt 0) { $args += " -CustomPaths " + ($CustomPaths -join ',') }
    Start-Process powershell.exe $args -Verb RunAs
    exit
}

$wsaPackageName = "MicrosoftCorporationII.WindowsSubsystemForAndroid"
$wsaFolderName = "MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe"
$localPackagesPath = "$env:LOCALAPPDATA\Packages\$wsaFolderName"

# Common WSA installation locations
$commonWSAPaths = @(
    "$env:ProgramFiles\WSA",
    "$env:ProgramFiles\WindowsSubsystemForAndroid",
    "$env:ProgramFiles (x86)\WSA",
    "$env:ProgramFiles (x86)\WindowsSubsystemForAndroid",
    "$env:USERPROFILE\WSA",
    "$env:USERPROFILE\Downloads\WSA*",
    "$env:USERPROFILE\Desktop\WSA*",
    "C:\WSA",
    "D:\WSA",
    "E:\WSA"
)

# Add custom paths if provided
if ($CustomPaths.Count -gt 0) {
    $commonWSAPaths += $CustomPaths
}

# Function to check if WSA is running
function Test-WSARunning {
    $wsaProcesses = @("WsaClient", "WsaService", "WsaSettings", "wsaclient", "wsaservice", "wsasettings", "vmmemWSA", "WSA")
    foreach ($process in $wsaProcesses) {
        if (Get-Process -Name $process -ErrorAction SilentlyContinue) {
            return $true
        }
    }
    return $false
}

# Function to scan for WSA folders
function Find-WSAFolders {
    Write-Host "`nScanning for WSA installation folders..." -ForegroundColor Yellow
    $foundPaths = @()
    
    # Check common paths
    foreach ($path in $commonWSAPaths) {
        if ($path.Contains("*")) {
            $resolved = Get-Item -Path $path -ErrorAction SilentlyContinue
            if ($resolved) {
                $foundPaths += $resolved.FullName
            }
        }
        elseif (Test-Path $path) {
            $foundPaths += $path
        }
    }
    
    # Scan drives for WSA folders if requested
    if ($ScanForWSA) {
        Write-Host "Performing deep scan for WSA folders (this may take a while)..." -ForegroundColor Yellow
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null }
        
        foreach ($drive in $drives) {
            Write-Host "Scanning drive $($drive.Name):\" -ForegroundColor Gray
            $wsaFolders = Get-ChildItem -Path "$($drive.Name):\" -Directory -Recurse -ErrorAction SilentlyContinue |
                         Where-Object { $_.Name -like "*WSA*" -or $_.Name -like "*WindowsSubsystemForAndroid*" } |
                         Where-Object { 
                             Test-Path (Join-Path $_.FullName "Install.ps1") -or
                             Test-Path (Join-Path $_.FullName "Run.bat") -or
                             Test-Path (Join-Path $_.FullName "WsaClient.exe") -or
                             Test-Path (Join-Path $_.FullName "kernel") -or
                             (Get-ChildItem -Path $_.FullName -Filter "*.msix" -ErrorAction SilentlyContinue).Count -gt 0
                         }
            
            if ($wsaFolders) {
                $foundPaths += $wsaFolders.FullName
            }
        }
    }
    
    return $foundPaths | Select-Object -Unique
}

# Function to display found folders and let user select
function Select-WSAFolders {
    param($folders)
    
    if ($folders.Count -eq 0) {
        return @()
    }
    
    Write-Host "`nFound the following potential WSA folders:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $folders.Count; $i++) {
        Write-Host "  [$($i + 1)] $($folders[$i])" -ForegroundColor White
    }
    Write-Host "  [A] Select all folders" -ForegroundColor Yellow
    Write-Host "  [N] None (skip folder cleanup)" -ForegroundColor Yellow
    
    $selection = Read-Host "`nSelect folders to remove (comma-separated numbers, 'A' for all, or 'N' for none)"
    
    if ($selection -eq 'N' -or $selection -eq 'n') {
        return @()
    }
    elseif ($selection -eq 'A' -or $selection -eq 'a') {
        return $folders
    }
    else {
        $selected = @()
        $indices = $selection -split ',' | ForEach-Object { $_.Trim() }
        foreach ($index in $indices) {
            if ($index -match '^\d+$') {
                $num = [int]$index - 1
                if ($num -ge 0 -and $num -lt $folders.Count) {
                    $selected += $folders[$num]
                }
            }
        }
        return $selected
    }
}

# Step 1: Check if WSA is installed
Write-Host "`nChecking if WSA is installed..." -ForegroundColor Yellow
$wsaPackage = Get-AppxPackage -Name $wsaPackageName -ErrorAction SilentlyContinue

if (-not $wsaPackage) {
    Write-Host "Windows Subsystem for Android package is not installed." -ForegroundColor Green
    
    # Check for leftover folders
    if (Test-Path $localPackagesPath) {
        Write-Host "Found leftover WSA data folder. Cleaning up..." -ForegroundColor Yellow
        Remove-Item -Path $localPackagesPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Leftover folder removed." -ForegroundColor Green
    }
}
else {
    Write-Host "WSA is installed. Package: $($wsaPackage.PackageFullName)" -ForegroundColor Cyan
}

# Step 2: Find WSA installation folders
$wsaFolders = Find-WSAFolders

if ($Interactive -and $wsaFolders.Count -gt 0) {
    $selectedFolders = Select-WSAFolders -folders $wsaFolders
}
else {
    $selectedFolders = $wsaFolders
}

# Step 3: Check if WSA is running
Write-Host "`nChecking if WSA is running..." -ForegroundColor Yellow
if (Test-WSARunning) {
    Write-Host "WSA is currently running. Attempting to stop it..." -ForegroundColor Yellow
    
    # Try to stop WSA processes
    $wsaProcesses = @("WsaClient", "WsaService", "WsaSettings", "wsaclient", "wsaservice", "wsasettings", "vmmemWSA", "WSA")
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

# Step 4: Backup user data if requested
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

# Step 5: Uninstall WSA package if installed
if ($wsaPackage) {
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
}

# Step 6: Clean up leftover folders
Write-Host "`nCleaning up folders..." -ForegroundColor Yellow

# Clean up package data folder
if (Test-Path $localPackagesPath) {
    try {
        Remove-Item -Path $localPackagesPath -Recurse -Force -ErrorAction Stop
        Write-Host "WSA data folder removed: $localPackagesPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to remove WSA data folder. You may need to delete it manually: $localPackagesPath" -ForegroundColor Yellow
        Write-Host "Error: $_" -ForegroundColor Yellow
    }
}

# Clean up installation folders
if ($selectedFolders.Count -gt 0) {
    Write-Host "`nRemoving WSA installation folders..." -ForegroundColor Yellow
    foreach ($folder in $selectedFolders) {
        if (Test-Path $folder) {
            try {
                Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
                Write-Host "Removed: $folder" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to remove: $folder" -ForegroundColor Yellow
                Write-Host "Error: $_" -ForegroundColor Yellow
            }
        }
    }
}
elseif ($wsaFolders.Count -gt 0 -and -not $Interactive) {
    Write-Host "`nFound WSA installation folders but not removing them (use -Interactive to select):" -ForegroundColor Yellow
    foreach ($folder in $wsaFolders) {
        Write-Host "  - $folder" -ForegroundColor Gray
    }
}

# Step 7: Clean registry entries (optional)
Write-Host "`nCleaning registry entries..." -ForegroundColor Yellow
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*WSA*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*WSA*",
    "HKLM:\SOFTWARE\Classes\*WSA*",
    "HKCU:\SOFTWARE\Classes\*WSA*"
)

foreach ($regPath in $regPaths) {
    Get-Item -Path $regPath -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`nWSA uninstallation completed!" -ForegroundColor Green

if ($BackupData -and (Test-Path $BackupPath)) {
    Write-Host "`nYour user data has been backed up to: $BackupPath" -ForegroundColor Cyan
    Write-Host "You can restore this data if you reinstall WSA in the future." -ForegroundColor Cyan
}

if (-not $ScanForWSA -and -not ($selectedFolders.Count -gt 0)) {
    Write-Host "`nTip: Run with -ScanForWSA parameter to perform a deep scan for WSA folders" -ForegroundColor Yellow
    Write-Host "     or use -Interactive to manually select folders to remove" -ForegroundColor Yellow
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")