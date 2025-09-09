#!/bin/bash

# xiaohongshu-mcp systemd 服务卸载脚本
# 使用方法: sudo ./uninstall-service.sh

set -e

SERVICE_NAME="xiaohongshu-mcp"
SERVICE_FILE="xiaohongshu-mcp.service"
SYSTEMD_PATH="/etc/systemd/system"

echo "=== Xiaohongshu MCP Systemd 服务卸载脚本 ==="

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   echo "错误: 此脚本需要以root权限运行 (使用 sudo)"
   exit 1
fi

echo "1. 停止服务..."
systemctl stop $SERVICE_NAME 2>/dev/null || true

echo "2. 禁用服务..."
systemctl disable $SERVICE_NAME 2>/dev/null || true

echo "3. 删除systemd服务文件..."
rm -f "$SYSTEMD_PATH/$SERVICE_FILE"

echo "4. 重新加载systemd配置..."
systemctl daemon-reload

echo "5. 重置失败状态 (如果有)..."
systemctl reset-failed $SERVICE_NAME 2>/dev/null || true

echo ""
echo "=== 卸载完成! ==="
echo "服务 $SERVICE_NAME 已被完全移除"
