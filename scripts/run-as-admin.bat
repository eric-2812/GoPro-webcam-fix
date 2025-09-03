@echo off
:: run-as-admin.bat - Launches the PowerShell fix with admin privileges
set SCRIPT=%~dp0fix-gopro-webcam.ps1

:: Check admin
whoami /groups | find "S-1-5-32-544" >nul
if %errorlevel% neq 0 (
  echo [i] Restarting as Administrator...
  powershell -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File ""%SCRIPT%""'"
  exit /b
) else (
  powershell -ExecutionPolicy Bypass -File "%SCRIPT%"
)
