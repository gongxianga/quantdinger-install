@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ============================================
echo   QuantDinger Windows 一键安装脚本
echo ============================================
echo.

:: 检查 Docker
echo [1/4] 检查 Docker 环境...
docker --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [错误] 未检测到 Docker
    echo 请先安装 Docker Desktop for Windows：
    echo https://www.docker.com/products/docker-desktop/
    echo.
    echo 安装完成后重新运行此脚本
    pause
    exit /b 1
)
docker info >nul 2>&1
if %errorLevel% neq 0 (
    echo [错误] Docker 未启动，请先启动 Docker Desktop
    pause
    exit /b 1
)
echo [OK] Docker 已就绪

:: 检查 Git
echo [2/4] 检查 Git 环境...
git --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [错误] 未检测到 Git
    echo 请先安装 Git：https://git-scm.com/download/win
    pause
    exit /b 1
)
echo [OK] Git 已安装

:: 克隆仓库
echo [3/4] 下载 QuantDinger 源码...
if exist "QuantDinger" (
    echo [信息] 已存在 QuantDinger 目录，执行更新...
    cd QuantDinger
    git pull
    cd ..
) else (
    git clone https://github.com/brokermr810/QuantDinger.git
    if %errorLevel% neq 0 (
        echo [错误] 克隆失败，请检查网络连接
        pause
        exit /b 1
    )
)
echo [OK] 源码下载完成

:: 启动服务
echo [4/4] 启动 QuantDinger 服务（首次拉取镜像可能需要几分钟）...
cd QuantDinger
docker compose -f docker-compose.ghcr.yml pull
docker compose -f docker-compose.ghcr.yml up -d
if %errorLevel% neq 0 (
    echo [错误] 启动失败，请检查 Docker 是否正常运行
    pause
    exit /b 1
)

echo.
echo ============================================
echo   安装完成！
echo ============================================
echo.
echo 访问地址：http://localhost:8888
echo 默认账号：quantdinger
echo 默认密码：123456
echo.
echo [重要] 登录后请立即修改默认密码！
echo.

:: 生成启动和停止脚本
echo @echo off > ..\start.bat
echo cd /d "%~dp0QuantDinger" >> ..\start.bat
echo docker compose -f docker-compose.ghcr.yml up -d >> ..\start.bat
echo echo QuantDinger 已启动，访问 http://localhost:8888 >> ..\start.bat
echo pause >> ..\start.bat

echo @echo off > ..\stop.bat
echo cd /d "%~dp0QuantDinger" >> ..\stop.bat
echo docker compose -f docker-compose.ghcr.yml down >> ..\stop.bat
echo echo QuantDinger 已停止 >> ..\stop.bat
echo pause >> ..\stop.bat

echo [OK] 已生成 start.bat（启动）和 stop.bat（停止）
echo.
pause
