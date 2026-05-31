# QuantDinger Windows 一键安装脚本

自动部署 [QuantDinger](https://github.com/brokermr810/QuantDinger) 量化交易系统到 Windows 本地环境。

> QuantDinger 基于 Docker 运行，请确保已安装 Docker Desktop。

## 前置要求

| 软件 | 说明 | 下载地址 |
|------|------|----------|
| Docker Desktop | 必须，且需保持运行 | https://www.docker.com/products/docker-desktop/ |
| Git | 必须 | https://git-scm.com/download/win |

## 使用方法

### 方式一：批处理脚本（推荐）

双击运行 `install.bat`，或右键选择**以管理员身份运行**。

### 方式二：PowerShell 脚本

1. 右键点击 `install.ps1` → **使用 PowerShell 运行**
2. 如提示执行策略限制，先在 PowerShell 中执行：
   ```
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## 安装流程

1. 检测 Docker 环境
2. 检测 Git 环境
3. 克隆 QuantDinger 源码
4. 拉取 Docker 镜像并启动服务
5. 生成 `start.bat` 和 `stop.bat` 快捷脚本

## 安装完成后

| 项目 | 内容 |
|------|------|
| 访问地址 | http://localhost:8888 |
| 默认账号 | quantdinger |
| 默认密码 | 123456 |

**登录后请立即修改默认密码！**

## 日常使用

- **启动**：双击 `start.bat`
- **停止**：双击 `stop.bat`
