@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ============================================
echo   QuantDinger Windows 一键安装脚本
echo ============================================
echo.

:: 检查管理员权限（Docker 安装需要）
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [提示] 请右键点击此脚本，选择"以管理员身份运行"
    pause
    exit /b 1
)

:: ============ 步骤1：检查/安装 Docker ============
echo [1/4] 检查 Docker 环境...
docker --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [信息] 未检测到 Docker，开始自动下载安装...
    echo [信息] 文件较大（约600MB），请耐心等待...

    :: 启用 WSL2（Docker Desktop 依赖）
    echo [信息] 启用 WSL2 功能...
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >nul 2>&1
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >nul 2>&1

    :: 下载 Docker Desktop 安装包
    set DOCKER_INSTALLER=%TEMP%\DockerDesktopInstaller.exe
    powershell -Command "Invoke-WebRequest -Uri 'https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe' -OutFile '%DOCKER_INSTALLER%' -UseBasicParsing"
    if %errorLevel% neq 0 (
        echo [错误] Docker 下载失败，请手动安装：https://www.docker.com/products/docker-desktop/
        pause
        exit /b 1
    )

    :: 静默安装 Docker Desktop
    echo [信息] 正在安装 Docker Desktop（请稍候）...
    "%DOCKER_INSTALLER%" install --quiet --accept-license
    if %errorLevel% neq 0 (
        echo [错误] Docker 安装失败，请手动安装后重新运行此脚本
        pause
        exit /b 1
    )

    echo [OK] Docker Desktop 安装完成
    echo [重要] 需要重启电脑以完成 WSL2 配置
    echo 重启后请重新运行此脚本继续安装 QuantDinger
    echo.
    set /p REBOOT="是否立即重启？(Y/N): "
    if /i "!REBOOT!"=="Y" (
        shutdown /r /t 10 /c "重启以完成 Docker 安装，10秒后重启..."
    )
    pause
    exit /b 0
)

:: 检查 Docker 是否已启动
docker info >nul 2>&1
if %errorLevel% neq 0 (
    echo [信息] Docker 已安装但未启动，正在启动 Docker Desktop...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    echo [信息] 等待 Docker 启动（最多60秒）...
    set /a COUNT=0
    :WAIT_DOCKER
    timeout /t 5 /nobreak >nul
    docker info >nul 2>&1
    if %errorLevel% equ 0 goto DOCKER_READY
    set /a COUNT+=1
    if !COUNT! lss 12 (
        echo [信息] 等待中...（!COUNT!/12）
        goto WAIT_DOCKER
    )
    echo [错误] Docker 启动超时，请手动启动 Docker Desktop 后重试
    pause
    exit /b 1
)
:DOCKER_READY
echo [OK] Docker 已就绪

:: ============ 步骤2：检查/安装 Git ============
echo [2/4] 检查 Git 环境...
git --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [信息] 未检测到 Git，开始自动下载安装...
    set GIT_INSTALLER=%TEMP%\GitInstaller.exe
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe' -OutFile '%GIT_INSTALLER%' -UseBasicParsing"
    if %errorLevel% neq 0 (
        echo [错误] Git 下载失败，请手动安装：https://git-scm.com/download/win
        pause
        exit /b 1
    )
    echo [信息] 正在安装 Git...
    "%GIT_INSTALLER%" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS="icons,ext\reg\shellhere,assoc,assoc_sh"
    :: 刷新 PATH
    set "PATH=%PATH%;C:\Program Files\Git\cmd"
    git --version >nul 2>&1
    if %errorLevel% neq 0 (
        echo [错误] Git 安装完成，但需要重新打开命令窗口
        echo 请关闭此窗口后重新运行 install.bat
        pause
        exit /b 1
    )
)
echo [OK] Git 已安装

:: ============ 步骤3：克隆仓库 ============
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

:: ============ 步骤4：启动服务 ============
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
set QDIR=%~dp0QuantDinger
echo @echo off > ..\start.bat
echo cd /d "%QDIR%" >> ..\start.bat
echo docker compose -f docker-compose.ghcr.yml up -d >> ..\start.bat
echo echo QuantDinger 已启动，访问 http://localhost:8888 >> ..\start.bat
echo pause >> ..\start.bat

echo @echo off > ..\stop.bat
echo cd /d "%QDIR%" >> ..\stop.bat
echo docker compose -f docker-compose.ghcr.yml down >> ..\stop.bat
echo echo QuantDinger 已停止 >> ..\stop.bat
echo pause >> ..\stop.bat

echo [OK] 已生成 start.bat（启动）和 stop.bat（停止）
echo.
pause
