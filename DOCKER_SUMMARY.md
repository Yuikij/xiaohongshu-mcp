# Docker 化部署总结

本文档总结了为 xiaohongshu-mcp 项目创建的所有 Docker 相关文件和配置。

## 📁 创建的文件列表

### 核心 Docker 文件
1. **`Dockerfile`** - 主 Docker 镜像构建文件
2. **`docker-compose.yml`** - 开发环境容器编排配置
3. **`docker-compose.prod.yml`** - 生产环境容器编排配置
4. **`.dockerignore`** - Docker 构建忽略文件

### 辅助脚本
5. **`docker-entrypoint.sh`** - 容器启动入口脚本
6. **`deploy.sh`** - Linux/Mac 部署脚本
7. **`deploy.bat`** - Windows 部署脚本
8. **`Makefile`** - 便捷操作命令集合

### 文档
9. **`README_Docker.md`** - 详细的 Docker 部署指南
10. **`DOCKER_SUMMARY.md`** - 本总结文档

## 🐳 Dockerfile 特性

### 多阶段构建
- **构建阶段**: 使用 `golang:1.23.5-alpine` 编译 Go 应用
- **运行阶段**: 使用 `ghcr.io/browserless/chromium:latest` 提供优化的 Chromium 环境

### 关键特性
- ✅ **专业 Chromium 环境**: 使用 browserless/chromium 专业镜像
- ✅ **优化性能**: 针对无头浏览器场景优化
- ✅ **预配置依赖**: 所有 Chrome 依赖已预安装
- ✅ **时区配置**: 默认设置为 Asia/Shanghai
- ✅ **健康检查**: 内置健康检查机制
- ✅ **安全配置**: 使用非 root 用户运行
- ✅ **稳定性**: 基于经过验证的浏览器镜像

### Browserless 镜像优势
- 🚀 **专业化**: 专门为自动化浏览器任务设计
- 🔧 **预优化**: 内置性能优化和稳定性改进
- 📦 **完整性**: 包含所有必需的字体和库
- 🛡️ **安全性**: 定期更新，修复安全漏洞
- 💾 **体积优化**: 虽然较大但包含完整功能

### 环境要求
- **共享内存**: 2GB (Chrome 需要)
- **端口**: 18060
- **存储**: 持久化 cookies 和数据

## 🔧 Docker Compose 配置

### 开发环境 (`docker-compose.yml`)
```yaml
特点:
- 基础配置，适合开发和测试
- 本地数据卷
- 简化的日志配置
- 快速启动和调试
```

### 生产环境 (`docker-compose.prod.yml`)
```yaml
特点:
- 资源限制 (CPU: 2核, 内存: 4GB)
- 绑定挂载到 /opt/xiaohongshu-mcp
- 高级日志轮转配置
- 自定义网络配置
- 监控就绪配置
```

## 🚀 快速开始

### 1. 开发环境部署
```bash
# Linux/Mac
./deploy.sh dev

# Windows
deploy.bat dev

# 或使用 Make
make dev
```

### 2. 生产环境部署
```bash
# Linux/Mac
./deploy.sh prod

# Windows
deploy.bat prod

# 或使用 Make
make prod
```

### 3. 常用操作
```bash
# 查看日志
make logs

# 健康检查
make health

# 重启服务
make restart

# 进入容器
make shell

# 清理资源
make clean
```

## 📋 部署检查清单

### 首次部署前
- [ ] 确认 Docker 和 Docker Compose 已安装
- [ ] 检查端口 18060 未被占用
- [ ] 确保有足够的磁盘空间 (至少 4GB)

### 部署后验证
- [ ] 容器启动成功: `docker-compose ps`
- [ ] 健康检查通过: `curl http://localhost:18060/health`
- [ ] MCP 端点可访问: `curl http://localhost:18060/mcp`
- [ ] 日志无错误: `docker-compose logs`

### 生产环境额外检查
- [ ] 数据目录权限正确: `/opt/xiaohongshu-mcp`
- [ ] 资源监控配置
- [ ] 备份策略就位
- [ ] 网络安全配置

## 🔍 故障排除

### 常见问题和解决方案

#### 1. 容器启动失败
```bash
# 检查日志
docker-compose logs xiaohongshu-mcp

# 检查资源
docker stats

# 重新构建
docker-compose up -d --build --force-recreate
```

#### 2. Chromium 相关错误
```bash
# 确保共享内存足够
shm_size: 2gb

# 检查安全选项
security_opt:
  - seccomp:unconfined
```

#### 3. 权限问题
```bash
# 修复数据目录权限
sudo chown -R 1000:1000 /opt/xiaohongshu-mcp

# 或在容器内
docker-compose exec xiaohongshu-mcp chown -R app:app /app/
```

#### 4. 网络连接问题
```bash
# 测试网络
docker-compose exec xiaohongshu-mcp ping baidu.com

# 检查代理设置
docker-compose exec xiaohongshu-mcp env | grep -i proxy
```

## 🔐 安全考虑

### 容器安全
- 使用非 root 用户运行应用
- 限制容器权限
- 定期更新基础镜像

### 数据安全
- cookies 数据加密存储
- 定期备份重要数据
- 访问权限控制

### 网络安全
- 仅暴露必要端口
- 使用内部网络通信
- 配置防火墙规则

## 📊 监控和维护

### 日志管理
```bash
# 查看实时日志
make logs

# 日志轮转配置在 docker-compose.prod.yml
logging:
  options:
    max-size: "50m"
    max-file: "5"
```

### 资源监控
```bash
# 查看资源使用
make stats

# 容器健康状态
docker-compose ps
```

### 备份策略
```bash
# 备份 cookies
make backup

# 恢复 cookies
make restore BACKUP_DIR=./backup/cookies-20231201-120000
```

## 🎯 最佳实践

1. **定期更新**: 保持基础镜像和依赖最新
2. **监控资源**: 定期检查 CPU、内存和磁盘使用
3. **备份数据**: 定期备份 cookies 和重要配置
4. **日志管理**: 配置适当的日志轮转和保留策略
5. **安全审计**: 定期检查容器和镜像安全性

## 📞 支持

如果遇到问题，请：
1. 查看详细文档 `README_Docker.md`
2. 检查项目主文档 `README.md`
3. 查看 MCP 接入指南 `MCP_README.md`
4. 提交 GitHub Issue

---

**注意**: 这是一个自动化的小红书操作工具，请遵守相关服务条款和法律法规，仅用于学习和个人使用。
