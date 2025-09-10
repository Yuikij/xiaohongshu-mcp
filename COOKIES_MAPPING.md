# 🍪 Cookies 路径映射指南

本文档详细说明了 xiaohongshu-mcp 项目中 cookies 的存储路径和 Docker 映射配置。

## 📁 Cookies 存储路径分析

### 代码中的路径逻辑

在 `cookies/cookies.go` 中，cookies 文件路径由以下函数决定：

```go
func GetCookiesFilePath() string {
    tmpDir := os.TempDir()
    filePath := filepath.Join(tmpDir, "cookies.json")
    return filePath
}
```

### 不同系统的实际路径

| 系统 | `os.TempDir()` 返回值 | Cookies 文件路径 |
|------|----------------------|------------------|
| **Linux 容器** | `/tmp` | `/tmp/cookies.json` |
| **Windows** | `C:\Users\用户名\AppData\Local\Temp` | `C:\Users\用户名\AppData\Local\Temp\cookies.json` |
| **macOS** | `/tmp` | `/tmp/cookies.json` |
| **Linux 宿主机** | `/tmp` | `/tmp/cookies.json` |

## 🐳 Docker 映射配置

### 当前配置（已修正）

```yaml
# docker-compose.yml
volumes:
  # 正确：映射到容器的临时目录
  - xiaohongshu_cookies:/tmp
  - xiaohongshu_data:/app/data
```

### 为什么映射 `/tmp` 而不是 `/app/cookies`？

1. **代码逻辑**: `os.TempDir()` 在 Linux 容器中返回 `/tmp`
2. **实际存储**: cookies.json 文件保存在 `/tmp/cookies.json`
3. **权限管理**: `/tmp` 目录通常有正确的读写权限

## 📂 目录结构

### 容器内部结构
```
/tmp/
└── cookies.json          # 登录状态数据

/app/
├── xiaohongshu-mcp       # 主程序
├── docker-entrypoint.sh  # 启动脚本
└── data/                 # 其他数据
```

### 宿主机映射
```
# 开发环境
xiaohongshu_cookies volume -> /tmp/cookies.json

# 生产环境
/opt/xiaohongshu-mcp/cookies/ -> /tmp/cookies.json
```

## 🔄 Cookies 生命周期

### 1. 首次登录
```bash
# 在宿主机运行登录（推荐）
go run cmd/login/main.go

# cookies 保存到：
# Windows: C:\Users\用户名\AppData\Local\Temp\cookies.json
# Linux: /tmp/cookies.json
```

### 2. 容器启动
```bash
# 容器启动时自动加载 cookies
# 从: /tmp/cookies.json
# 通过: browser.NewBrowser() -> cookies.GetCookiesFilePath()
```

### 3. 持久化存储
```bash
# Docker volume 确保数据持久化
# 即使容器重启，cookies 也不会丢失
```

## 🛠️ 管理命令

### 备份 Cookies
```bash
# 备份当前 cookies
make backup

# 备份文件位置: ./backup/cookies-20231201-120000.json
```

### 恢复 Cookies
```bash
# 恢复指定备份
make restore BACKUP_FILE=./backup/cookies-20231201-120000.json
```

### 查看 Cookies
```bash
# 进入容器查看
docker compose exec xiaohongshu-mcp cat /tmp/cookies.json

# 或查看 volume 内容
docker compose exec xiaohongshu-mcp ls -la /tmp/
```

## 🔍 故障排除

### 1. Cookies 文件不存在
```bash
# 检查文件是否存在
docker compose exec xiaohongshu-mcp ls -la /tmp/cookies.json

# 如果不存在，需要重新登录
go run cmd/login/main.go
```

### 2. 权限问题
```bash
# 检查权限
docker compose exec xiaohongshu-mcp ls -la /tmp/

# 修复权限
docker compose exec xiaohongshu-mcp chown 1000:1000 /tmp/cookies.json
```

### 3. 登录状态丢失
```bash
# 检查 cookies 内容
docker compose exec xiaohongshu-mcp cat /tmp/cookies.json

# 重新登录
go run cmd/login/main.go

# 重启容器
docker compose restart xiaohongshu-mcp
```

### 4. 宿主机和容器路径不一致
```bash
# 错误配置示例
volumes:
  - ./cookies:/app/cookies  # ❌ 错误：应用不会在这里查找

# 正确配置
volumes:
  - xiaohongshu_cookies:/tmp  # ✅ 正确：映射到临时目录
```

## 📊 迁移指南

### 从旧配置迁移

如果你之前使用了错误的路径映射：

```bash
# 1. 停止服务
docker compose down

# 2. 备份旧数据（如果有）
docker cp old_container:/app/cookies ./backup-old/

# 3. 使用新配置启动
docker compose up -d

# 4. 恢复 cookies（如果需要）
docker cp ./backup-old/cookies.json $(docker compose ps -q xiaohongshu-mcp):/tmp/
```

## 🎯 最佳实践

1. **首次部署**: 先在宿主机完成登录，再启动容器
2. **定期备份**: 使用 `make backup` 定期备份 cookies
3. **权限检查**: 确保容器用户对 `/tmp` 目录有读写权限
4. **监控日志**: 关注登录相关的错误日志
5. **版本控制**: 不要将 cookies 文件提交到 Git

现在 cookies 映射已经正确配置！🎉
