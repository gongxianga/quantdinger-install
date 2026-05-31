# QuantDinger Windows 一键安装脚本 (PowerShell 版)
# 使用方法：右键 -> 使用 PowerShell 运行
# 或先执行：Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Step($step, $total, $msg) { Write-Host "[$step/$total] $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Fail($msg) { Write-Host "[错误] $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "[信息] $msg" -ForegroundColor Yellow }

Write-Host "============================================" -ForegroundColor Blue
Write-Host "   QuantDinger Windows 一键安装脚本" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host ""

$TOTAL = 4

# 步骤1：检查 Docker
Write-Step 1 $TOTAL "检查 Docker 环境..."
try {
    docker --version | Out-Null
    docker info 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Docker 未启动，请先启动 Docker Desktop"
        Read-Host "按 Enter 退出"
        exit 1
    }
    Write-OK "Docker 已就绪"
} catch {
    Write-Fail "未检测到 Docker，请先安装 Docker Desktop"
    Write-Info "下载地址：https://www.docker.com/products/docker-desktop/"
    Start-Process "https://www.docker.com/products/docker-desktop/"
    Read-Host "安装完成后按 Enter 重新运行脚本"
    exit 1
}

# 步骤2：检查 Git
Write-Step 2 $TOTAL "检查 Git 环境..."
try {
    git --version | Out-Null
    Write-OK "Git 已安装"
} catch {
    Write-Fail "未检测到 Git"
    Write-Info "正在打开 Git 下载页面..."
    Start-Process "https://git-scm.com/download/win"
    Read-Host "安装完成后按 Enter 重新运行脚本"
    exit 1
}

# 步骤3：克隆仓库
Write-Step 3 $TOTAL "下载 QuantDinger 源码..."
$installDir = Join-Path $PSScriptRoot "QuantDinger"
if (Test-Path $installDir) {
    Write-Info "已存在 QuantDinger 目录，执行 git pull 更新..."
    Set-Location $installDir
    git pull
} else {
    git clone https://github.com/brokermr810/QuantDinger.git $installDir
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "克隆失败，请检查网络连接"
        Read-Host "按 Enter 退出"
        exit 1
    }
    Set-Location $installDir
}
Write-OK "源码准备完成"

# 步骤4：启动服务
Write-Step 4 $TOTAL "启动 QuantDinger 服务（首次拉取镜像可能需要几分钟）..."
docker compose -f docker-compose.ghcr.yml pull
docker compose -f docker-compose.ghcr.yml up -d
if ($LASTEXITCODE -ne 0) {
    Write-Fail "启动失败，请检查 Docker 是否正常运行"
    Read-Host "按 Enter 退出"
    exit 1
}

# 生成启动/停止脚本
$startBat = Join-Path $PSScriptRoot "start.bat"
$stopBat  = Join-Path $PSScriptRoot "stop.bat"

@"
@echo off
cd /d "$installDir"
docker compose -f docker-compose.ghcr.yml up -d
echo QuantDinger 已启动，访问 http://localhost:8888
pause
"@ | Out-File -FilePath $startBat -Encoding UTF8

@"
@echo off
cd /d "$installDir"
docker compose -f docker-compose.ghcr.yml down
echo QuantDinger 已停止
pause
"@ | Out-File -FilePath $stopBat -Encoding UTF8

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "   安装完成！" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "访问地址：http://localhost:8888"
Write-Host "默认账号：quantdinger"
Write-Host "默认密码：123456"
Write-Host ""
Write-Host "[重要] 登录后请立即修改默认密码！" -ForegroundColor Red
Write-Host ""
Write-Host "已生成 start.bat（启动）和 stop.bat（停止）"
Write-Host ""
Read-Host "按 Enter 退出"
