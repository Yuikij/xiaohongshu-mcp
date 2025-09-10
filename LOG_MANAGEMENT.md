# 📋 日志管理策略

xiaohongshu-mcp 项目的完整日志管理解决方案。

## 🎯 问题现状

你观察到的问题：
```
健康检查每30秒执行一次 → 大量重复日志
[GIN] 2025/09/09 - 17:00:18 | 200 | 326.393µs | 127.0.0.1 | GET "/health"
[GIN] 2025/09/09 - 17:00:49 | 200 | 147.69µs | 127.0.0.1 | GET "/health"
```

## 🔧 已实施的解决方案

### 1. Docker 日志轮转配置

#### 开发环境 (`docker-compose.yml`)
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "5m"        # 每个日志文件最大 5MB
    max-file: "5"         # 最多保留 5 个文件
    compress: "true"      # 压缩旧日志文件
```

#### 生产环境 (`docker-compose.prod.yml`)
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "20m"       # 每个日志文件最大 20MB
    max-file: "10"        # 最多保留 10 个文件
    compress: "true"      # 压缩旧日志文件
    labels: "service,environment"
```

### 2. 健康检查频率优化

#### 修改前
```yaml
interval: 30s    # 每30秒检查 → 过于频繁
```

#### 修改后
```yaml
# 开发环境
interval: 2m     # 每2分钟检查

# 生产环境  
interval: 1m     # 每1分钟检查
```

### 3. 日志存储空间计算

#### 开发环境
- 每个文件: 5MB
- 文件数量: 5个
- 总空间: 25MB

#### 生产环境
- 每个文件: 20MB
- 文件数量: 10个
- 总空间: 200MB

## 📊 日志量对比

### 优化前（30秒健康检查）
```
健康检查日志/小时: 120条
健康检查日志/天: 2,880条
预估日志文件大小/天: ~50MB
```

### 优化后（2分钟健康检查）
```
健康检查日志/小时: 30条
健康检查日志/天: 720条  
预估日志文件大小/天: ~15MB
```

**减少量: 75% 的健康检查日志**

## 🛠️ 日志管理命令

### 查看当前日志
```bash
# 查看实时日志
docker compose logs -f xiaohongshu-mcp

# 查看最近100行
docker compose logs --tail=100 xiaohongshu-mcp

# 查看特定时间段
docker compose logs --since="1h" xiaohongshu-mcp
```

### 日志文件位置
```bash
# Docker 日志文件位置
/var/lib/docker/containers/<container_id>/<container_id>-json.log*

# 查看日志文件大小
docker compose exec xiaohongshu-mcp du -sh /var/log/
```

### 清理日志
```bash
# 清理所有 Docker 日志
docker system prune --volumes

# 手动清理特定容器日志
docker logs xiaohongshu-mcp > /dev/null 2>&1
```

## 🔍 日志监控

### 检查日志轮转状态
```bash
# 查看当前日志文件
ls -la /var/lib/docker/containers/$(docker compose ps -q xiaohongshu-mcp)/

# 检查压缩的日志文件
ls -la /var/lib/docker/containers/$(docker compose ps -q xiaohongshu-mcp)/*.gz
```

### 监控日志大小
```bash
# 实时监控日志大小
watch -n 60 'docker compose logs --tail=1 xiaohongshu-mcp | wc -l'

# 查看容器日志统计
docker stats xiaohongshu-mcp --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

## 🚨 高级日志管理

### 1. 使用 logrotate（宿主机级别）

创建 `/etc/logrotate.d/docker-xiaohongshu`:
```bash
/var/lib/docker/containers/*/xiaohongshu*-json.log {
    daily
    rotate 7
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
}
```

### 2. 集中日志收集（可选）

#### ELK Stack 配置
```yaml
# 在 docker-compose.prod.yml 中添加
logging:
  driver: "fluentd"
  options:
    fluentd-address: localhost:24224
    tag: xiaohongshu-mcp
```

#### Loki + Grafana 配置
```yaml
logging:
  driver: "loki"
  options:
    loki-url: "http://localhost:3100/loki/api/v1/push"
    labels: "service=xiaohongshu-mcp"
```

### 3. 日志过滤脚本

创建 `filter-logs.sh`:
```bash
#!/bin/bash
# 过滤掉健康检查日志
docker compose logs xiaohongshu-mcp | grep -v "GET.*health" | grep -v "200.*health"
```

## 📈 性能影响

### 日志 I/O 优化
- **压缩**: 减少70%磁盘空间
- **轮转**: 避免单文件过大影响性能
- **频率控制**: 减少75%无意义日志

### 监控建议
1. **磁盘空间**: 定期检查 `/var/lib/docker` 使用量
2. **日志解析**: 使用结构化日志便于分析
3. **告警设置**: 日志错误自动通知

## 🔄 重新应用配置

### 开发环境
```bash
# 停止服务
docker compose down

# 重新启动（应用新的日志配置）
docker compose up -d

# 验证配置
docker inspect xiaohongshu-mcp | grep -A 10 "LogConfig"
```

### 生产环境
```bash
# 更新生产配置
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

# 检查日志轮转是否生效
docker compose -f docker-compose.prod.yml logs --tail=50 xiaohongshu-mcp
```

## ✅ 验证清单

- [ ] 健康检查频率已降低到2分钟
- [ ] 日志文件大小限制已配置
- [ ] 日志轮转已启用
- [ ] 压缩已启用
- [ ] 最大文件数已设置
- [ ] 容器重启后配置生效

现在你的日志应该更加可控，不会无限增长了！🎉
