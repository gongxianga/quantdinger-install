# QuantDinger Windows 一键安装脚本

自动检测并配置 [QuantDinger](https://github.com/brokermr810/QuantDinger) 量化交易系统的 Windows 运行环境。

## 使用方法

### 方式一：批处理脚本（推荐新手）

右键点击 `install.bat`，选择**以管理员身份运行**。

### 方式二：PowerShell 脚本（功能更完整）

1. 右键点击 `install.ps1`，选择**使用 PowerShell 运行**
2. 如提示执行策略限制，以管理员身份运行 PowerShell 后执行：
   ```
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
   再重新运行脚本。

## 安装流程

脚本会自动完成以下步骤：

1. 检测 Python 3.8+ 环境
2. 检测 Git 环境
3. 克隆 QuantDinger 源码
4. 创建 Python 虚拟环境
5. 安装所有依赖包
6. 生成配置文件模板和 `start.bat` 启动脚本

## 前置要求

| 软件 | 版本要求 | 下载地址 |
|------|----------|----------|
| Python | 3.8 或以上 | https://www.python.org/downloads/ |
| Git | 任意版本 | https://git-scm.com/download/win |

> 安装 Python 时请勾选 **Add Python to PATH**

## 安装后

1. 编辑 `QuantDinger\config\config.yaml`，填写交易所 API Key
2. 双击 `start.bat` 启动系统
3. 访问 `http://localhost:8888` 查看界面
