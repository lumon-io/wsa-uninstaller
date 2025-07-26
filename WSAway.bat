@echo off
:: WSAway - Windows Subsystem for Android Complete Removal Tool
:: Batch launcher for CLI version

echo WSAway - Windows Subsystem for Android Complete Removal Tool
echo ============================================================
echo.

:: Parse command line arguments
set PARAMS=
:parse
if "%~1"=="" goto endparse
set PARAMS=%PARAMS% %1
shift
goto parse
:endparse

:: Launch PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0WSAway.ps1" %PARAMS%

pause