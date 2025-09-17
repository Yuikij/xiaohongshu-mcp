# 使用官方 Go 镜像作为构建阶段
FROM golang:1.23.5-alpine AS builder

# 设置工作目录
WORKDIR /app

# 配置 Alpine 镜像源和代理（加速下载）
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}

# 使用国内镜像源加速 apk 下载
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

# 安装构建依赖
RUN apk add --no-cache git ca-certificates tzdata

# 复制 go.mod 和 go.sum
COPY go.mod go.sum ./

# 配置 Go 模块代理（加速 Go 包下载）
ENV GOPROXY=https://goproxy.cn,direct
ENV GOSUMDB=sum.golang.google.cn

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o xiaohongshu-mcp .

# 使用 Browserless Chromium 镜像作为运行阶段
FROM ghcr.io/browserless/chromium:latest

# 设置工作目录
WORKDIR /app

# 切换到 root 用户进行安装
USER root

# 安装必要的系统包（browserless 镜像已包含大部分依赖）
RUN apt-get update && apt-get install -y \
    ca-certificates \
    tzdata \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 设置时区为亚洲/上海
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建应用用户（如果不存在）
RUN useradd --create-home --shell /bin/bash --uid 1000 app 2>/dev/null || true

# 从构建阶段复制二进制文件
COPY --from=builder /app/xiaohongshu-mcp /app/xiaohongshu-mcp

# 复制 entrypoint 脚本
COPY docker-entrypoint.sh /app/docker-entrypoint.sh

# 创建必要的目录并设置权限
RUN mkdir -p /app/data /tmp && \
    chmod +x /app/docker-entrypoint.sh && \
    chown -R 1000:1000 /app && \
    chown -R 1000:1000 /tmp

# 切换到应用用户
USER 1000

# 设置环境变量
ENV GIN_MODE=release
ENV DISPLAY=:99

# 暴露端口
EXPOSE 18060

# 健康检查（降低频率减少日志）
# HEALTHCHECK --interval=2m --timeout=10s --start-period=60s --retries=3 \
#     CMD curl -f http://localhost:18060/health || exit 1

# 设置入口点
ENTRYPOINT ["/app/docker-entrypoint.sh"]

# 启动命令
CMD ["./xiaohongshu-mcp", "-headless=true"]
