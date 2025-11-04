# HTTPS服务器示例 - 安全Web服务

本示例展示了如何创建安全的HTTPS服务器，包含SSL/TLS加密、安全头部、证书管理等功能。

## 📁 文件结构

```
entry/src/main/ets/examples/https/
├── HttpsExample.ets    # HTTPS服务器核心逻辑
├── HttpsPage.ets       # HTTPS服务器UI界面
├── scripts/            # 证书生成脚本
│   ├── generate-cert.sh
│   ├── generate-dev-cert.sh
│   └── generate-full-chain.sh
└── README.md          # 本文档
```

## 🚀 快速开始

### 1. 基本使用

```typescript
import { HttpsExample } from './HttpsExample';
import { common } from '@kit.AbilityKit';

const context = getContext() as common.UIAbilityContext;

// 创建HTTPS服务器
const httpsExample = new HttpsExample(context, {
  port: 8443,
  useSelfSigned: true,  // 使用自签名证书
  enableLogging: true,
  enableCors: true
});

// 设置文件和证书
await httpsExample.setupFiles();

// 初始化并启动服务器
httpsExample.initializeServer();
const serverInfo = await httpsExample.start();
```

### 2. 生产环境配置

```typescript
const httpsExample = new HttpsExample(context, {
  port: 443,
  useSelfSigned: false,     // 使用正式证书
  certPath: '/path/to/cert.pem',
  keyPath: '/path/to/key.pem',
  enableLogging: true,
  enableCors: false         // 生产环境建议关闭通配符CORS
});
```

## 🔐 SSL证书管理

### 生成自签名证书

使用提供的脚本生成开发用证书：

```bash
# 快速生成开发证书
cd scripts
./generate-dev-cert.sh 192.168.2.38

# 生成完整CA证书链
./generate-cert.sh 192.168.2.38 365 true

# 生成三级证书链
./generate-full-chain.sh example.com 365
```

### 证书文件说明

| 文件 | 描述 | 用途 |
|------|------|------|
| `server-key.pem` | 服务器私钥 | SSL/TLS加密 |
| `server-cert.pem` | 服务器证书 | 身份验证 |
| `ca-cert.pem` | CA根证书 | 证书链验证 |

## 📋 API端点

### 安全API

| 方法 | 路径 | 描述 | 示例 |
|------|------|------|------|
| GET | `/api/secure/users` | 安全用户列表 | `curl -k https://localhost:8443/api/secure/users` |
| POST | `/api/secure/users` | 创建安全用户 | `curl -k -X POST -H "Content-Type: application/json" -d '{"name":"Alice","email":"alice@secure.com"}' https://localhost:8443/api/secure/users` |
| POST | `/api/secure/login` | 安全登录 | `curl -k -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"secret"}' https://localhost:8443/api/secure/login` |
| POST | `/api/secure/upload` | 安全文件上传 | `curl -k -X POST -F "uploadFile=@test.txt" https://localhost:8443/api/secure/upload` |

### 安全信息API

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/api/ssl/info` | SSL证书信息 |
| GET | `/api/security/test` | 安全测试端点 |

## 🛡️ 安全特性

### 1. SSL/TLS加密
- 支持TLS 1.2和TLS 1.3
- 强加密算法套件
- 完美前向保密

### 2. 安全头部
```typescript
// 自动添加的安全头部
res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
res.setHeader('X-Content-Type-Options', 'nosniff');
res.setHeader('X-Frame-Options', 'DENY');
res.setHeader('X-XSS-Protection', '1; mode=block');
```

### 3. CORS安全配置
```typescript
// 生产环境CORS配置
server.cors({
  origin: 'https://yourdomain.com',  // 限制来源
  credentials: true,                 // 允许凭证
  methods: ['GET', 'POST', 'PUT', 'DELETE']
});
```

## 🔧 配置选项

```typescript
interface HttpsServerConfig {
  port: number;              // HTTPS端口 (默认: 8443)
  staticRoot: string;        // 静态文件目录
  enableLogging: boolean;    // 启用日志
  enableCors: boolean;       // 启用CORS
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

### 程序访问
```bash
# 忽略证书验证 (仅开发环境)
curl -k https://localhost:8443/api/secure/users

# 指定CA证书
curl --cacert ca-cert.pem https://localhost:8443/api/secure/users

# 使用客户端证书
curl --cert client.pem --key client-key.pem https://localhost:8443/api/secure/users
```

## 🧪 测试示例

### 1. 测试SSL连接
```bash
# 检查SSL证书
openssl s_client -connect localhost:8443 -servername localhost

# 测试TLS版本
openssl s_client -connect localhost:8443 -tls1_3
```

### 2. 测试安全API
```bash
# 测试安全登录
curl -k -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"secret"}' \
  https://localhost:8443/api/secure/login

# 测试SSL信息
curl -k https://localhost:8443/api/ssl/info
```

### 3. 性能测试
```bash
# 使用ab进行HTTPS性能测试
ab -n 1000 -c 10 -k https://localhost:8443/api/secure/users
```

## 🔍 故障排除

### 常见问题

1. **证书错误**
   - 检查证书文件格式和路径
   - 验证证书有效期
   - 确认私钥与证书匹配

2. **连接被拒绝**
   - 检查端口是否被占用
   - 验证防火墙设置
   - 确认SSL配置正确

3. **浏览器安全警告**
   - 自签名证书正常现象
   - 可以添加例外或安装CA证书

### 调试命令
```bash
# 验证证书
openssl x509 -in server-cert.pem -text -noout

# 检查私钥
openssl rsa -in server-key.pem -check

# 验证证书和私钥匹配
openssl x509 -noout -modulus -in server-cert.pem | openssl md5
openssl rsa -noout -modulus -in server-key.pem | openssl md5
```

## 📚 相关文档

- [证书生成脚本使用指南](scripts/README.md)
- [WebServer完整文档](../../../webserver/README.md)
- [HTTP服务器示例](../http/README.md)

## 🎯 最佳实践

1. **证书管理**
   - 使用有效的SSL证书
   - 定期更新证书
   - 监控证书过期时间

2. **安全配置**
   - 禁用不安全的协议版本
   - 使用强加密算法
   - 配置适当的安全头部

3. **性能优化**
   - 启用HTTP/2
   - 使用会话复用
   - 配置适当的缓存策略

4. **监控和日志**
   - 记录安全事件
   - 监控异常连接
   - 定期安全审计