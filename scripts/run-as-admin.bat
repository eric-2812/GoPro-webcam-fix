@echo off
:: run-as-admin.bat - Lanza el fix con privilegios
set SCRIPT=%~dp0fix-gopro-webcam.ps1

:: Comprobar admin
whoami /groups | find "S-1-5-32-544" >nul
if %errorlevel% neq 0 (
  echo [i] Reintentando como Administrador...
  powershell -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File ""%SCRIPT%""'"
  exit /b
) else (
  powershell -ExecutionPolicy Bypass -File "%SCRIPT%"
)
