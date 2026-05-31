@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ============================================
echo   QuantDinger Windows 一键安装脚本
echo ============================================
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [警告] 建议以管理员身份运行此脚本
    echo 右键点击 install.bat，选择"以管理员身份运行"
    pause
)

:: 检查 Python
echo [1/6] 检查 Python 环境...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [错误] 未检测到 Python，请先安装 Python 3.8 或以上版本
    echo 下载地址: https://www.python.org/downloads/
    echo 安装时请勾选 "Add Python to PATH"
    pause
    exit /b 1
)
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYVER=%%i
echo [OK] Python %PYVER% 已安装

:: 检查 Git
echo [2/6] 检查 Git 环境...
git --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [错误] 未检测到 Git，请先安装 Git
    echo 下载地址: https://git-scm.com/download/win
    pause
    exit /b 1
)
for /f "tokens=3" %%i in ('git --version 2^>^&1') do set GITVER=%%i
echo [OK] Git %GITVER% 已安装

:: 克隆仓库
echo [3/6] 下载 QuantDinger 源码...
if exist "QuantDinger" (
    echo [信息] 已存在 QuantDinger 目录，跳过克隆
) else (
    git clone https://github.com/brokermr810/QuantDinger.git
    if %errorLevel% neq 0 (
        echo [错误] 克隆仓库失败，请检查网络连接
        pause
        exit /b 1
    )
)
echo [OK] 源码下载完成

:: 创建虚拟环境
echo [4/6] 创建 Python 虚拟环境...
cd QuantDinger
if exist "venv" (
    echo [信息] 虚拟环境已存在，跳过创建
) else (
    python -m venv venv
    if %errorLevel% neq 0 (
        echo [错误] 创建虚拟环境失败
        pause
        exit /b 1
    )
)
echo [OK] 虚拟环境创建完成

:: 安装依赖
echo [5/6] 安装依赖包（可能需要几分钟）...
call venv\Scripts\activate.bat
venv\Scripts\python.exe -m pip install --upgrade pip -q
if exist "requirements.txt" (
    venv\Scripts\python.exe -m pip install -r requirements.txt -q
) else (
    venv\Scripts\python.exe -m pip install pandas numpy ccxt ta-lib backtrader -q
)
if %errorLevel% neq 0 (
    echo [错误] 安装依赖失败，请检查网络连接
    pause
    exit /b 1
)
echo [OK] 依赖安装完成

:: 配置检查
echo [6/6] 检查配置文件...
if not exist "config" mkdir config
if not exist "config\config.yaml" (
    if exist "config\config.example.yaml" (
        copy "config\config.example.yaml" "config\config.yaml" >nul
        echo [信息] 已生成 config\config.yaml，请填写您的 API Key
    ) else (
        echo [信息] 请在 config 目录下创建 config.yaml 配置文件
    )
) else (
    echo [OK] 配置文件已存在
)

echo.
echo ============================================
echo   安装完成！
echo ============================================
echo.
echo 后续步骤：
echo   1. 编辑 config\config.yaml 填写交易所 API Key
echo   2. 运行 start.bat 启动 QuantDinger
echo   3. 访问 http://localhost:8888 查看界面
echo.
echo 如需重新激活环境，请运行：venv\Scripts\activate.bat
echo.

:: 创建启动脚本
echo @echo off > ..\start.bat
echo cd /d "%~dp0QuantDinger" >> ..\start.bat
echo call venv\Scripts\activate.bat >> ..\start.bat
echo python main.py >> ..\start.bat
echo pause >> ..\start.bat

echo [OK] 已生成 start.bat 启动脚本
echo.
pause
