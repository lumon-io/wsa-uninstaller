# WSAway - Windows Subsystem for Android Complete Removal Tool
# GUI Version for easy use

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Set high DPI awareness
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class User32 {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
"@
[User32]::SetProcessDPIAware()

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    $result = [System.Windows.Forms.MessageBox]::Show(
        "WSAway requires Administrator privileges to run properly. Would you like to restart as Administrator?", 
        "Administrator Required", 
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    }
    exit
}

# Global variables
$script:LogPath = "$env:USERPROFILE\Desktop\WSAway_Logs"
$script:BackupPath = "$env:USERPROFILE\Desktop\WSA_Backup"
$script:DryRun = $false
$script:FoundFolders = @()
$script:WSAPackage = $null

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "WSAway - WSA Complete Removal Tool"
$form.Size = New-Object System.Drawing.Size(800,700)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Icon = [System.Drawing.SystemIcons]::Application

# Create TabControl
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Size = New-Object System.Drawing.Size(780,620)
$tabControl.Location = New-Object System.Drawing.Point(10,10)

# Main Tab
$mainTab = New-Object System.Windows.Forms.TabPage
$mainTab.Text = "Main"
$mainTab.BackColor = [System.Drawing.Color]::White

# Status GroupBox
$statusGroup = New-Object System.Windows.Forms.GroupBox
$statusGroup.Text = "WSA Status"
$statusGroup.Size = New-Object System.Drawing.Size(750,100)
$statusGroup.Location = New-Object System.Drawing.Point(10,10)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Size = New-Object System.Drawing.Size(730,80)
$statusLabel.Location = New-Object System.Drawing.Point(10,20)
$statusLabel.Text = "Checking WSA installation status..."
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$statusGroup.Controls.Add($statusLabel)

# Options GroupBox
$optionsGroup = New-Object System.Windows.Forms.GroupBox
$optionsGroup.Text = "Removal Options"
$optionsGroup.Size = New-Object System.Drawing.Size(750,200)
$optionsGroup.Location = New-Object System.Drawing.Point(10,120)

$backupCheckbox = New-Object System.Windows.Forms.CheckBox
$backupCheckbox.Text = "Backup user data before removal"
$backupCheckbox.Size = New-Object System.Drawing.Size(300,30)
$backupCheckbox.Location = New-Object System.Drawing.Point(20,30)
$backupCheckbox.Checked = $true

$restorePointCheckbox = New-Object System.Windows.Forms.CheckBox
$restorePointCheckbox.Text = "Create System Restore Point"
$restorePointCheckbox.Size = New-Object System.Drawing.Size(300,30)
$restorePointCheckbox.Location = New-Object System.Drawing.Point(20,60)
$restorePointCheckbox.Checked = $true

$deepScanCheckbox = New-Object System.Windows.Forms.CheckBox
$deepScanCheckbox.Text = "Deep scan all drives for WSA folders"
$deepScanCheckbox.Size = New-Object System.Drawing.Size(300,30)
$deepScanCheckbox.Location = New-Object System.Drawing.Point(20,90)

$dryRunCheckbox = New-Object System.Windows.Forms.CheckBox
$dryRunCheckbox.Text = "Dry Run (preview only, don't delete)"
$dryRunCheckbox.Size = New-Object System.Drawing.Size(300,30)
$dryRunCheckbox.Location = New-Object System.Drawing.Point(20,120)

$loggingCheckbox = New-Object System.Windows.Forms.CheckBox
$loggingCheckbox.Text = "Enable detailed logging"
$loggingCheckbox.Size = New-Object System.Drawing.Size(300,30)
$loggingCheckbox.Location = New-Object System.Drawing.Point(400,30)
$loggingCheckbox.Checked = $true

