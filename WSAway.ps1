# WSAway - Windows Subsystem for Android Complete Removal Tool
# CLI Version

param(
    [switch]$BackupData = $false,
    [string]$BackupPath = "$env:USERPROFILE\Desktop\WSA_Backup",
    [string[]]$CustomPaths = @(),
    [switch]$ScanForWSA = $false,
    [switch]$Interactive = $false,
    [switch]$CreateRestorePoint = $false,
    [switch]$CleanFirewall = $false,
    [switch]$CleanStartup = $false,
    [switch]$CleanHyperV = $false,
    [switch]$DryRun = $false,
    [switch]$GUI = $false,
    [switch]$Version = $false,
    [switch]$Help = $false
)

$WSAwayVersion = "3.0"

# Show version
if ($Version) {
    Write-Host "WSAway version $WSAwayVersion"
    exit
}

# Show help
if ($Help) {
    Write-Host @"
WSAway - Windows Subsystem for Android Complete Removal Tool
Version $WSAwayVersion

Usage: WSAway.ps1 [options]

Options:
  -BackupData           Backup user data before removal
  -BackupPath <path>    Custom backup location (default: Desktop\WSA_Backup)
  -CustomPaths <paths>  Additional paths to check for WSA
  -ScanForWSA          Perform deep scan across all drives
  -Interactive         Interactive mode to select folders
  -CreateRestorePoint  Create system restore point before removal
  -CleanFirewall       Remove WSA firewall rules
  -CleanStartup        Remove WSA startup entries
  -CleanHyperV         Clean Hyper-V WSA settings
  -DryRun              Preview changes without executing
  -GUI                 Launch graphical interface
  -Version             Show version information
  -Help                Show this help message

Examples:
  .\WSAway.ps1 -GUI
  .\WSAway.ps1 -Interactive -BackupData
  .\WSAway.ps1 -ScanForWSA -DryRun
  .\WSAway.ps1 -BackupData -CreateRestorePoint -CleanFirewall -CleanStartup

Repository: https://github.com/lumon-io/wsaway
"@
    exit
}

# Launch GUI if requested
if ($GUI) {
    & "$PSScriptRoot\WSAway-GUI.ps1"
    exit
}

Write-Host "WSAway - Windows Subsystem for Android Complete Removal Tool v$WSAwayVersion" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Restarting as Administrator..." -ForegroundColor Yellow
    $args = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    
    # Preserve all parameters
    if ($BackupData) { $args += " -BackupData" }
    if ($ScanForWSA) { $args += " -ScanForWSA" }
    if ($Interactive) { $args += " -Interactive" }
    if ($CreateRestorePoint) { $args += " -CreateRestorePoint" }
    if ($CleanFirewall) { $args += " -CleanFirewall" }
    if ($CleanStartup) { $args += " -CleanStartup" }
    if ($CleanHyperV) { $args += " -CleanHyperV" }
    if ($DryRun) { $args += " -DryRun" }
    if ($CustomPaths.Count -gt 0) { $args += " -CustomPaths " + ($CustomPaths -join ',') }
    if ($BackupPath -ne "$env:USERPROFILE\Desktop\WSA_Backup") { $args += " -BackupPath `"$BackupPath`"" }
    
    Start-Process powershell.exe $args -Verb RunAs
    exit
}

# Set global dry run flag
$script:DryRun = $DryRun

# Load core functions
. "$PSScriptRoot\WSAway-Core.ps1"

# Override Write-Log for CLI
function Write-Log {
    param($Message, $Type = "INFO")
    
    $color = switch ($Type) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host "[$Type] $Message" -ForegroundColor $color
    
    # Also write to log file
    $logPath = "$env:USERPROFILE\Desktop\WSAway_Logs"
    if (-not (Test-Path $logPath)) {
        New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    }
    $logFile = Join-Path $logPath "WSAway_$(Get-Date -Format 'yyyyMMdd').log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] [$Type] $Message"
}

# Dummy Update-Progress for CLI compatibility
function Update-Progress {
    param($Value, $Status)
    Write-Host "Progress: $Status" -ForegroundColor Cyan
}

# Check WSA status
Write-Log "Checking WSA installation status..."
$script:WSAPackage = Get-AppxPackage -Name $script:WSAPackageName -ErrorAction SilentlyContinue

if ($script:WSAPackage) {
    Write-Log "WSA is installed: $($script:WSAPackage.PackageFullName)" -Type "SUCCESS"
}
else {
    Write-Log "WSA package is not installed" -Type "WARNING"
}

# Find WSA folders
Write-Log "Scanning for WSA folders..."
$foundFolders = Find-WSAFolders -DeepScan:$ScanForWSA -IncludePackageFolder:$true -CustomPaths $CustomPaths

if ($foundFolders.Count -eq 0) {
    Write-Log "No WSA folders found" -Type "WARNING"
    if (-not $script:WSAPackage) {
        Write-Log "WSA appears to be already removed or was never installed" -Type "SUCCESS"
        exit
    }
}
else {
    Write-Log "Found $($foundFolders.Count) WSA-related folders:" -Type "SUCCESS"
    foreach ($folder in $foundFolders) {
        Write-Host "  - $folder"
    }
}

# Interactive mode
$selectedFolders = $foundFolders
if ($Interactive -and $foundFolders.Count -gt 0) {
    Write-Host "`nInteractive Mode - Select folders to remove:" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $foundFolders.Count; $i++) {
        $safeStatus = if (Test-SafeToDelete $foundFolders[$i]) { "" } else { " [PROTECTED]" }
        Write-Host "  [$($i + 1)] $($foundFolders[$i])$safeStatus"
    }
    Write-Host "  [A] Select all safe folders"
    Write-Host "  [N] None (skip folder removal)"
    
    $selection = Read-Host "`nEnter your selection"
    
    if ($selection -eq 'N' -or $selection -eq 'n') {
        $selectedFolders = @()
    }
    elseif ($selection -eq 'A' -or $selection -eq 'a') {
        $selectedFolders = $foundFolders | Where-Object { Test-SafeToDelete $_ }
    }
    else {
        $selected = @()
        $indices = $selection -split ',' | ForEach-Object { $_.Trim() }
        foreach ($index in $indices) {
            if ($index -match '^\d+$') {
                $num = [int]$index - 1
                if ($num -ge 0 -and $num -lt $foundFolders.Count) {
                    if (Test-SafeToDelete $foundFolders[$num]) {
                        $selected += $foundFolders[$num]
                    }
                    else {
                        Write-Log "Skipping protected folder: $($foundFolders[$num])" -Type "WARNING"
                    }
                }
            }
        }
        $selectedFolders = $selected
    }
}

