#!/bin/bash

# xiaohongshu-mcp systemd 服务安装脚本
# 使用方法: sudo ./install-service.sh

set -e

SERVICE_NAME="xiaohongshu-mcp"
SERVICE_FILE="xiaohongshu-mcp.service"
SYSTEMD_PATH="/etc/systemd/system"
CURRENT_DIR="$(pwd)"
BINARY_NAME="xiaohongshu-mcp"

echo "=== Xiaohongshu MCP Systemd 服务安装脚本 ==="

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   echo "错误: 此脚本需要以root权限运行 (使用 sudo)"
   exit 1
fi

# 检查service文件是否存在
if [ ! -f "$SERVICE_FILE" ]; then
    echo "错误: $SERVICE_FILE 文件不存在"
    exit 1
fi

echo "1. 停止现有服务 (如果存在)..."
systemctl stop $SERVICE_NAME 2>/dev/null || true
systemctl disable $SERVICE_NAME 2>/dev/null || true

echo "2. 编译Go应用..."
cd "$CURRENT_DIR"
sudo -u shiori go build -o $BINARY_NAME .
chmod +x $BINARY_NAME

echo "3. 安装systemd服务文件..."
cp "$SERVICE_FILE" "$SYSTEMD_PATH/$SERVICE_FILE"

echo "4. 重新加载systemd配置..."
systemctl daemon-reload

echo "5. 启用并启动服务..."
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

echo "6. 检查服务状态..."
sleep 2
systemctl status $SERVICE_NAME --no-pager

echo ""
echo "=== 安装完成! ==="
echo "服务名称: $SERVICE_NAME"
echo "服务状态: systemctl status $SERVICE_NAME"
echo "启动服务: systemctl start $SERVICE_NAME"
echo "停止服务: systemctl stop $SERVICE_NAME"
echo "重启服务: systemctl restart $SERVICE_NAME"
echo "查看日志: journalctl -u $SERVICE_NAME -f"
echo "禁用服务: systemctl disable $SERVICE_NAME"
echo ""
echo "应用将在 http://localhost:18060 上运行"
