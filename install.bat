@echo off
setlocal enabledelayedexpansion

echo ============================================
echo   QuantDinger One-Click Installer
echo ============================================
echo.

:: Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Please run as Administrator.
    echo Right-click install.bat and select "Run as administrator"
    pause
    exit /b 1
)

:: ===== Step 1: Check / Install Docker =====
echo [1/4] Checking Docker...
docker --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Docker not found. Downloading Docker Desktop...
    echo [INFO] File size ~600MB, please wait...

    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >nul 2>&1
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >nul 2>&1

    set "DOCKER_EXE=%TEMP%\DockerDesktopInstaller.exe"
    powershell -Command "Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker%%20Desktop%%20Installer.exe' -OutFile '!DOCKER_EXE!' -UseBasicParsing"
    if %errorLevel% neq 0 (
        echo [ERROR] Download failed. Install manually: https://www.docker.com/products/docker-desktop/
        pause
        exit /b 1
    )

    echo [INFO] Installing Docker Desktop...
    "!DOCKER_EXE!" install --quiet --accept-license
    if %errorLevel% neq 0 (
        echo [ERROR] Docker install failed. Please install manually then re-run.
        pause
        exit /b 1
    )

    echo [OK] Docker Desktop installed.
    echo [IMPORTANT] A reboot is required to finish WSL2 setup.
    echo After reboot, run install.bat again to continue.
    echo.
    set /p REBOOT="Reboot now? (Y/N): "
    if /i "!REBOOT!"=="Y" shutdown /r /t 10 /c "Rebooting to finish Docker setup..."
    pause
    exit /b 0
)

docker info >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Docker is installed but not running. Starting Docker Desktop...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo [INFO] Waiting for Docker to start (up to 60s)...
    set /a COUNT=0
    :WAIT_DOCKER
    timeout /t 5 /nobreak >nul
    docker info >nul 2>&1
    if %errorLevel% equ 0 goto DOCKER_READY
    set /a COUNT+=1
    if !COUNT! lss 12 (
        echo [INFO] Still waiting... (!COUNT!/12^)
        goto WAIT_DOCKER
    )
    echo [ERROR] Docker did not start in time. Please start Docker Desktop manually then retry.
    pause
    exit /b 1
)
:DOCKER_READY
echo [OK] Docker is ready.

:: ===== Step 2: Check / Install Git =====
echo [2/4] Checking Git...
git --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Git not found. Downloading...
    set "GIT_EXE=%TEMP%\GitInstaller.exe"
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe' -OutFile '!GIT_EXE!' -UseBasicParsing"
    if %errorLevel% neq 0 (
        echo [ERROR] Download failed. Install manually: https://git-scm.com/download/win
        pause
        exit /b 1
    )
    echo [INFO] Installing Git...
    "!GIT_EXE!" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
    git --version >nul 2>&1
    if %errorLevel% neq 0 (
        echo [INFO] Git installed. Please close this window and run install.bat again.
        pause
        exit /b 0
    )
)
echo [OK] Git is ready.

:: ===== Step 3: Clone repo =====
echo [3/4] Downloading QuantDinger source...
if exist "QuantDinger" (
    echo [INFO] Directory exists, pulling latest...
    cd QuantDinger
    git pull
    cd ..
) else (
    git clone https://github.com/brokermr810/QuantDinger.git
    if %errorLevel% neq 0 (
        echo [ERROR] Clone failed. Check your network connection.
        pause
        exit /b 1
    )
)
echo [OK] Source ready.

:: ===== Step 4: Start services =====
echo [4/4] Starting QuantDinger (first run may take a few minutes)...
cd QuantDinger

:: Create backend.env before Docker starts (prevents Docker creating it as a directory)
if exist "backend.env\" rmdir /s /q "backend.env"
if not exist "backend.env" (
    copy /y "backend_api_python\env.example" "backend.env" >nul
    echo [OK] backend.env created.
)
docker compose -f docker-compose.ghcr.yml pull
docker compose -f docker-compose.ghcr.yml up -d
if %errorLevel% neq 0 (
    echo [ERROR] Failed to start. Check Docker is running.
    pause
    exit /b 1
)

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
echo.

:: Generate start / stop shortcuts
set "QDIR=%~dp0QuantDinger"
(
    echo @echo off
    echo cd /d "%QDIR%"
    echo docker compose -f docker-compose.ghcr.yml up -d
    echo echo Started - open http://localhost:8888
    echo pause
) > "%~dp0start.bat"

(
    echo @echo off
    echo cd /d "%QDIR%"
    echo docker compose -f docker-compose.ghcr.yml down
    echo echo QuantDinger stopped.
    echo pause
) > "%~dp0stop.bat"

echo [OK] start.bat and stop.bat created.
echo.
pause
