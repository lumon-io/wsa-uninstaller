# WSAway Core Functions
# Shared functionality for both CLI and GUI versions

# Get script directory
$script:ScriptDirectory = Split-Path -Parent $PSCommandPath
$script:ScriptParentDirectory = Split-Path -Parent $script:ScriptDirectory

# WSA Package information
$script:WSAPackageName = "MicrosoftCorporationII.WindowsSubsystemForAndroid"
$script:WSAFolderName = "MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe"
$script:LocalPackagesPath = "$env:LOCALAPPDATA\Packages\$script:WSAFolderName"

# Common WSA installation locations
$script:CommonWSAPaths = @(
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

# Function to check if a folder is safe to delete
function Test-SafeToDelete {
    param($FolderPath)
    
    # Normalize paths for comparison
    $normalizedFolder = $FolderPath.TrimEnd('\').ToLower()
    $normalizedScript = $script:ScriptDirectory.TrimEnd('\').ToLower()
    $normalizedParent = $script:ScriptParentDirectory.TrimEnd('\').ToLower()
    
    # Check if the folder is the script directory or its parent
    if ($normalizedFolder -eq $normalizedScript -or $normalizedFolder -eq $normalizedParent) {
        return $false
    }
    
    # Check if the folder contains WSAway files
    $wsawayFiles = @("WSAway*.ps1", "WSAway*.bat", "uninstall-wsa.ps1", "uninstall-wsa.bat")
    foreach ($pattern in $wsawayFiles) {
        if (Get-ChildItem -Path $FolderPath -Filter $pattern -ErrorAction SilentlyContinue) {
            return $false
        }
    }
    
    return $true
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

# Function to stop WSA processes
function Stop-WSAProcesses {
    Write-Log "Stopping WSA processes..."
    
    $wsaProcesses = @("WsaClient", "WsaService", "WsaSettings", "wsaclient", "wsaservice", "wsasettings", "vmmemWSA", "WSA")
    $stopped = $false
    
    foreach ($process in $wsaProcesses) {
        $procs = Get-Process -Name $process -ErrorAction SilentlyContinue
        if ($procs) {
            foreach ($proc in $procs) {
                try {
                    $proc | Stop-Process -Force -ErrorAction Stop
                    Write-Log "Stopped process: $($proc.Name) (PID: $($proc.Id))"
                    $stopped = $true
                }
                catch {
                    Write-Log "Failed to stop process: $($proc.Name) - $_" -Type "ERROR"
                }
            }
        }
    }
    
    if ($stopped) {
        Start-Sleep -Seconds 3
    }
    
    return -not (Test-WSARunning)
}

# Function to create system restore point
function New-SystemRestorePoint {
    param([string]$Description = "WSAway - Before WSA Removal")
    
    if ($script:DryRun) {
        Write-Log "[DRY RUN] Would create system restore point: $Description"
        return $true
    }
    
    try {
        Write-Log "Creating system restore point..."
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Log "System restore point created successfully"
        return $true
    }
    catch {
        Write-Log "Failed to create restore point: $_" -Type "ERROR"
        return $false
    }
}

# Function to backup user data
function Backup-WSAUserData {
    param([string]$BackupPath = "$env:USERPROFILE\Desktop\WSA_Backup")
    
    $userDataPath = "$script:LocalPackagesPath\LocalCache\userdata.vhdx"
    
    if (-not (Test-Path $userDataPath)) {
        Write-Log "No user data found to backup"
        return $true
    }
    
    if ($script:DryRun) {
        Write-Log "[DRY RUN] Would backup user data from: $userDataPath"
        return $true
    }
    
    try {
        Write-Log "Backing up user data..."
        
        if (-not (Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        }
        
        $backupFileName = "WSA_userdata_$(Get-Date -Format 'yyyyMMdd_HHmmss').vhdx"
        $backupFullPath = Join-Path $BackupPath $backupFileName
        
        Copy-Item -Path $userDataPath -Destination $backupFullPath -Force
        Write-Log "User data backed up to: $backupFullPath"
        
        # Also backup app list
        $appListPath = Join-Path $BackupPath "WSA_AppList_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        if ($script:WSAPackage) {
            Get-AppxPackage | Where-Object { $_.PackageFamilyName -like "*WSA*" } | 
                Format-List | Out-File -FilePath $appListPath
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to backup user data: $_" -Type "ERROR"
        return $false
    }
}

# Function to find WSA folders
function Find-WSAFolders {
    param(
        [switch]$DeepScan,
        [switch]$IncludePackageFolder,
        [string[]]$CustomPaths = @()
    )
    
    $foundPaths = @()
    
    # Add package folder if requested
    if ($IncludePackageFolder -and (Test-Path $script:LocalPackagesPath)) {
        $foundPaths += $script:LocalPackagesPath
    }
    
    # Check common paths
    $allPaths = $script:CommonWSAPaths + $CustomPaths
    foreach ($path in $allPaths) {
        if ($path.Contains("*")) {
            $resolved = Get-Item -Path $path -ErrorAction SilentlyContinue
            if ($resolved) {
                foreach ($item in $resolved) {
                    if ((Test-Path $item.FullName) -and (Test-SafeToDelete $item.FullName)) {
                        $foundPaths += $item.FullName
                    }
                }
            }
        }
        elseif ((Test-Path $path) -and (Test-SafeToDelete $path)) {
            $foundPaths += $path
        }
    }
    
    # Deep scan if requested
    if ($DeepScan) {
        Write-Log "Performing deep scan for WSA folders..."
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null }
        
        foreach ($drive in $drives) {
            Write-Log "Scanning drive $($drive.Name):\"
            
            try {
                $wsaFolders = Get-ChildItem -Path "$($drive.Name):\" -Directory -Recurse -ErrorAction SilentlyContinue |
                    Where-Object { 
                        ($_.Name -like "*WSA*" -or $_.Name -like "*WindowsSubsystemForAndroid*") -and
                        (Test-Path (Join-Path $_.FullName "Install.ps1") -or
                         Test-Path (Join-Path $_.FullName "Run.bat") -or
                         Test-Path (Join-Path $_.FullName "WsaClient.exe") -or
                         Test-Path (Join-Path $_.FullName "kernel") -or
                         (Get-ChildItem -Path $_.FullName -Filter "*.msix" -ErrorAction SilentlyContinue).Count -gt 0)
                    }
                
                foreach ($folder in $wsaFolders) {
                    if (Test-SafeToDelete $folder.FullName) {
                        $foundPaths += $folder.FullName
                    }
                }
            }
            catch {
                Write-Log "Error scanning drive $($drive.Name): $_" -Type "ERROR"
            }
        }
    }
    
    return $foundPaths | Select-Object -Unique
}

# Function to clean firewall rules
function Remove-WSAFirewallRules {
    if ($script:DryRun) {
        Write-Log "[DRY RUN] Would remove WSA firewall rules"
        return
    }
    
    Write-Log "Removing WSA firewall rules..."
    
    try {
        $rules = Get-NetFirewallRule -ErrorAction SilentlyContinue | 
            Where-Object { $_.DisplayName -like "*WSA*" -or $_.DisplayName -like "*Android*" }
        
        foreach ($rule in $rules) {
            Remove-NetFirewallRule -Name $rule.Name -ErrorAction SilentlyContinue
            Write-Log "Removed firewall rule: $($rule.DisplayName)"
        }
    }
    catch {
        Write-Log "Error removing firewall rules: $_" -Type "ERROR"
    }
}

# Function to clean startup entries
function Remove-WSAStartupEntries {
    if ($script:DryRun) {
        Write-Log "[DRY RUN] Would remove WSA startup entries"
        return
    }
    
    Write-Log "Removing WSA startup entries..."
    
    # Check Task Scheduler
    try {
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | 
            Where-Object { $_.TaskName -like "*WSA*" -or $_.TaskName -like "*Android*" }
        
        foreach ($task in $tasks) {
            Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false -ErrorAction SilentlyContinue
            Write-Log "Removed scheduled task: $($task.TaskName)"
        }
    }
    catch {
        Write-Log "Error removing scheduled tasks: $_" -Type "ERROR"
    }
    
    # Check Registry Run keys
    $runKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    )
    
    foreach ($key in $runKeys) {
        try {
            $values = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
            $values.PSObject.Properties | Where-Object { 
                $_.Value -like "*WSA*" -or $_.Value -like "*WindowsSubsystemForAndroid*" 
            } | ForEach-Object {
                Remove-ItemProperty -Path $key -Name $_.Name -ErrorAction SilentlyContinue
                Write-Log "Removed startup entry: $($_.Name)"
            }
        }
        catch {
            Write-Log "Error checking registry key $key : $_" -Type "ERROR"
        }
    }
}

# Function to clean Hyper-V settings
function Remove-WSAHyperVSettings {
    if ($script:DryRun) {
        Write-Log "[DRY RUN] Would remove WSA Hyper-V settings"
        return
    }
    
    Write-Log "Cleaning WSA Hyper-V settings..."
    
    try {
        # Remove WSA virtual switches
        $switches = Get-VMSwitch -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -like "*WSA*" }
        
        foreach ($switch in $switches) {
            Remove-VMSwitch -Name $switch.Name -Force -ErrorAction SilentlyContinue
            Write-Log "Removed virtual switch: $($switch.Name)"
        }
        
        # Remove WSA NAT configurations
        $nats = Get-NetNat -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -like "*WSA*" }
        
        foreach ($nat in $nats) {
            Remove-NetNat -Name $nat.Name -Confirm:$false -ErrorAction SilentlyContinue
            Write-Log "Removed NAT configuration: $($nat.Name)"
        }
    }
    catch {
        Write-Log "Error cleaning Hyper-V settings: $_" -Type "ERROR"
    }
}

# Function to clean environment variables
function Remove-WSAEnvironmentVariables {
    if ($script:DryRun) {
        Write-Log "[DRY RUN] Would remove WSA environment variables"
        return
    }
    
    Write-Log "Cleaning WSA environment variables..."
    
    try {
        # Check PATH variable
        $path = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        $newPath = ($path -split ';' | Where-Object { $_ -notlike "*WSA*" -and $_ -notlike "*WindowsSubsystemForAndroid*" }) -join ';'
        
        if ($path -ne $newPath) {
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
            Write-Log "Cleaned PATH environment variable"
        }
        
        # Check user PATH
        $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        $newUserPath = ($userPath -split ';' | Where-Object { $_ -notlike "*WSA*" -and $_ -notlike "*WindowsSubsystemForAndroid*" }) -join ';'
        
        if ($userPath -ne $newUserPath) {
            [Environment]::SetEnvironmentVariable("PATH", $newUserPath, "User")
            Write-Log "Cleaned user PATH environment variable"
        }
    }
    catch {
        Write-Log "Error cleaning environment variables: $_" -Type "ERROR"
    }
}

# Function to clean registry
function Remove-WSARegistryEntries {
    if ($script:DryRun) {
        Write-Log "[DRY RUN] Would remove WSA registry entries"
        return
    }
    
    Write-Log "Cleaning WSA registry entries..."
    
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*WSA*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*WSA*",
        "HKLM:\SOFTWARE\Classes\*WSA*",
        "HKCU:\SOFTWARE\Classes\*WSA*"
    )
    
    foreach ($regPath in $regPaths) {
        try {
            Get-Item -Path $regPath -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Log "Error removing registry path $regPath : $_" -Type "ERROR"
        }
    }
}

# Main removal function
function Remove-WSAComplete {
    param(
        [string[]]$SelectedFolders = @()
    )
    
    Write-Log "Starting WSA complete removal process..."
    Update-Progress -Value 0 -Status "Initializing..."
    
    # Create restore point if requested
    if ($restorePointCheckbox.Checked) {
        Update-Progress -Value 10 -Status "Creating restore point..."
        New-SystemRestorePoint
    }
    
    # Backup user data if requested
    if ($backupCheckbox.Checked) {
        Update-Progress -Value 20 -Status "Backing up user data..."
        Backup-WSAUserData -BackupPath $script:BackupPath
    }
    
    # Stop WSA processes
    Update-Progress -Value 30 -Status "Stopping WSA processes..."
    if (Test-WSARunning) {
        if (-not (Stop-WSAProcesses)) {
            Write-Log "Failed to stop all WSA processes. Please close Android apps manually." -Type "ERROR"
            return
        }
    }
    
    # Uninstall WSA package
    if ($script:WSAPackage) {
        Update-Progress -Value 40 -Status "Uninstalling WSA package..."
        
        if ($script:DryRun) {
            Write-Log "[DRY RUN] Would uninstall WSA package: $($script:WSAPackage.PackageFullName)"
        }
        else {
            try {
                Remove-AppxPackage -Package $script:WSAPackage.PackageFullName -ErrorAction Stop
                Write-Log "WSA package uninstalled successfully"
            }
            catch {
                Write-Log "Failed to uninstall WSA package: $_" -Type "ERROR"
            }
        }
    }
    
    # Clean folders
    if ($SelectedFolders.Count -gt 0) {
        Update-Progress -Value 50 -Status "Removing WSA folders..."
        
        foreach ($folder in $SelectedFolders) {
            if (Test-Path $folder) {
                if (-not (Test-SafeToDelete $folder)) {
                    Write-Log "Skipping protected folder: $folder" -Type "WARNING"
                    continue
                }
                
                if ($script:DryRun) {
                    Write-Log "[DRY RUN] Would remove folder: $folder"
                }
                else {
                    try {
                        Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
                        Write-Log "Removed folder: $folder"
                    }
                    catch {
                        Write-Log "Failed to remove folder $folder : $_" -Type "ERROR"
                    }
                }
            }
        }
    }
    
    # Clean firewall rules
    if ($firewallCheckbox.Checked) {
        Update-Progress -Value 60 -Status "Cleaning firewall rules..."
        Remove-WSAFirewallRules
    }
    
    # Clean startup entries
    if ($startupCheckbox.Checked) {
        Update-Progress -Value 70 -Status "Cleaning startup entries..."
        Remove-WSAStartupEntries
    }
    
    # Clean Hyper-V settings
    if ($hyperVCheckbox.Checked) {
        Update-Progress -Value 80 -Status "Cleaning Hyper-V settings..."
        Remove-WSAHyperVSettings
    }
    
    # Clean environment variables
    Update-Progress -Value 85 -Status "Cleaning environment variables..."
    Remove-WSAEnvironmentVariables
    
    # Clean registry
    Update-Progress -Value 90 -Status "Cleaning registry entries..."
    Remove-WSARegistryEntries
    
    Update-Progress -Value 100 -Status "Removal complete"
    
    if ($script:DryRun) {
        Write-Log "DRY RUN COMPLETE - No actual changes were made"
        [System.Windows.Forms.MessageBox]::Show(
            "Dry run complete. No actual changes were made. Check the logs for details.",
            "Dry Run Complete",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    else {
        Write-Log "WSA removal complete!"
        [System.Windows.Forms.MessageBox]::Show(
            "WSA has been removed successfully. Check the logs for details.",
            "Removal Complete",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    
    # Refresh status
    Check-WSAStatus
}