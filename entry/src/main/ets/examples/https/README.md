# HTTPS服务器示例 - SSL/TLS加密通信

本示例专注于展示HTTPS的核心安全特性，包括SSL/TLS加密通信、数字证书验证、安全头部配置和加密数据传输。通过精简的API设计，突出HTTPS相比HTTP的安全优势。

## 📁 文件结构

```
entry/src/main/ets/examples/https/
├── HttpsExample.ets                    # HTTPS服务器核心逻辑
├── HttpsPage.ets                       # HTTPS服务器UI界面
├── test-https-api.sh                   # API测试脚本
├── scripts/                            # 证书生成脚本目录
│   ├── generate-cert.sh                # 标准证书生成
│   ├── generate-dev-cert.sh            # 开发证书快速生成
│   ├── generate-full-chain.sh          # 完整证书链生成
│   ├── dev-cert.pem                    # 开发证书文件
│   ├── dev-key.pem                     # 开发私钥文件
│   └── HTTPS证书生成脚本使用指南.md     # 证书脚本详细说明
├── HTTPS服务器使用指南.md               # 详细使用指南
└── README.md                           # 本文档
```

## 🚀 快速开始

### 1. 生成开发证书

```bash
# 进入证书脚本目录
cd scripts

# 生成开发用自签名证书
./generate-dev-cert.sh 192.168.1.100

# 将证书复制到系统临时目录
cp dev-cert.pem /data/local/tmp/
cp dev-key.pem /data/local/tmp/
```

### 2. 启动HTTPS服务器

```typescript
import { HttpsExample } from './HttpsExample';

// 创建HTTPS服务器实例
const httpsServer = new HttpsExample();

// 初始化安全配置
httpsServer.init();

// 启动服务器 (默认端口8443)
const serverInfo = await httpsServer.start(8443);
console.log(`🔒 HTTPS服务器已启动: https://${serverInfo.address}:${serverInfo.port}`);
```

### 3. 访问HTTPS服务

```bash
# 使用curl测试 (忽略证书验证)
curl -k https://192.168.1.100:8443/

# 浏览器访问 (会显示证书警告)
# 点击"高级" → "继续访问"即可
```

## 🔐 SSL证书管理

### 快速生成开发证书

```bash
# 进入脚本目录
cd scripts

# 快速生成开发证书（推荐）
./generate-dev-cert.sh 192.168.2.38

# 生成完整CA证书链
./generate-cert.sh 192.168.2.38 365 true

# 生成企业级三级证书链
./generate-full-chain.sh example.com 365
```

### 证书文件说明

| 文件 | 描述 | 用途 | 权限 |
|------|------|------|------|
| `dev-key.pem` | 开发私钥 | SSL/TLS加密 | 600 |
| `dev-cert.pem` | 开发证书 | 身份验证 | 644 |
| `server-key.pem` | 服务器私钥 | SSL/TLS加密 | 600 |
| `server-cert.pem` | 服务器证书 | 身份验证 | 644 |
| `ca-cert.pem` | CA根证书 | 证书链验证 | 644 |

## 🔒 HTTPS安全特性演示

### SSL/TLS加密特性

| 方法 | 路径 | 描述 | 安全特性 |
|------|------|------|----------|
| GET | `/` | HTTPS安全首页 | 展示加密连接状态 |
| GET | `/api/ssl/info` | SSL证书信息 | 证书详情、加密算法 |
| GET | `/api/security/headers` | 安全头部展示 | HSTS、CSP等安全头部 |

### 加密数据传输

| 方法 | 路径 | 描述 | 安全特性 |
|------|------|------|----------|
| POST | `/api/secure/data` | 敏感数据传输 | SSL/TLS端到端加密 |
| GET | `/api/secure/token` | 安全Token获取 | 基础认证+加密传输 |
| GET | `/api/secure/verify/:token` | Token验证 | 安全Token验证机制 |

### 使用示例

```bash
# 1. 查看HTTPS连接状态
curl -k https://192.168.1.100:8443/

# 2. 获取SSL证书信息
curl -k https://192.168.1.100:8443/api/ssl/info

# 3. 传输敏感数据 (加密保护)
curl -k -X POST -H "Content-Type: application/json" \
  -d '{"creditCard":"4532-1234-5678-9012","personalInfo":{"name":"张三"}}' \
  https://192.168.1.100:8443/api/secure/data

