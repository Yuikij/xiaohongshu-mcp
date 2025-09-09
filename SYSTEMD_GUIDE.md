# Xiaohongshu MCP Systemd 服务管理指南

## 快速安装

1. **确保你在项目根目录** (`/home/shiori/mcp/xiaohongshu-mcp/`)

2. **给安装脚本执行权限并运行**:
   ```bash
   chmod +x install-service.sh
   sudo ./install-service.sh
   ```

## 服务管理命令

### 基本操作
```bash
# 查看服务状态
sudo systemctl status xiaohongshu-mcp

# 启动服务
sudo systemctl start xiaohongshu-mcp

# 停止服务  
sudo systemctl stop xiaohongshu-mcp

# 重启服务
sudo systemctl restart xiaohongshu-mcp

# 重新加载配置
sudo systemctl reload xiaohongshu-mcp
```

### 开机自启动
```bash
# 启用开机自启动
sudo systemctl enable xiaohongshu-mcp

# 禁用开机自启动
sudo systemctl disable xiaohongshu-mcp
```

### 日志查看
```bash
# 查看实时日志
sudo journalctl -u xiaohongshu-mcp -f

# 查看最近的日志
sudo journalctl -u xiaohongshu-mcp -n 50

# 查看今天的日志
sudo journalctl -u xiaohongshu-mcp --since today

# 查看指定时间的日志
sudo journalctl -u xiaohongshu-mcp --since "2024-01-01 10:00:00"
```

## 服务配置说明

### 服务文件位置
- 配置文件: `/etc/systemd/system/xiaohongshu-mcp.service`
- 应用目录: `/home/shiori/mcp/xiaohongshu-mcp/`
- 二进制文件: `/home/shiori/mcp/xiaohongshu-mcp/xiaohongshu-mcp`

### 服务配置参数
- **端口**: 18060
- **用户**: shiori
- **工作目录**: `/home/shiori/mcp/xiaohongshu-mcp/`
- **启动参数**: `-headless=true`
- **环境变量**: `GIN_MODE=release`

### 重要特性
- **自动重启**: 服务异常退出时会自动重启
- **重启间隔**: 5秒
- **日志记录**: 所有输出都会记录到系统日志
- **安全设置**: 包含多项安全加固配置

## 故障排查

### 服务无法启动
1. 检查服务状态和错误信息:
   ```bash
   sudo systemctl status xiaohongshu-mcp
   sudo journalctl -u xiaohongshu-mcp -n 20
   ```

2. 检查二进制文件是否存在和有执行权限:
   ```bash
   ls -la /home/shiori/mcp/xiaohongshu-mcp/xiaohongshu-mcp
   ```

3. 手动测试应用是否能正常运行:
   ```bash
   cd /home/shiori/mcp/xiaohongshu-mcp/
   ./xiaohongshu-mcp -headless=true
   ```

### 端口被占用
检查端口18060是否被其他程序占用:
```bash
sudo netstat -tlnp | grep 18060
# 或
sudo ss -tlnp | grep 18060
```

### 权限问题
确保shiori用户对应用目录有适当权限:
```bash
sudo chown -R shiori:shiori /home/shiori/mcp/xiaohongshu-mcp/
```

## 手动配置 (高级用户)

如果不想使用安装脚本，可以手动配置:

1. **编译应用**:
   ```bash
   cd /home/shiori/mcp/xiaohongshu-mcp/
   go build -o xiaohongshu-mcp .
   ```

2. **复制服务文件**:
   ```bash
   sudo cp xiaohongshu-mcp.service /etc/systemd/system/
   ```

3. **启用并启动服务**:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable xiaohongshu-mcp
   sudo systemctl start xiaohongshu-mcp
   ```

## 卸载服务

如需完全移除服务:
```bash
chmod +x uninstall-service.sh
sudo ./uninstall-service.sh
```

## 访问应用

服务启动后，应用将在以下地址运行:
- **HTTP**: http://localhost:18060
- **HTTP (外部访问)**: http://your-server-ip:18060

确保防火墙允许18060端口的访问 (如果需要外部访问)。
