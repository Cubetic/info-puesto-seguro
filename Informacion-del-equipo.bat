@echo off
@REM ——— Elevación automática ———
net session >nul 2>&1 || (
  echo Solicitando privilegios de administrador...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

@REM ——— Ejecutar el PowerShell sin que se muestre la línea de invocación ———
@powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0config/Get-PCInfo.ps1"

pause
