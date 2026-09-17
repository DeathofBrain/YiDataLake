@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title YiDataLake - Apache Iceberg

where docker >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Docker was not found. Install or start Docker Desktop first.
  pause
  exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Docker Desktop is not running or is not accessible.
  pause
  exit /b 1
)

docker compose version >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Docker Compose is not available.
  pause
  exit /b 1
)

docker compose config --quiet
if errorlevel 1 (
  echo [ERROR] compose.yaml is invalid.
  pause
  exit /b 1
)

echo.
echo [YiDataLake] Starting MinIO, Iceberg REST Catalog, and Spark...
echo [YiDataLake] Press Ctrl+C once to stop and remove all project containers.
echo [YiDataLake] Persistent data volumes will be preserved.
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run-datalake.ps1"
set "RUN_EXIT=%ERRORLEVEL%"

if not "%RUN_EXIT%"=="0" (
  echo [ERROR] YiDataLake exited with code %RUN_EXIT%.
  pause
  exit /b %RUN_EXIT%
)

echo [YiDataLake] Shutdown completed successfully.
exit /b 0