# Confirm removal
if (-not $DryRun) {
    Write-Host "`nReady to remove WSA with the following options:" -ForegroundColor Yellow
    Write-Host "  - Backup user data: $BackupData"
    Write-Host "  - Create restore point: $CreateRestorePoint"
    Write-Host "  - Clean firewall rules: $CleanFirewall"
    Write-Host "  - Clean startup entries: $CleanStartup"
    Write-Host "  - Clean Hyper-V settings: $CleanHyperV"
    Write-Host "  - Folders to remove: $($selectedFolders.Count)"
    
    $confirm = Read-Host "`nProceed with removal? (Y/N)"
    if ($confirm -ne 'Y' -and $confirm -ne 'y') {
        Write-Log "Removal cancelled by user"
        exit
    }
}

# Create restore point
if ($CreateRestorePoint) {
    New-SystemRestorePoint -Description "WSAway - Before WSA Removal"
}

# Backup user data
if ($BackupData) {
    Backup-WSAUserData -BackupPath $BackupPath
}

# Stop WSA processes
if (Test-WSARunning) {
    Write-Log "Stopping WSA processes..."
    if (-not (Stop-WSAProcesses)) {
        Write-Log "Failed to stop all WSA processes. Please close Android apps manually." -Type "ERROR"
        exit 1
    }
}

# Uninstall WSA package
if ($script:WSAPackage) {
    if ($DryRun) {
        Write-Log "[DRY RUN] Would uninstall WSA package: $($script:WSAPackage.PackageFullName)"
    }
    else {
        try {
            Write-Log "Uninstalling WSA package..."
            Remove-AppxPackage -Package $script:WSAPackage.PackageFullName -ErrorAction Stop
            Write-Log "WSA package uninstalled successfully" -Type "SUCCESS"
        }
        catch {
            Write-Log "Failed to uninstall WSA package: $_" -Type "ERROR"
        }
    }
}

# Remove folders
foreach ($folder in $selectedFolders) {
    if (Test-Path $folder) {
        if ($DryRun) {
            Write-Log "[DRY RUN] Would remove folder: $folder"
        }
        else {
            try {
                Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
                Write-Log "Removed folder: $folder" -Type "SUCCESS"
            }
            catch {
                Write-Log "Failed to remove folder $folder : $_" -Type "ERROR"
            }
        }
    }
}

# Clean firewall rules
if ($CleanFirewall) {
    Remove-WSAFirewallRules
}

# Clean startup entries
if ($CleanStartup) {
    Remove-WSAStartupEntries
}

# Clean Hyper-V settings
if ($CleanHyperV) {
    Remove-WSAHyperVSettings
}

# Always clean environment variables and registry
Remove-WSAEnvironmentVariables
Remove-WSARegistryEntries

if ($DryRun) {
    Write-Log "`nDRY RUN COMPLETE - No actual changes were made" -Type "SUCCESS"
}
else {
    Write-Log "`nWSA removal complete!" -Type "SUCCESS"
    
    if ($BackupData) {
        Write-Log "Your user data has been backed up to: $BackupPath" -Type "SUCCESS"
    }
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")