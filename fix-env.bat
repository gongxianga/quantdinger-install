@echo off
setlocal

echo [1/4] Stopping QuantDinger...
cd /d "%~dp0QuantDinger"
docker compose -f docker-compose.ghcr.yml down

echo [2/4] Removing bad backend.env directory...
if exist "backend.env\" (
    rmdir /s /q "backend.env"
)
if exist "backend.env" (
    del /f /q "backend.env"
)

echo [3/4] Creating backend.env from template...
if exist "backend_api_python\env.example" (
    copy /y "backend_api_python\env.example" "backend.env" >nul
    echo [OK] backend.env created.
) else (
    echo [ERROR] env.example not found.
    pause
    exit /b 1
)

echo [4/4] Restarting QuantDinger...
docker compose -f docker-compose.ghcr.yml up -d

echo.
echo Done! Wait 1-2 minutes then open http://localhost:8888
echo Username: quantdinger  /  Password: 123456
echo.
pause
