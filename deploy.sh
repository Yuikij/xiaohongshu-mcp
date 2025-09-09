#!/bin/bash

# xiaohongshu-mcp Docker 部署脚本
# 使用方法: ./deploy.sh [dev|prod]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查系统依赖..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose 未安装或版本过旧，请安装新版本 Docker Compose"
        exit 1
    fi
    
    log_success "系统依赖检查通过"
}

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."
    
    if [ "$1" = "prod" ]; then
        sudo mkdir -p /opt/xiaohongshu-mcp/{cookies,data,logs}
        sudo chown -R $(id -u):$(id -g) /opt/xiaohongshu-mcp
        log_success "生产环境目录创建完成: /opt/xiaohongshu-mcp"
    else
        mkdir -p ./data/{cookies,logs}
        log_success "开发环境目录创建完成"
    fi
}

# 部署开发环境
deploy_dev() {
    log_info "部署开发环境..."
    
    create_directories "dev"
    
    # 构建并启动服务
    docker compose down 2>/dev/null || true
    docker compose up -d --build
    
    log_success "开发环境部署完成！"
    log_info "服务地址: http://localhost:18060"
    log_info "健康检查: http://localhost:18060/health"
    log_info "MCP端点: http://localhost:18060/mcp"
}

# 部署生产环境
deploy_prod() {
    log_info "部署生产环境..."
    
    create_directories "prod"
    
    # 构建并启动服务
    docker compose -f docker-compose.prod.yml down 2>/dev/null || true
    docker compose -f docker-compose.prod.yml up -d --build
    
    log_success "生产环境部署完成！"
    log_info "服务地址: http://localhost:18060"
    log_info "数据目录: /opt/xiaohongshu-mcp"
}

# 检查服务状态
check_service() {
    log_info "检查服务状态..."
    
    sleep 10  # 等待服务启动
    
    if curl -f http://localhost:18060/health &>/dev/null; then
        log_success "服务运行正常"
    else
        log_warning "服务可能还在启动中，请稍后检查"
        log_info "使用以下命令查看日志:"
        if [ "$1" = "prod" ]; then
            echo "  docker compose -f docker-compose.prod.yml logs -f"
        else
            echo "  docker compose logs -f"
        fi
    fi
}

# 显示后续步骤
show_next_steps() {
    echo ""
    log_info "=== 后续步骤 ==="
    echo ""
    echo "1. 首次使用需要完成小红书登录:"
    echo "   go run cmd/login/main.go"
    echo ""
    echo "2. 验证 MCP 服务:"
    echo "   npx @modelcontextprotocol/inspector"
    echo "   然后连接到: http://localhost:18060/mcp"
    echo ""
    echo "3. 常用命令:"
    echo "   查看日志: make logs"
    echo "   重启服务: make restart"
    echo "   停止服务: make down"
    echo "   健康检查: make health"
    echo ""
    echo "4. 文档参考:"
    echo "   - 主文档: README.md"
    echo "   - Docker文档: README_Docker.md"
    echo "   - MCP接入: MCP_README.md"
    echo ""
}

# 主函数
main() {
    echo ""
    log_info "=== xiaohongshu-mcp Docker 部署工具 ==="
    echo ""
    
    # 参数检查
    if [ $# -eq 0 ]; then
        log_info "使用方法: $0 [dev|prod]"
        log_info "  dev  - 部署开发环境"
        log_info "  prod - 部署生产环境"
        exit 1
    fi
    
    MODE=$1
    
    case $MODE in
        "dev")
            log_info "开始部署开发环境..."
            check_dependencies
            deploy_dev
            check_service "dev"
            show_next_steps
            ;;
        "prod")
            log_info "开始部署生产环境..."
            check_dependencies
            deploy_prod
            check_service "prod"
            show_next_steps
            ;;
        *)
            log_error "无效的部署模式: $MODE"
            log_info "支持的模式: dev, prod"
            exit 1
            ;;
    esac
    
    log_success "部署完成！"
}

# 信号处理
trap 'log_error "部署被中断"; exit 1' INT TERM

# 执行主函数
main "$@"