# 4. 获取安全Token
curl -k -H "Authorization: Basic ZGVtbzpzZWN1cmU=" \
  https://192.168.1.100:8443/api/secure/token

# 5. 验证Token
curl -k https://192.168.1.100:8443/api/secure/verify/YOUR_TOKEN
```

## 🛡️ HTTPS核心安全特性

### 1. SSL/TLS加密通信
- **端到端加密**: 所有数据传输均通过SSL/TLS加密
- **协议版本**: 支持TLS 1.2和TLS 1.3
- **加密算法**: AES256-GCM、ChaCha20-Poly1305
- **密钥交换**: ECDHE完美前向保密
- **数字签名**: RSA-SHA256、ECDSA-SHA256

### 2. 数字证书验证
- **X.509证书**: 标准数字证书格式
- **证书链**: 支持完整的信任链验证
- **自签名证书**: 开发环境快速部署
- **证书管理**: 安全的证书加载和存储

### 3. 安全头部防护
```typescript
// HTTPS自动配置的安全头部
'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload'  // 强制HTTPS
'Content-Security-Policy': "default-src 'self'"                              // 内容安全策略
'X-Content-Type-Options': 'nosniff'                                          // 防MIME嗅探
'X-Frame-Options': 'DENY'                                                    // 防点击劫持
'X-XSS-Protection': '1; mode=block'                                          // XSS保护
```

### 4. 数据传输安全
- **加密传输**: 敏感数据通过SSL/TLS加密传输
- **完整性校验**: 防止数据在传输过程中被篡改
- **身份验证**: 确保通信双方身份的真实性
- **防重放攻击**: 通过时间戳和随机数防止重放

### 5. 安全Token机制
- **安全生成**: 使用加密安全的随机数生成Token
- **加密传输**: Token通过HTTPS安全传输
- **有效期控制**: Token具有明确的有效期限制
- **验证机制**: 服务端安全验证Token有效性

## 🔧 配置选项

```typescript
interface HttpsServerConfig {
  port: number;              // HTTPS端口 (默认: 8443)
  staticRoot: string;        // 静态文件目录
  enableLogging: boolean;    // 启用访问日志
  enableCors: boolean;       // 启用CORS跨域
  certPath: string;          // 证书文件路径
  keyPath: string;           // 私钥文件路径
  useSelfSigned: boolean;    // 使用自签名证书
}
```

## 🌐 客户端访问

### 浏览器访问
1. 访问 `https://IP:端口`
2. 自签名证书会显示安全警告
3. 点击"高级" → "继续访问"
4. 或将CA证书添加到受信任根证书

### 程序访问
```bash
# 忽略证书验证 (仅开发环境)
curl -k https://localhost:8443/api/secure/users

# 使用CA证书验证
curl --cacert scripts/ca-cert.pem https://localhost:8443/api/secure/users

# 使用客户端证书认证
curl --cert client.pem --key client-key.pem https://localhost:8443/api/secure/users
```

## 🧪 HTTPS安全特性测试

### 1. 自动化测试脚本
```bash
# 运行HTTPS安全特性测试
./test-https-api.sh

# 指定服务器地址和端口
./test-https-api.sh 192.168.1.100 8443
```

### 2. 测试覆盖范围
- **🔒 SSL/TLS连接**: 验证加密连接建立
- **📜 数字证书**: 检查证书信息和有效性
- **📡 加密传输**: 测试敏感数据安全传输
- **🔐 Token机制**: 验证安全Token生成和验证
- **🛡️ 安全头部**: 检查HSTS、CSP等安全头部
- **🔧 协议支持**: 测试TLS 1.2/1.3协议支持
- **⚡ 性能基准**: HTTPS连接性能测试

### 2. 手动测试SSL连接
```bash
# 检查SSL证书详细信息
openssl s_client -connect localhost:8443 -servername localhost

# 测试TLS 1.2连接
openssl s_client -connect localhost:8443 -tls1_2

# 测试TLS 1.3连接
openssl s_client -connect localhost:8443 -tls1_3
```

### 3. 安全API测试
```bash
# 1. 测试安全登录
LOGIN_RESPONSE=$(curl -k -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"secret"}' \
  https://localhost:8443/api/secure/login)

# 2. 提取Token
TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')

# 3. 使用Token访问安全端点
curl -k -H "Authorization: Bearer $TOKEN" \
  https://localhost:8443/api/security/test
```

