# HTTPS证书生成脚本使用指南

本目录包含了多个用于生成HTTPS证书的脚本，适用于不同的使用场景。

## 脚本说明

### 1. `generate-cert.sh` - 完整CA和服务器证书
生成CA根证书和由CA签名的服务器证书，适合需要证书链验证的场景。

```bash
# 基本用法
./generate-cert.sh

# 指定域名/IP和有效期
./generate-cert.sh 192.168.1.100 730

# 只生成自签名服务器证书（不生成CA）
./generate-cert.sh 192.168.1.100 365 false
```

**生成的文件：**
- `ca-key.pem` - CA私钥
- `ca-cert.pem` - CA根证书
- `server-key.pem` - 服务器私钥
- `server-cert.pem` - 服务器证书

### 2. `generate-dev-cert.sh` - 快速开发证书
快速生成用于开发环境的自签名证书，配置简单。

```bash
# 使用默认IP
./generate-dev-cert.sh

# 指定IP地址
./generate-dev-cert.sh 192.168.2.38
```

**生成的文件：**
- `dev-key.pem` - 开发环境私钥
- `dev-cert.pem` - 开发环境证书

### 3. `generate-full-chain.sh` - 完整证书链
生成包含根CA、中间CA和服务器证书的完整证书链，最接近生产环境。

```bash
# 基本用法
./generate-full-chain.sh

# 指定域名和有效期
./generate-full-chain.sh example.com 365
```

**生成的文件：**
- `root-ca-key.pem` - 根CA私钥
- `root-ca-cert.pem` - 根CA证书
- `intermediate-ca-key.pem` - 中间CA私钥
- `intermediate-ca-cert.pem` - 中间CA证书
- `server-key.pem` - 服务器私钥
- `server-cert.pem` - 服务器证书
- `cert-chain.pem` - 完整证书链文件

## 使用场景推荐

### 开发环境
推荐使用 `generate-dev-cert.sh`：
```bash
./generate-dev-cert.sh 192.168.2.38
```

### 测试环境
推荐使用 `generate-cert.sh`：
```bash
./generate-cert.sh test.example.com 365 true
```

### 生产环境模拟
推荐使用 `generate-full-chain.sh`：
```bash
./generate-full-chain.sh prod.example.com 365
```

## 在HarmonyOS WebServer中使用

### 基本用法
```typescript
import { CertificateManager, TLSServer } from '@your-package/webserver';

// 加载证书
const tlsOptions = await CertificateManager.loadFromFiles(
  'server-key.pem',
  'server-cert.pem',
  'ca-cert.pem'  // 可选，如果有CA证书
);

// 创建HTTPS服务器
const httpsServer = new TLSServer(tlsOptions);
await httpsServer.startServer(8443);
```

### 开发环境快速启动
```typescript
// 使用开发证书
const tlsOptions = await CertificateManager.loadFromFiles(
  'dev-key.pem',
  'dev-cert.pem'
);

const httpsServer = new TLSServer(tlsOptions);
httpsServer.get('/', (req, res) => {
  res.json({ message: 'Hello HTTPS!', secure: true });
});

await httpsServer.startServer(8443);
```

## 证书验证

### 验证证书内容
```bash
# 查看证书详细信息
openssl x509 -in server-cert.pem -text -noout

# 验证证书链
openssl verify -CAfile ca-cert.pem server-cert.pem

# 检查私钥和证书是否匹配
openssl x509 -noout -modulus -in server-cert.pem | openssl md5
openssl rsa -noout -modulus -in server-key.pem | openssl md5
```

### 测试HTTPS连接
```bash
# 使用curl测试（忽略证书验证）
curl -k -v https://192.168.2.38:8443/

# 使用curl测试（指定CA证书）
curl --cacert ca-cert.pem https://192.168.2.38:8443/
```

## 客户端配置

### 浏览器访问
1. **自签名证书**：浏览器会显示安全警告，需要手动信任
2. **CA签名证书**：需要将CA证书添加到系统受信任根证书存储

## 安全注意事项

1. **私钥保护**：私钥文件权限应设置为600（仅所有者可读写）
2. **证书有效期**：定期更新证书，避免过期
3. **生产环境**：使用受信任的CA签发的证书，不要使用自签名证书
4. **密钥强度**：使用至少2048位RSA密钥，推荐4096位
5. **协议版本**：只启用TLS 1.2和TLS 1.3

## 故障排除

### 常见错误
1. **证书格式错误**：确保证书文件包含正确的PEM格式头部和尾部
2. **私钥不匹配**：验证私钥和证书是否匹配
3. **权限问题**：检查文件权限设置
4. **路径问题**：确保证书文件路径正确

### 调试命令
```bash
# 检查证书有效期
openssl x509 -in server-cert.pem -noout -dates

# 检查证书主题和SAN
openssl x509 -in server-cert.pem -noout -subject -ext subjectAltName

# 测试私钥
openssl rsa -in server-key.pem -check
```