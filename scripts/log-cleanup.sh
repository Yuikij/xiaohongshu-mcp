#!/bin/bash

# xiaohongshu-mcp 日志清理脚本

set -e

echo "🧹 xiaohongshu-mcp 日志清理工具"
echo ""

# 检查参数
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --dry-run     模拟清理，不实际删除"
    echo "  --force       强制清理，不询问确认"
    echo "  --size        只显示当前日志大小"
    echo "  --help, -h    显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --size                # 查看日志大小"
    echo "  $0 --dry-run            # 模拟清理"
    echo "  $0 --force              # 直接清理"
    exit 0
fi

# 获取容器名称
CONTAINER_NAME="xiaohongshu-mcp"

# 检查容器是否存在
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ 容器 $CONTAINER_NAME 不存在"
    exit 1
fi

# 获取容器ID和日志路径
CONTAINER_ID=$(docker ps -aq -f name=$CONTAINER_NAME)
LOG_PATH=$(docker inspect $CONTAINER_ID --format='{{.LogPath}}' 2>/dev/null || echo "")

if [ -z "$LOG_PATH" ]; then
    echo "❌ 无法获取日志路径"
    exit 1
fi

# 显示当前日志大小
echo "📊 当前日志状态:"
echo "容器: $CONTAINER_NAME"
echo "日志路径: $LOG_PATH"

if [ -f "$LOG_PATH" ]; then
    LOG_SIZE=$(ls -lh "$LOG_PATH" | awk '{print $5}')
    echo "主日志文件大小: $LOG_SIZE"
else
    echo "主日志文件: 不存在"
fi

# 查找轮转的日志文件
LOG_DIR=$(dirname "$LOG_PATH")
ROTATED_LOGS=$(find "$LOG_DIR" -name "*-json.log.*" 2>/dev/null | wc -l)
if [ "$ROTATED_LOGS" -gt 0 ]; then
    ROTATED_SIZE=$(find "$LOG_DIR" -name "*-json.log.*" -exec ls -l {} \; 2>/dev/null | awk '{sum+=$5} END {print sum/1024/1024 "MB"}')
    echo "轮转日志文件: $ROTATED_LOGS 个，总大小: $ROTATED_SIZE"
fi

# 如果只是查看大小，直接退出
if [ "$1" = "--size" ]; then
    echo ""
    echo "💡 提示: 使用 '$0 --dry-run' 查看清理预览"
    exit 0
fi

echo ""

# 清理操作
DRY_RUN=false
FORCE=false

case "$1" in
    --dry-run)
        DRY_RUN=true
        echo "🔍 模拟清理模式（不会实际删除文件）"
        ;;
    --force)
        FORCE=true
        echo "⚡ 强制清理模式"
        ;;
    *)
        echo "🤔 交互清理模式"
        ;;
esac

echo ""

# 清理选项
CLEANUP_ACTIONS=()

if [ -f "$LOG_PATH" ] && [ -s "$LOG_PATH" ]; then
    CLEANUP_ACTIONS+=("截断主日志文件")
fi

if [ "$ROTATED_LOGS" -gt 0 ]; then
    CLEANUP_ACTIONS+=("删除轮转日志文件")
fi

if [ ${#CLEANUP_ACTIONS[@]} -eq 0 ]; then
    echo "✅ 没有需要清理的日志文件"
    exit 0
fi

echo "📋 将执行以下清理操作:"
for i in "${!CLEANUP_ACTIONS[@]}"; do
    echo "  $((i+1)). ${CLEANUP_ACTIONS[$i]}"
done

echo ""

# 确认清理
if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
    read -p "确认执行清理？(y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "❌ 清理已取消"
        exit 0
    fi
fi

# 执行清理
echo "🚀 开始清理..."

# 截断主日志文件
if [ -f "$LOG_PATH" ] && [ -s "$LOG_PATH" ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "  [模拟] 截断 $LOG_PATH"
    else
        echo "  截断主日志文件..."
        sudo truncate -s 0 "$LOG_PATH" && echo "  ✅ 主日志文件已截断"
    fi
fi

# 删除轮转日志文件
if [ "$ROTATED_LOGS" -gt 0 ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "  [模拟] 删除 $ROTATED_LOGS 个轮转日志文件"
        find "$LOG_DIR" -name "*-json.log.*" 2>/dev/null | head -5 | while read file; do
            echo "    [模拟] 删除: $file"
        done
    else
        echo "  删除轮转日志文件..."
        find "$LOG_DIR" -name "*-json.log.*" -delete 2>/dev/null && echo "  ✅ 轮转日志文件已删除"
    fi
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "🔍 模拟清理完成！使用 '$0 --force' 执行实际清理"
else
    echo "✅ 日志清理完成！"
    echo ""
    echo "💡 建议:"
    echo "  - 重启容器以确保日志配置生效: docker compose restart xiaohongshu-mcp"
    echo "  - 监控新的日志轮转: make logs-size"
fi
