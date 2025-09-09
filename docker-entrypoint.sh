#!/bin/bash

# Docker entrypoint script for xiaohongshu-mcp

set -e

# 创建必要的目录
mkdir -p /app/cookies /app/data

# browserless 镜像通常已经配置了显示环境
# 只在必要时启动 Xvfb
if [ "$HEADLESS" != "false" ] && [ -z "$DISPLAY" ]; then
    echo "Setting up display for headless mode..."
    export DISPLAY=:99
    # 检查是否需要启动 Xvfb
    if ! pgrep Xvfb > /dev/null; then
        echo "Starting Xvfb..."
        Xvfb :99 -screen 0 1920x1080x24 &
        sleep 2
    fi
fi

# 输出启动信息
echo "Starting xiaohongshu-mcp..."
echo "Working directory: $(pwd)"
echo "Display: $DISPLAY"
echo "Headless mode: ${HEADLESS:-true}"

# 执行主程序
exec "$@"
