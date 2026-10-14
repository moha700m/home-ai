@echo off
setlocal EnableExtensions
title pc-local installer
cd /d "%~dp0"

echo ==> pc-local one-click install
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo ERR Git not found. Install https://git-scm.com
  pause
  exit /b 1
)
where node >nul 2>&1
if errorlevel 1 (
  echo ERR Node.js not found. Install https://nodejs.org
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
set ERR=%ERRORLEVEL%
if not "%ERR%"=="0" (
  echo.
  echo ERR install failed with code %ERR%
  pause
  exit /b %ERR%
)

echo.
echo Done. Starting playground...
cd /d "%USERPROFILE%\home-ai"
if not exist "package.json" (
  echo ERR missing %USERPROFILE%\home-ai
  pause
  exit /b 1
)

start "" "http://127.0.0.1:3847/playground"
call npm run dev
pause
