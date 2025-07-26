@echo off
:: WSAway GUI Launcher
:: Launches the graphical interface

echo Launching WSAway GUI...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0WSAway-GUI.ps1"