# HTTPS证书生成脚本使用指南

本目录包含了用于生成HTTPS证书的脚本工具，支持开发环境和生产环境的不同需求。

## 📁 脚本文件说明

| 脚本文件 | 用途 | 适用场景 |
|---------|------|----------|
| `generate-dev-cert.sh` | 快速生成开发证书 | 开发测试环境 |
| `generate-cert.sh` | 生成完整证书链 | 开发和生产环境 |
| `generate-full-chain.sh` | 生成三级证书链 | 企业级生产环境 |

## 🚀 快速开始

### 1. 开发环境快速证书生成

最简单的方式，一键生成自签名证书：

```bash
cd scripts
./generate-dev-cert.sh 192.168.2.38
```

生成文件：
- `dev-key.pem` - 私钥文件
- `dev-cert.pem` - 证书文件

### 2. 标准证书链生成

生成包含CA的完整证书链：

```bash
cd scripts
./generate-cert.sh example.com 365 true
```

参数说明：
- `example.com` - 域名或IP地址
- `365` - 证书有效期（天）
- `true` - 是否生成CA证书

生成文件：
- `ca-key.pem` - CA私钥
- `ca-cert.pem` - CA证书
- `server-key.pem` - 服务器私钥
- `server-cert.pem` - 服务器证书

### 3. 企业级三级证书链

生成根CA、中间CA和服务器证书的完整链：

```bash
cd scripts
./generate-full-chain.sh example.com 365
```

## 📋 详细使用说明

### generate-dev-cert.sh

**用法：**
```bash
./generate-dev-cert.sh [IP地址]
```

**示例：**
```bash
# 使用默认IP
./generate-dev-cert.sh

# 指定IP地址
./generate-dev-cert.sh 192.168.1.100

# 使用域名
./generate-dev-cert.sh localhost
```

**特点：**
- 一步生成，无需交互
- 自动配置SAN扩展
- 包含常用的IP和域名
- 适合快速开发测试

### generate-cert.sh

**用法：**
```bash
./generate-cert.sh [域名] [有效期天数] [是否生成CA]
```

**示例：**
```bash
# 生成完整CA证书链
./generate-cert.sh example.com 365 true

# 只生成自签名服务器证书
./generate-cert.sh example.com 365 false

# 使用默认参数
./generate-cert.sh
```

**特点：**
- 支持CA证书链
- 可配置证书有效期
- 支持多域名和IP
- 自动验证证书链

### generate-full-chain.sh

**用法：**
```bash
./generate-full-chain.sh [域名] [有效期天数]
```

**示例：**
```bash
# 生成三级证书链
./generate-full-chain.sh company.com 730

# 使用默认参数
./generate-full-chain.sh
```

**特点：**
- 三级证书链结构
- 企业级安全标准
- 完整的证书验证链
- 适合生产环境部署

## 🔧 证书配置

### 在代码中使用证书

```typescript
// 使用开发证书
const tlsOptions = await CertificateManager.loadFromFiles(
  'scripts/dev-key.pem',
  'scripts/dev-cert.pem'
);

// 使用CA签名证书
const tlsOptions = await CertificateManager.loadFromFiles(
  'scripts/server-key.pem',
  'scripts/server-cert.pem',
  'scripts/ca-cert.pem'
);
```

### 证书文件权限设置

脚本会自动设置正确的文件权限：
- 私钥文件：`600` (仅所有者可读写)
- 证书文件：`644` (所有者可读写，其他人只读)

## 🔍 证书验证

### 验证证书有效性

```bash
# 检查证书内容
openssl x509 -in server-cert.pem -text -noout

# 验证私钥和证书匹配
openssl x509 -noout -modulus -in server-cert.pem | openssl md5
openssl rsa -noout -modulus -in server-key.pem | openssl md5

# 验证证书链
openssl verify -CAfile ca-cert.pem server-cert.pem
```

### 测试SSL连接

```bash
# 测试SSL握手
openssl s_client -connect localhost:8443 -servername localhost

# 测试特定TLS版本
openssl s_client -connect localhost:8443 -tls1_2
openssl s_client -connect localhost:8443 -tls1_3
```

## 🌐 客户端配置

### 浏览器访问

1. **自签名证书：**
   - 浏览器会显示安全警告
   - 点击"高级" → "继续访问"
   - 或将CA证书添加到受信任根证书

2. **CA签名证书：**
   - 将`ca-cert.pem`导入浏览器受信任根证书
   - 或系统级证书存储

### 程序访问

```bash
# 忽略证书验证（仅开发环境）
curl -k https://localhost:8443/api/ssl/info

# 使用CA证书验证
curl --cacert ca-cert.pem https://localhost:8443/api/ssl/info

# 使用客户端证书认证
curl --cert client.pem --key client-key.pem https://localhost:8443/api/secure/users
```

## 📚 证书类型对比

| 证书类型 | 安全级别 | 部署复杂度 | 适用场景 | 浏览器信任 |
|---------|----------|------------|----------|------------|
| 自签名 | 中等 | 简单 | 开发测试 | 需要手动信任 |
| CA签名 | 高 | 中等 | 内部系统 | 需要导入CA |
| 商业证书 | 最高 | 复杂 | 公网服务 | 自动信任 |

## 🛠️ 故障排除

### 常见问题

1. **权限错误**
   ```bash
   chmod +x *.sh
   ```

2. **OpenSSL未安装**
   ```bash
   # macOS
   brew install openssl
   
   # Ubuntu/Debian
   sudo apt-get install openssl
   
   # CentOS/RHEL
   sudo yum install openssl
   ```

3. **证书格式错误**
   - 确保使用PEM格式
   - 检查文件编码为UTF-8
   - 验证文件完整性

4. **域名不匹配**
   - 检查证书SAN扩展
   - 确认域名或IP正确
   - 重新生成匹配的证书

### 调试命令

```bash
# 查看证书详细信息
openssl x509 -in cert.pem -text -noout

# 检查私钥
openssl rsa -in key.pem -check

# 验证证书和私钥匹配
diff <(openssl x509 -noout -modulus -in cert.pem) <(openssl rsa -noout -modulus -in key.pem)

# 检查证书链
openssl crl2pkcs7 -nocrl -certfile cert-chain.pem | openssl pkcs7 -print_certs -noout
```

## 🔐 安全最佳实践

1. **私钥保护**
   - 设置正确的文件权限
   - 不要将私钥提交到版本控制
   - 定期轮换证书

2. **证书管理**
   - 监控证书过期时间
   - 建立证书更新流程
   - 备份重要证书文件

3. **生产环境**
   - 使用商业SSL证书
   - 启用HSTS头部
   - 配置强加密套件

4. **开发环境**
   - 使用自签名证书
   - 不要在生产环境使用开发证书
   - 定期更新开发证书

## 📖 相关文档

- [OpenSSL官方文档](https://www.openssl.org/docs/)
- [SSL/TLS最佳实践](https://wiki.mozilla.org/Security/Server_Side_TLS)