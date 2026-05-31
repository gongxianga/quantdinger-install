# QuantDinger Windows 一键安装脚本 (PowerShell 版)
# 使用方法：右键点击此文件 -> 使用 PowerShell 运行
# 或在 PowerShell 中执行：Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Step($step, $total, $msg) {
    Write-Host "[$step/$total] $msg" -ForegroundColor Cyan
}
function Write-OK($msg) {
    Write-Host "[OK] $msg" -ForegroundColor Green
}
function Write-Fail($msg) {
    Write-Host "[错误] $msg" -ForegroundColor Red
}
function Write-Info($msg) {
    Write-Host "[信息] $msg" -ForegroundColor Yellow
}

Write-Host "============================================" -ForegroundColor Blue
Write-Host "   QuantDinger Windows 一键安装脚本" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

$TOTAL_STEPS = 6

# 步骤1：检查 Python
Write-Step 1 $TOTAL_STEPS "检查 Python 环境..."
try {
    $pyVer = (python --version 2>&1).ToString()
    if ($pyVer -match "Python (\d+\.\d+)") {
        $major = [int]$Matches[1].Split('.')[0]
        $minor = [int]$Matches[1].Split('.')[1]
        if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 8)) {
            Write-Fail "需要 Python 3.8 或以上版本，当前版本：$pyVer"
            Write-Info "下载地址：https://www.python.org/downloads/"
            Read-Host "按 Enter 退出"
            exit 1
        }
        Write-OK "$pyVer 已安装"
    }
} catch {
    Write-Fail "未检测到 Python，请先安装 Python 3.8+"
    Write-Info "下载地址：https://www.python.org/downloads/"
    Write-Info "安装时请勾选 'Add Python to PATH'"
    Start-Process "https://www.python.org/downloads/"
    Read-Host "安装完成后按 Enter 继续"
    exit 1
}

# 步骤2：检查 Git
Write-Step 2 $TOTAL_STEPS "检查 Git 环境..."
try {
    $gitVer = (git --version 2>&1).ToString()
    Write-OK "$gitVer 已安装"
} catch {
    Write-Fail "未检测到 Git"
    Write-Info "正在打开 Git 下载页面..."
    Start-Process "https://git-scm.com/download/win"
    Read-Host "安装完成后按 Enter 继续"
    exit 1
}

# 步骤3：克隆仓库
Write-Step 3 $TOTAL_STEPS "下载 QuantDinger 源码..."
$installDir = Join-Path $PSScriptRoot "QuantDinger"
if (Test-Path $installDir) {
    Write-Info "已存在 QuantDinger 目录，执行 git pull 更新..."
    Set-Location $installDir
    git pull
} else {
    git clone https://github.com/brokermr810/QuantDinger.git $installDir
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "克隆失败，请检查网络连接或仓库地址"
        Read-Host "按 Enter 退出"
        exit 1
    }
    Set-Location $installDir
}
Write-OK "源码准备完成"

# 步骤4：创建虚拟环境
Write-Step 4 $TOTAL_STEPS "创建 Python 虚拟环境..."
$venvPath = Join-Path $installDir "venv"
if (Test-Path $venvPath) {
    Write-Info "虚拟环境已存在，跳过创建"
} else {
    python -m venv venv
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "创建虚拟环境失败"
        Read-Host "按 Enter 退出"
        exit 1
    }
}
Write-OK "虚拟环境就绪"

# 步骤5：安装依赖
Write-Step 5 $TOTAL_STEPS "安装依赖包（可能需要几分钟）..."
$pip = Join-Path $venvPath "Scripts\pip.exe"
$reqFile = Join-Path $installDir "requirements.txt"

& $pip install --upgrade pip -q
if (Test-Path $reqFile) {
    & $pip install -r $reqFile -q
} else {
    & $pip install pandas numpy ccxt backtrader -q
}
if ($LASTEXITCODE -ne 0) {
    Write-Fail "依赖安装失败"
    Read-Host "按 Enter 退出"
    exit 1
}
Write-OK "依赖安装完成"

# 步骤6：配置文件
Write-Step 6 $TOTAL_STEPS "检查配置文件..."
$configDir = Join-Path $installDir "config"
if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir | Out-Null }

$configFile = Join-Path $configDir "config.yaml"
$configExample = Join-Path $configDir "config.example.yaml"
if (-not (Test-Path $configFile)) {
    if (Test-Path $configExample) {
        Copy-Item $configExample $configFile
        Write-Info "已生成 config\config.yaml，请填写您的交易所 API Key"
    } else {
        Write-Info "请在 config 目录下创建 config.yaml 配置文件"
    }
} else {
    Write-OK "配置文件已存在"
}

# 生成启动脚本
$startBat = Join-Path $PSScriptRoot "start.bat"
@"
@echo off
cd /d "$installDir"
call venv\Scripts\activate.bat
python main.py
pause
"@ | Out-File -FilePath $startBat -Encoding UTF8
Write-OK "已生成 start.bat 启动脚本"

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "   安装完成！" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "后续步骤："
Write-Host "  1. 编辑 QuantDinger\config\config.yaml 填写 API Key"
Write-Host "  2. 双击 start.bat 启动 QuantDinger"
Write-Host "  3. 访问 http://localhost:8888 查看界面"
Write-Host ""
Read-Host "按 Enter 退出"
