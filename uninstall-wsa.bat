@echo off
:: Windows Subsystem for Android (WSA) Uninstaller Batch Wrapper
:: This batch file launches the PowerShell uninstaller script

echo Windows Subsystem for Android (WSA) Uninstaller
echo ================================================
echo.

:: Check for backup flag
set BACKUP_FLAG=
if "%1"=="-backup" set BACKUP_FLAG=-BackupData
if "%1"=="/backup" set BACKUP_FLAG=-BackupData

:: Launch PowerShell script with appropriate parameters
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall-wsa.ps1" %BACKUP_FLAG%

pause