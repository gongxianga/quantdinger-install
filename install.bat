@echo off
setlocal enabledelayedexpansion

:: Auto-elevate to admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs -Wait"
    exit /b
)

echo ============================================
echo   QuantDinger One-Click Installer
echo ============================================
echo.

:: ===== Step 1: Check / Install Docker =====
echo [1/4] Checking Docker...
where docker >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Docker not found. Downloading Docker Desktop ~600MB...

    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >nul 2>&1
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >nul 2>&1

    set "DOCKER_EXE=%TEMP%\DockerDesktopInstaller.exe"
    powershell -Command "Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker%%20Desktop%%20Installer.exe' -OutFile '%TEMP%\DockerDesktopInstaller.exe' -UseBasicParsing"
    if %errorLevel% neq 0 (
        echo [ERROR] Download failed. Install manually: https://www.docker.com/products/docker-desktop/
        goto :end
    )

    echo [INFO] Installing Docker Desktop...
    "%TEMP%\DockerDesktopInstaller.exe" install --quiet --accept-license
    echo [OK] Docker Desktop installed. Please reboot then run install.bat again.
    goto :end
)

docker info >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Docker not running. Starting Docker Desktop...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo [INFO] Waiting up to 60s for Docker...
    set COUNT=0
    :WAIT
    timeout /t 5 /nobreak >nul
    docker info >nul 2>&1
    if %errorLevel% equ 0 goto :DOCKER_OK
    set /a COUNT+=1
    echo [INFO] Waiting... !COUNT!/12
    if !COUNT! lss 12 goto :WAIT
    echo [ERROR] Docker did not start. Open Docker Desktop manually then retry.
    goto :end
)
:DOCKER_OK
echo [OK] Docker is ready.

:: ===== Step 2: Check / Install Git =====
echo [2/4] Checking Git...
where git >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Git not found. Downloading...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe' -OutFile '%TEMP%\GitInstaller.exe' -UseBasicParsing"
    if %errorLevel% neq 0 (
        echo [ERROR] Git download failed. Install manually: https://git-scm.com/download/win
        goto :end
    )
    "%TEMP%\GitInstaller.exe" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
    where git >nul 2>&1
    if %errorLevel% neq 0 (
        echo [INFO] Git installed. Please close and run install.bat again.
        goto :end
    )
)
echo [OK] Git is ready.

:: ===== Step 3: Clone repo =====
echo [3/4] Downloading QuantDinger...
cd /d "%~dp0"
if exist "QuantDinger" (
    echo [INFO] Updating existing install...
    cd QuantDinger && git pull && cd ..
) else (
    git clone https://github.com/brokermr810/QuantDinger.git
    if %errorLevel% neq 0 (
        echo [ERROR] Clone failed. Check network connection.
        goto :end
    )
)
echo [OK] Source ready.

:: ===== Step 4: Create backend.env and start =====
echo [4/4] Starting QuantDinger...
cd /d "%~dp0QuantDinger"

if exist "backend.env" (
    rmdir /s /q "backend.env" >nul 2>&1
    del /f /q "backend.env" >nul 2>&1
)
if not exist "backend.env" (
    copy /y "backend_api_python\env.example" "backend.env" >nul
    echo [OK] backend.env created.
)

docker compose -f docker-compose.ghcr.yml pull
docker compose -f docker-compose.ghcr.yml up -d
if %errorLevel% neq 0 (
    echo [ERROR] Failed to start. Check Docker is running.
    goto :end
)

:: Create shortcuts
set "QDIR=%~dp0QuantDinger"
>"../start.bat" echo @echo off
>>"../start.bat" echo cd /d "%QDIR%"
>>"../start.bat" echo docker compose -f docker-compose.ghcr.yml up -d
>>"../start.bat" echo echo Started - open http://localhost:8888
>>"../start.bat" echo pause

>"../stop.bat" echo @echo off
>>"../stop.bat" echo cd /d "%QDIR%"
>>"../stop.bat" echo docker compose -f docker-compose.ghcr.yml down
>>"../stop.bat" echo echo Stopped.
>>"../stop.bat" echo pause

echo.
echo ============================================
echo   Installation complete!
echo ============================================
echo.
echo   URL:      http://localhost:8888
echo   Username: quantdinger
echo   Password: 123456
echo.
echo   IMPORTANT: Change the default password after login!
echo   start.bat = start   /   stop.bat = stop
echo.

:end
echo.
echo Press any key to close...
pause >nul