$firewallCheckbox = New-Object System.Windows.Forms.CheckBox
$firewallCheckbox.Text = "Clean firewall rules"
$firewallCheckbox.Size = New-Object System.Drawing.Size(300,30)
$firewallCheckbox.Location = New-Object System.Drawing.Point(400,60)
$firewallCheckbox.Checked = $true

$startupCheckbox = New-Object System.Windows.Forms.CheckBox
$startupCheckbox.Text = "Clean startup entries"
$startupCheckbox.Size = New-Object System.Drawing.Size(300,30)
$startupCheckbox.Location = New-Object System.Drawing.Point(400,90)
$startupCheckbox.Checked = $true

$hyperVCheckbox = New-Object System.Windows.Forms.CheckBox
$hyperVCheckbox.Text = "Clean Hyper-V settings"
$hyperVCheckbox.Size = New-Object System.Drawing.Size(300,30)
$hyperVCheckbox.Location = New-Object System.Drawing.Point(400,120)
$hyperVCheckbox.Checked = $true

$optionsGroup.Controls.AddRange(@(
    $backupCheckbox, $restorePointCheckbox, $deepScanCheckbox, $dryRunCheckbox,
    $loggingCheckbox, $firewallCheckbox, $startupCheckbox, $hyperVCheckbox
))

# Action Buttons
$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = "Scan for WSA"
$scanButton.Size = New-Object System.Drawing.Size(150,40)
$scanButton.Location = New-Object System.Drawing.Point(10,330)
$scanButton.BackColor = [System.Drawing.Color]::LightBlue
$scanButton.FlatStyle = "Flat"

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Text = "Remove WSA"
$removeButton.Size = New-Object System.Drawing.Size(150,40)
$removeButton.Location = New-Object System.Drawing.Point(170,330)
$removeButton.BackColor = [System.Drawing.Color]::IndianRed
$removeButton.ForeColor = [System.Drawing.Color]::White
$removeButton.FlatStyle = "Flat"
$removeButton.Enabled = $false

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(750,30)
$progressBar.Location = New-Object System.Drawing.Point(10,380)
$progressBar.Style = "Continuous"

# Output TextBox
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Size = New-Object System.Drawing.Size(750,150)
$outputBox.Location = New-Object System.Drawing.Point(10,420)
$outputBox.ReadOnly = $true
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$outputBox.BackColor = [System.Drawing.Color]::Black
$outputBox.ForeColor = [System.Drawing.Color]::LightGreen

$mainTab.Controls.AddRange(@(
    $statusGroup, $optionsGroup, $scanButton, $removeButton, $progressBar, $outputBox
))

# Folders Tab
$foldersTab = New-Object System.Windows.Forms.TabPage
$foldersTab.Text = "Found Folders"
$foldersTab.BackColor = [System.Drawing.Color]::White

$foldersListBox = New-Object System.Windows.Forms.CheckedListBox
$foldersListBox.Size = New-Object System.Drawing.Size(750,500)
$foldersListBox.Location = New-Object System.Drawing.Point(10,10)
$foldersListBox.CheckOnClick = $true
$foldersListBox.Font = New-Object System.Drawing.Font("Consolas", 9)

$selectAllButton = New-Object System.Windows.Forms.Button
$selectAllButton.Text = "Select All"
$selectAllButton.Size = New-Object System.Drawing.Size(100,30)
$selectAllButton.Location = New-Object System.Drawing.Point(10,520)

$selectNoneButton = New-Object System.Windows.Forms.Button
$selectNoneButton.Text = "Select None"
$selectNoneButton.Size = New-Object System.Drawing.Size(100,30)
$selectNoneButton.Location = New-Object System.Drawing.Point(120,520)

$foldersTab.Controls.AddRange(@($foldersListBox, $selectAllButton, $selectNoneButton))

# Logs Tab
$logsTab = New-Object System.Windows.Forms.TabPage
$logsTab.Text = "Logs"
$logsTab.BackColor = [System.Drawing.Color]::White

