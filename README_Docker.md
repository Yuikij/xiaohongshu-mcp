# Docker 部署指南

本文档描述如何使用 Docker 部署 xiaohongshu-mcp 服务。

## 🐳 快速开始

### 1. 构建并启动服务

```bash
# 使用 docker-compose 构建并启动
docker-compose up -d --build

# 或者分步执行
docker build -t xiaohongshu-mcp .
docker-compose up -d
```

### 2. 查看服务状态

```bash
# 查看容器状态
docker-compose ps

# 查看服务日志
docker-compose logs -f xiaohongshu-mcp

# 健康检查
curl http://localhost:18060/health
```

## 📋 前置条件

### 系统要求

- Docker Engine 20.10+
- Docker Compose 2.0+
- 至少 2GB 可用内存
- 至少 6GB 可用存储空间（browserless/chromium 镜像较大）

### 首次登录

容器启动后，你需要首先完成小红书登录：

```bash
# 进入容器
docker-compose exec xiaohongshu-mcp bash

# 运行登录命令（注意：这需要图形界面，建议在宿主机运行）
go run cmd/login/main.go
```

**推荐方式**：在宿主机上完成登录，然后将 cookies 目录挂载到容器中。

## 🔧 配置选项

### 环境变量

在 `docker-compose.yml` 中可以配置以下环境变量：

```yaml
environment:
  - GIN_MODE=release          # Gin 运行模式
  - TZ=Asia/Shanghai          # 时区设置
  - HTTP_PROXY=http://proxy:port   # HTTP 代理（可选）
  - HTTPS_PROXY=http://proxy:port  # HTTPS 代理（可选）
```

### 数据持久化

服务使用以下卷来持久化数据：

- `xiaohongshu_cookies`: 存储登录 cookies
- `xiaohongshu_data`: 存储其他应用数据

### 网络配置

服务默认监听端口 `18060`，可在 docker-compose.yml 中修改：

```yaml
ports:
  - "18060:18060"  # 宿主机端口:容器端口
```

## 🚀 生产部署

### 使用外部代理

如果需要使用代理服务器：

```yaml
environment:
  - HTTP_PROXY=http://your-proxy:port
  - HTTPS_PROXY=http://your-proxy:port
```

### 资源限制

为生产环境添加资源限制：

```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 4G
    reservations:
      cpus: '0.5'
      memory: 1G
```

### 日志管理

配置日志轮转：

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

## 🔍 故障排除

### 常见问题

#### 1. 容器启动失败

```bash
# 查看详细日志
docker-compose logs xiaohongshu-mcp

# 检查资源使用
docker stats
```

#### 2. 浏览器相关错误

```bash
# 确保共享内存足够大
# 在 docker-compose.yml 中设置
shm_size: 2gb
```

#### 3. 权限问题

```bash
# 检查卷权限
docker-compose exec xiaohongshu-mcp ls -la /app/

# 修复权限
docker-compose exec xiaohongshu-mcp chown -R app:app /app/
```

#### 4. 网络连接问题

```bash
# 测试容器网络
docker-compose exec xiaohongshu-mcp ping baidu.com

# 检查代理设置
docker-compose exec xiaohongshu-mcp env | grep -i proxy
```

### 调试模式

启用调试模式：

```bash
# 临时启动带调试的容器
docker-compose run --rm xiaohongshu-mcp ./xiaohongshu-mcp -headless=false
```

## 📚 相关命令

```bash
# 重启服务
docker-compose restart xiaohongshu-mcp

# 重新构建并启动
docker-compose up -d --build

# 停止服务
docker-compose down

# 完全清理（包括卷）
docker-compose down -v

# 查看资源使用
docker-compose exec xiaohongshu-mcp top

# 进入容器 shell
docker-compose exec xiaohongshu-mcp bash
```

## 🔗 相关链接

- [主项目文档](./README.md)
- [MCP 接入指南](./MCP_README.md)
- [Claude 接入指南](./CLAUDE.md)
