# 🚀 代理加速构建指南

由于网络原因，Docker 构建可能会很慢。本指南提供了多种加速方案。

## 🎯 快速解决方案

### 方法1：使用构建脚本（推荐）

```bash
# 设置执行权限
chmod +x build-with-proxy.sh

# 使用默认代理构建
./build-with-proxy.sh

# 使用自定义代理构建
./build-with-proxy.sh http://your-proxy:port
```

### 方法2：使用 Make 命令

```bash
# 使用代理构建
make build-proxy

# 使用代理重新构建并启动
make rebuild-proxy
```

### 方法3：直接 Docker 命令

```bash
# 单次构建
docker build \
    --build-arg HTTP_PROXY=http://172.23.104.184:7890 \
    --build-arg HTTPS_PROXY=http://172.23.104.184:7890 \
    -t xiaohongshu-mcp:latest .
```

## 🔧 配置说明

### Dockerfile 中的优化

我们在 Dockerfile 中添加了以下优化：

1. **Alpine 镜像源替换**
   ```dockerfile
   RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
   ```

2. **Go 模块代理**
   ```dockerfile
   ENV GOPROXY=https://goproxy.cn,direct
   ENV GOSUMDB=sum.golang.google.cn
   ```

3. **代理参数支持**
   ```dockerfile
   ARG HTTP_PROXY
   ARG HTTPS_PROXY
   ENV http_proxy=${HTTP_PROXY}
   ENV https_proxy=${HTTPS_PROXY}
   ```

### 常用代理地址

根据你的网络环境选择：

```bash
# 本地代理（你当前使用的）
http://172.23.104.184:7890

# 其他常见代理端口
http://127.0.0.1:7890   # 本机代理
http://127.0.0.1:1080   # Shadowsocks
http://127.0.0.1:8080   # HTTP 代理
```

## 📊 性能对比

### 不使用代理
```
Alpine 包下载: ~20 分钟
Go 模块下载: ~10 分钟
总构建时间: ~30 分钟
```

### 使用代理 + 国内镜像
```
Alpine 包下载: ~1 分钟
Go 模块下载: ~2 分钟  
总构建时间: ~5 分钟
```

## 🛠️ 故障排除

### 1. 代理连接失败

```bash
# 测试代理连接
curl -x http://172.23.104.184:7890 https://www.google.com

# 如果失败，检查：
- 代理服务是否正常运行
- 防火墙设置
- 网络连接
```

### 2. Docker 构建仍然缓慢

```bash
# 清理 Docker 构建缓存
docker builder prune

# 强制重新构建
docker build --no-cache \
    --build-arg HTTP_PROXY=http://172.23.104.184:7890 \
    --build-arg HTTPS_PROXY=http://172.23.104.184:7890 \
    -t xiaohongshu-mcp:latest .
```

### 3. Go 模块下载失败

```bash
# 在构建前设置环境变量
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn

# 然后构建
make build-proxy
```

## 🌐 其他加速方案

### Docker Hub 镜像加速

在 `/etc/docker/daemon.json` 中配置：

```json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
```

### Go 模块镜像

```bash
# 七牛云
export GOPROXY=https://goproxy.cn

# 阿里云
export GOPROXY=https://mirrors.aliyun.com/goproxy/

# 官方代理
export GOPROXY=https://proxy.golang.org
```

## 🎯 最佳实践

1. **首次构建**: 使用 `make build-proxy`
2. **后续构建**: 使用 `make build`（利用缓存）
3. **网络问题**: 切换不同代理地址
4. **完全重建**: 使用 `docker build --no-cache`

现在你可以快速构建了！🚀
