@echo off
setlocal
cd /d "%~dp0"
where powershell.exe >nul 2>&1 || (echo Windows PowerShell 5.1 is required.& pause & exit /b 1)
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0BenCore.ps1"
if errorlevel 1 (
  echo.
  echo BenCore encountered an error. See %%LOCALAPPDATA%%\BenCore\Logs if available.
  pause
)
endlocal
