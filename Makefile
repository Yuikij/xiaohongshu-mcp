# Makefile for xiaohongshu-mcp Docker deployment

.PHONY: help build up down logs clean dev prod restart status

# 默认目标
help: ## 显示帮助信息
	@echo "xiaohongshu-mcp Docker 部署命令："
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# 开发环境
dev: ## 启动开发环境
	docker compose up -d --build

dev-logs: ## 查看开发环境日志
	docker compose logs -f

dev-down: ## 停止开发环境
	docker compose down

# 生产环境
prod: ## 启动生产环境
	docker compose -f docker-compose.prod.yml up -d --build

prod-logs: ## 查看生产环境日志
	docker compose -f docker-compose.prod.yml logs -f

prod-down: ## 停止生产环境
	docker compose -f docker-compose.prod.yml down

# 通用命令
build: ## 构建镜像
	docker build -t xiaohongshu-mcp:latest .

build-proxy: ## 使用代理构建镜像
	./build-with-proxy.sh

rebuild: ## 重新构建并启动
	docker compose down
	docker compose up -d --build

rebuild-proxy: ## 使用代理重新构建并启动
	./build-with-proxy.sh
	docker compose up -d

restart: ## 重启服务
	docker compose restart xiaohongshu-mcp

status: ## 查看服务状态
	docker compose ps

health: ## 检查服务健康状态
	curl -f http://localhost:18060/health || echo "Service is not healthy"

logs: ## 查看日志（最近100行）
	docker compose logs --tail=100 -f xiaohongshu-mcp

shell: ## 进入容器shell
	docker compose exec xiaohongshu-mcp bash

# 清理命令
clean: ## 清理停止的容器和无用镜像
	docker container prune -f
	docker image prune -f

clean-all: ## 完全清理（包括卷和网络）
	docker compose down -v --remove-orphans
	docker system prune -af --volumes

# 备份和恢复
backup: ## 备份cookies数据
	mkdir -p ./backup
	docker cp $$(docker compose ps -q xiaohongshu-mcp):/app/cookies ./backup/cookies-$$(date +%Y%m%d-%H%M%S)

restore: ## 恢复cookies数据（需要指定备份目录 BACKUP_DIR=xxx）
	@if [ -z "$(BACKUP_DIR)" ]; then echo "请指定备份目录: make restore BACKUP_DIR=./backup/cookies-20231201-120000"; exit 1; fi
	docker cp $(BACKUP_DIR) $$(docker compose ps -q xiaohongshu-mcp):/app/cookies

# 监控命令
stats: ## 查看容器资源使用统计
	docker stats $$(docker compose ps -q)

inspect: ## 查看容器详细信息
	docker inspect xiaohongshu-mcp

# 登录相关
login-setup: ## 设置登录环境（在宿主机运行）
	@echo "请在宿主机上运行以下命令完成登录："
	@echo "go run cmd/login/main.go"
	@echo ""
	@echo "登录完成后，cookies将自动保存到 ./cookies 目录"
	@echo "容器重启时会自动加载这些cookies"

# 测试命令
test-mcp: ## 测试MCP连接
	curl -X POST http://localhost:18060/mcp \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","id":"test","method":"tools/list","params":{}}'

test-api: ## 测试API连接
	curl -X GET http://localhost:18060/api/v1/login/status

# 开发工具
fmt: ## 格式化代码
	go fmt ./...

lint: ## 运行代码检查
	golangci-lint run

test: ## 运行测试
	go test ./...

# 部署相关
deploy-prod: ## 部署到生产环境
	@echo "部署生产环境..."
	sudo mkdir -p /opt/xiaohongshu-mcp/{cookies,data}
	sudo chown -R 1000:1000 /opt/xiaohongshu-mcp
	docker compose -f docker-compose.prod.yml up -d --build
	@echo "生产环境部署完成！"

# 显示有用信息
info: ## 显示服务信息
	@echo "=== xiaohongshu-mcp 服务信息 ==="
	@echo "开发环境: http://localhost:18060"
	@echo "健康检查: http://localhost:18060/health"
	@echo "MCP端点: http://localhost:18060/mcp"
	@echo "API文档: 参见 README.md"
	@echo ""
	@echo "=== 容器状态 ==="
	@docker compose ps 2>/dev/null || echo "容器未运行"
	@echo ""
	@echo "=== 有用命令 ==="
	@echo "查看日志: make logs"
	@echo "重启服务: make restart"
	@echo "进入容器: make shell"
	@echo "检查健康: make health"
