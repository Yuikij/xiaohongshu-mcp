@echo off
:: xiaohongshu-mcp Docker 部署脚本 (Windows版本)
:: 使用方法: deploy.bat [dev|prod]

setlocal enabledelayedexpansion

:: 检查参数
if "%1"=="" (
    echo [INFO] 使用方法: %0 [dev^|prod]
    echo [INFO]   dev  - 部署开发环境
    echo [INFO]   prod - 部署生产环境
    exit /b 1
)

set MODE=%1

echo.
echo [INFO] === xiaohongshu-mcp Docker 部署工具 ===
echo.

:: 检查依赖
echo [INFO] 检查系统依赖...
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker 未安装，请先安装 Docker Desktop
    exit /b 1
)

docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker Compose 未安装，请先安装 Docker Compose
    exit /b 1
)
echo [SUCCESS] 系统依赖检查通过

:: 创建目录
echo [INFO] 创建必要的目录...
if "%MODE%"=="prod" (
    if not exist "C:\opt\xiaohongshu-mcp" mkdir "C:\opt\xiaohongshu-mcp"
    if not exist "C:\opt\xiaohongshu-mcp\cookies" mkdir "C:\opt\xiaohongshu-mcp\cookies"
    if not exist "C:\opt\xiaohongshu-mcp\data" mkdir "C:\opt\xiaohongshu-mcp\data"
    if not exist "C:\opt\xiaohongshu-mcp\logs" mkdir "C:\opt\xiaohongshu-mcp\logs"
    echo [SUCCESS] 生产环境目录创建完成: C:\opt\xiaohongshu-mcp
) else (
    if not exist "data" mkdir data
    if not exist "data\cookies" mkdir data\cookies
    if not exist "data\logs" mkdir data\logs
    echo [SUCCESS] 开发环境目录创建完成
)

:: 部署服务
if "%MODE%"=="dev" (
    echo [INFO] 部署开发环境...
    docker-compose down 2>nul
    docker-compose up -d --build
    echo [SUCCESS] 开发环境部署完成！
) else if "%MODE%"=="prod" (
    echo [INFO] 部署生产环境...
    docker-compose -f docker-compose.prod.yml down 2>nul
    docker-compose -f docker-compose.prod.yml up -d --build
    echo [SUCCESS] 生产环境部署完成！
) else (
    echo [ERROR] 无效的部署模式: %MODE%
    echo [INFO] 支持的模式: dev, prod
    exit /b 1
)

:: 检查服务状态
echo [INFO] 检查服务状态...
timeout /t 10 /nobreak >nul
curl -f http://localhost:18060/health >nul 2>&1
if errorlevel 1 (
    echo [WARNING] 服务可能还在启动中，请稍后检查
    echo [INFO] 使用以下命令查看日志:
    if "%MODE%"=="prod" (
        echo   docker-compose -f docker-compose.prod.yml logs -f
    ) else (
        echo   docker-compose logs -f
    )
) else (
    echo [SUCCESS] 服务运行正常
)

:: 显示后续步骤
echo.
echo [INFO] === 后续步骤 ===
echo.
echo 1. 首次使用需要完成小红书登录:
echo    go run cmd/login/main.go
echo.
echo 2. 验证 MCP 服务:
echo    npx @modelcontextprotocol/inspector
echo    然后连接到: http://localhost:18060/mcp
echo.
echo 3. 常用命令:
echo    查看日志: make logs
echo    重启服务: make restart
echo    停止服务: make down
echo    健康检查: make health
echo.
echo 4. 文档参考:
echo    - 主文档: README.md
echo    - Docker文档: README_Docker.md
echo    - MCP接入: MCP_README.md
echo.
echo [SUCCESS] 部署完成！

echo.
echo [INFO] 服务地址: http://localhost:18060
echo [INFO] 健康检查: http://localhost:18060/health
echo [INFO] MCP端点: http://localhost:18060/mcp

endlocal