### 4. 性能测试
```bash
# 使用Apache Bench进行HTTPS性能测试
ab -n 1000 -c 10 -k https://localhost:8443/api/ssl/info

# 使用wrk进行压力测试
wrk -t12 -c400 -d30s https://localhost:8443/api/secure/users
```

## 🔍 故障排除

### 常见问题及解决方案

1. **证书相关错误**
   ```bash
   # 验证证书格式
   openssl x509 -in cert.pem -text -noout
   
   # 检查私钥
   openssl rsa -in key.pem -check
   
   # 验证证书和私钥匹配
   openssl x509 -noout -modulus -in cert.pem | openssl md5
   openssl rsa -noout -modulus -in key.pem | openssl md5
   ```

2. **连接被拒绝**
   - 检查端口是否被占用: `lsof -i :8443`
   - 验证防火墙设置
   - 确认SSL配置正确

3. **浏览器安全警告**
   - 自签名证书的正常现象
   - 可以添加安全例外
   - 或安装CA证书到系统

4. **API访问失败**
   - 检查请求头格式
   - 验证Token有效性
   - 确认API路径正确

### 调试工具和命令

```bash
# 查看服务器日志
tail -f /var/log/https-server.log

# 网络连接调试
netstat -tlnp | grep :8443

# SSL握手调试
openssl s_client -connect localhost:8443 -debug

# 证书链验证
openssl verify -CAfile ca-cert.pem server-cert.pem
```

## 📚 相关文档

- [证书生成脚本使用指南](scripts/HTTPS证书生成脚本使用指南.md)
- [HTTPS服务器详细使用指南](HTTPS服务器使用指南.md)
- [WebServer完整文档](../../../../webserver/README.md)
- [HTTP服务器示例](../http/README.md)

## 🎯 HTTPS安全最佳实践

### 1. 证书安全管理
```bash
# 证书文件权限设置
chmod 600 dev-key.pem      # 私钥仅所有者可读
chmod 644 dev-cert.pem     # 证书文件可读

# 定期更新证书
./scripts/generate-dev-cert.sh $(hostname -I | awk '{print $1}')
```

### 2. TLS协议配置
```typescript
// 推荐的安全配置
const secureOptions: socket.TLSSecureOptions = {
  key: privateKey,
  cert: certificate,
  protocols: [socket.Protocol.TLSv13], // 仅使用最新协议
  // 强加密套件
  cipherSuite: 'ECDHE+AESGCM:ECDHE+CHACHA20:!aNULL:!MD5:!DSS'
};
```

### 3. 安全头部配置
```typescript
// 完整的安全头部配置
res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');
res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self'");
res.setHeader('X-Content-Type-Options', 'nosniff');
res.setHeader('X-Frame-Options', 'DENY');
res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
```

### 4. 开发vs生产环境
```typescript
// 开发环境
const devConfig = {
  selfSignedCert: true,
  corsOrigin: '*',
  logLevel: 'debug'
};

// 生产环境
const prodConfig = {
  validCertificate: true,
  corsOrigin: 'https://yourdomain.com',
  logLevel: 'error',
  hsts: true
};
```

### 5. 安全监控
- **连接监控**: 监控SSL握手成功率
- **证书监控**: 设置证书过期提醒
- **异常检测**: 监控异常访问模式
- **性能监控**: 跟踪HTTPS响应时间

## 🚀 HTTPS vs HTTP 对比

| 特性 | HTTP | HTTPS |
|------|------|-------|
| **数据传输** | 明文传输 | SSL/TLS加密 |
| **端口** | 80 | 443 |
| **安全性** | 无加密保护 | 端到端加密 |
| **身份验证** | 无 | 数字证书验证 |
| **数据完整性** | 无保证 | 加密校验 |
| **SEO排名** | 标准 | 搜索引擎优先 |
| **浏览器标识** | 无安全标识 | 🔒 安全锁图标 |

## 🔗 相关资源

- **证书生成**: [scripts/HTTPS证书生成脚本使用指南.md](scripts/HTTPS证书生成脚本使用指南.md)
- **详细指南**: [HTTPS服务器使用指南.md](HTTPS服务器使用指南.md)
- **WebServer文档**: [../../../../webserver/README.md](../../../../webserver/README.md)
- **HTTP对比示例**: [../http/README.md](../http/README.md)

通过本示例，开发者可以深入理解HTTPS的安全机制，掌握SSL/TLS加密通信的实现方法，为构建安全的Web应用奠定基础。