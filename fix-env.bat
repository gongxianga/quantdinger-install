@echo off
setlocal

:: Keep window open on any error
if "%1"=="ELEVATED" goto :main
cmd /k "%~f0" ELEVATED
exit /b

:main
echo ============================================
echo   QuantDinger Fix - backend.env
echo ============================================
echo.

set "SCRIPT_DIR=%~dp0"
set "QD_DIR=%SCRIPT_DIR%QuantDinger"

:: Check QuantDinger directory exists
if not exist "%QD_DIR%" (
    echo [ERROR] QuantDinger folder not found at: %QD_DIR%
    echo Make sure you run this script from the quantdinger-install folder.
    goto :end
)

echo [1/4] Stopping QuantDinger...
cd /d "%QD_DIR%"
docker compose -f docker-compose.ghcr.yml down
echo.

echo [2/4] Removing bad backend.env...
if exist "%QD_DIR%\backend.env" (
    attrib -r "%QD_DIR%\backend.env" >nul 2>&1
    rmdir /s /q "%QD_DIR%\backend.env" >nul 2>&1
    del /f /q "%QD_DIR%\backend.env" >nul 2>&1
    echo [OK] Removed old backend.env
)

echo [3/4] Creating backend.env from template...
if not exist "%QD_DIR%\backend_api_python\env.example" (
    echo [ERROR] Template not found: %QD_DIR%\backend_api_python\env.example
    goto :end
)
copy /y "%QD_DIR%\backend_api_python\env.example" "%QD_DIR%\backend.env" >nul
echo [OK] backend.env created.

echo [4/4] Restarting QuantDinger...
docker compose -f docker-compose.ghcr.yml up -d
echo.

echo ============================================
echo   Done!
echo ============================================
echo.
echo Wait 1-2 minutes then open: http://localhost:8888
echo Username: quantdinger
echo Password: 123456
echo.

:end
echo Press any key to close...
pause >nul