$logTextBox = New-Object System.Windows.Forms.TextBox
$logTextBox.Multiline = $true
$logTextBox.ScrollBars = "Both"
$logTextBox.Size = New-Object System.Drawing.Size(750,520)
$logTextBox.Location = New-Object System.Drawing.Point(10,10)
$logTextBox.ReadOnly = $true
$logTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)

$saveLogButton = New-Object System.Windows.Forms.Button
$saveLogButton.Text = "Save Log"
$saveLogButton.Size = New-Object System.Drawing.Size(100,30)
$saveLogButton.Location = New-Object System.Drawing.Point(10,540)

$clearLogButton = New-Object System.Windows.Forms.Button
$clearLogButton.Text = "Clear Log"
$clearLogButton.Size = New-Object System.Drawing.Size(100,30)
$clearLogButton.Location = New-Object System.Drawing.Point(120,540)

$logsTab.Controls.AddRange(@($logTextBox, $saveLogButton, $clearLogButton))

# About Tab
$aboutTab = New-Object System.Windows.Forms.TabPage
$aboutTab.Text = "About"
$aboutTab.BackColor = [System.Drawing.Color]::White

$aboutLabel = New-Object System.Windows.Forms.Label
$aboutLabel.Size = New-Object System.Drawing.Size(750,500)
$aboutLabel.Location = New-Object System.Drawing.Point(10,10)
$aboutLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$aboutLabel.Text = @"
WSAway - Windows Subsystem for Android Complete Removal Tool
Version 3.0

A comprehensive tool for completely removing Windows Subsystem for Android (WSA) 
including all associated files, folders, and registry entries.

Features:
• Safe removal with self-protection
• System restore point creation
• User data backup and restoration
• Deep scan capabilities
• Firewall and startup cleanup
• Hyper-V settings cleanup
• Detailed logging
• Dry run mode

Created by: WSAway Team
Repository: https://github.com/lumon-io/wsaway

Based on WSABuilds uninstallation documentation.
"@

$checkUpdateButton = New-Object System.Windows.Forms.Button
$checkUpdateButton.Text = "Check for Updates"
$checkUpdateButton.Size = New-Object System.Drawing.Size(150,30)
$checkUpdateButton.Location = New-Object System.Drawing.Point(10,520)

$githubButton = New-Object System.Windows.Forms.Button
$githubButton.Text = "Visit GitHub"
$githubButton.Size = New-Object System.Drawing.Size(150,30)
$githubButton.Location = New-Object System.Drawing.Point(170,520)

$aboutTab.Controls.AddRange(@($aboutLabel, $checkUpdateButton, $githubButton))

# Add tabs to TabControl
$tabControl.TabPages.AddRange(@($mainTab, $foldersTab, $logsTab, $aboutTab))

# Status Bar
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusBarLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusBarLabel.Text = "Ready"
$statusBar.Items.Add($statusBarLabel)

# Add controls to form
$form.Controls.Add($tabControl)
$form.Controls.Add($statusBar)

