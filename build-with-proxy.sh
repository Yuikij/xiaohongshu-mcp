#!/bin/bash

# 带代理的 Docker 构建脚本
# 使用方法: ./build-with-proxy.sh [proxy_url]

set -e

# 默认代理地址
DEFAULT_PROXY="http://172.23.104.184:7890"

# 使用传入的代理地址，或者使用默认值
PROXY_URL=${1:-$DEFAULT_PROXY}

echo "🚀 使用代理构建 Docker 镜像..."
echo "代理地址: $PROXY_URL"

# 构建 Docker 镜像
docker build \
    --build-arg HTTP_PROXY="$PROXY_URL" \
    --build-arg HTTPS_PROXY="$PROXY_URL" \
    --progress=plain \
    -t xiaohongshu-mcp:latest .

echo "✅ 构建完成！"

# 显示镜像信息
echo ""
echo "📦 镜像信息:"
docker images xiaohongshu-mcp:latest
