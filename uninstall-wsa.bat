@echo off
:: Windows Subsystem for Android (WSA) Uninstaller Batch Wrapper
:: This batch file launches the PowerShell uninstaller script

echo Windows Subsystem for Android (WSA) Uninstaller v2.1
echo ====================================================
echo.

:: Parse command line arguments
set PARAMS=
:parse
if "%~1"=="" goto endparse
if /i "%~1"=="-backup" set PARAMS=%PARAMS% -BackupData
if /i "%~1"=="/backup" set PARAMS=%PARAMS% -BackupData
if /i "%~1"=="-scan" set PARAMS=%PARAMS% -ScanForWSA
if /i "%~1"=="/scan" set PARAMS=%PARAMS% -ScanForWSA
if /i "%~1"=="-interactive" set PARAMS=%PARAMS% -Interactive
if /i "%~1"=="/interactive" set PARAMS=%PARAMS% -Interactive
if /i "%~1"=="-i" set PARAMS=%PARAMS% -Interactive
if /i "%~1"=="/i" set PARAMS=%PARAMS% -Interactive
if /i "%~1"=="-help" goto showhelp
if /i "%~1"=="/help" goto showhelp
if /i "%~1"=="-?" goto showhelp
if /i "%~1"=="/?" goto showhelp
shift
goto parse
:endparse

:: Launch PowerShell script with appropriate parameters
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall-wsa.ps1" %PARAMS%
goto end

:showhelp
echo Usage: uninstall-wsa.bat [options]
echo.
echo Options:
echo   -backup        : Backup user data before uninstalling
echo   -scan          : Perform deep scan for WSA folders across all drives
echo   -interactive   : Interactive mode to select which folders to remove
echo   -i             : Shorthand for -interactive
echo   -help, -?      : Show this help message
echo.
echo Examples:
echo   uninstall-wsa.bat                    : Basic uninstall
echo   uninstall-wsa.bat -backup            : Uninstall with data backup
echo   uninstall-wsa.bat -scan              : Deep scan and remove all WSA folders
echo   uninstall-wsa.bat -i                 : Interactive mode
echo   uninstall-wsa.bat -backup -scan -i   : All options combined

:end
pause