# Helper Functions
function Write-Log {
    param($Message, $Type = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    
    # Update log textbox
    $logTextBox.AppendText("$logEntry`r`n")
    
    # Update output box
    $outputBox.AppendText("$Message`r`n")
    
    # Write to log file if logging enabled
    if ($loggingCheckbox.Checked) {
        if (-not (Test-Path $script:LogPath)) {
            New-Item -ItemType Directory -Path $script:LogPath -Force | Out-Null
        }
        $logFile = Join-Path $script:LogPath "WSAway_$(Get-Date -Format 'yyyyMMdd').log"
        Add-Content -Path $logFile -Value $logEntry
    }
}

function Update-Progress {
    param($Value, $Status)
    $progressBar.Value = $Value
    $statusBarLabel.Text = $Status
    [System.Windows.Forms.Application]::DoEvents()
}

function Check-WSAStatus {
    Write-Log "Checking WSA installation status..."
    
    $script:WSAPackage = Get-AppxPackage -Name "MicrosoftCorporationII.WindowsSubsystemForAndroid" -ErrorAction SilentlyContinue
    
    if ($script:WSAPackage) {
        $statusLabel.Text = "WSA Status: INSTALLED`n" +
                           "Package: $($script:WSAPackage.PackageFullName)`n" +
                           "Version: $($script:WSAPackage.Version)"
        $statusLabel.ForeColor = [System.Drawing.Color]::DarkGreen
        Write-Log "WSA is installed: $($script:WSAPackage.PackageFullName)"
        $removeButton.Enabled = $true
    }
    else {
        $statusLabel.Text = "WSA Status: NOT INSTALLED`n" +
                           "No WSA package found in the system.`n" +
                           "You may still scan for leftover folders."
        $statusLabel.ForeColor = [System.Drawing.Color]::DarkRed
        Write-Log "WSA is not installed"
    }
}

# Load script functions
. "$PSScriptRoot\WSAway-Core.ps1"

# Event Handlers
$scanButton.Add_Click({
    Write-Log "Starting WSA scan..."
    $foldersListBox.Items.Clear()
    $script:FoundFolders = @()
    
    Update-Progress -Value 10 -Status "Scanning for WSA folders..."
    
    # Get scan parameters
    $scanParams = @{
        DeepScan = $deepScanCheckbox.Checked
        IncludePackageFolder = $true
    }
    
    # Find folders
    $folders = Find-WSAFolders @scanParams
    
    Update-Progress -Value 80 -Status "Processing found folders..."
    
    foreach ($folder in $folders) {
        $foldersListBox.Items.Add($folder, $true)
        $script:FoundFolders += $folder
    }
    
    Write-Log "Found $($folders.Count) WSA-related folders"
    Update-Progress -Value 100 -Status "Scan complete"
    
    if ($folders.Count -gt 0) {
        $tabControl.SelectedTab = $foldersTab
        [System.Windows.Forms.MessageBox]::Show(
            "Found $($folders.Count) WSA-related folders. Please review the folders in the 'Found Folders' tab.",
            "Scan Complete",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
})

$removeButton.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to remove WSA? This action cannot be undone (unless you have a backup or restore point).",
        "Confirm Removal",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $script:DryRun = $dryRunCheckbox.Checked
        
        # Get selected folders
        $selectedFolders = @()
        for ($i = 0; $i -lt $foldersListBox.Items.Count; $i++) {
            if ($foldersListBox.GetItemChecked($i)) {
                $selectedFolders += $foldersListBox.Items[$i]
            }
        }
        
        # Start removal process
        Remove-WSAComplete -SelectedFolders $selectedFolders
    }
})

$selectAllButton.Add_Click({
    for ($i = 0; $i -lt $foldersListBox.Items.Count; $i++) {
        $foldersListBox.SetItemChecked($i, $true)
    }
})

$selectNoneButton.Add_Click({
    for ($i = 0; $i -lt $foldersListBox.Items.Count; $i++) {
        $foldersListBox.SetItemChecked($i, $false)
    }
})

$saveLogButton.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "Log files (*.log)|*.log|Text files (*.txt)|*.txt|All files (*.*)|*.*"
    $saveDialog.FileName = "WSAway_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $logTextBox.Text | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
        Write-Log "Log saved to: $($saveDialog.FileName)"
    }
})

$clearLogButton.Add_Click({
    $logTextBox.Clear()
    $outputBox.Clear()
})

$checkUpdateButton.Add_Click({
    Write-Log "Checking for updates..."
    Start-Process "https://github.com/lumon-io/wsaway/releases"
})

$githubButton.Add_Click({
    Start-Process "https://github.com/lumon-io/wsaway"
})

# Initialize
Check-WSAStatus

# Show form
[System.Windows.Forms.Application]::Run($form)