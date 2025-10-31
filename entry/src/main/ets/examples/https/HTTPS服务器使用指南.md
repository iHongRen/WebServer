# HTTPS服务器使用指南

本指南介绍如何在HarmonyOS WebServer中使用HTTPS功能，基于HarmonyOS的TLSSocket API实现。

## 快速开始

### 1. 基本HTTPS服务器

```typescript
import { TLSServer, CertificateManager, HttpsExample } from '@cxy/webserver';

// 方式1: 使用示例快速启动
await HttpsExample.startCompleteExample();

// 方式2: 手动配置
const tlsOptions = CertificateManager.createSelfSignedConfig();
const httpsServer = new TLSServer(tlsOptions);

httpsServer.get('/', (req, res) => {
  res.json({ message: 'Hello HTTPS!' });
});

await httpsServer.startServer(8443);
```

### 2. 生产环境配置

```typescript
// 从文件加载证书
const httpsServer = await HttpsExample.createProductionServer(
  '/path/to/private-key.pem',
  '/path/to/certificate.pem',
  '/path/to/ca-certificate.pem' // 可选
);

await httpsServer.startServer(443);
```

## 证书管理

### 自签名证书（开发环境）

```typescript
import { CertificateManager } from '@your-package/webserver';

const tlsOptions = CertificateManager.createSelfSignedConfig();
// 注意：自签名证书仅用于开发，浏览器会显示安全警告
```

### 从文件加载证书

```typescript
const tlsOptions = await CertificateManager.loadFromFiles(
  'server.key', // 私钥文件
  'server.crt', // 证书文件
  'ca.crt'         // CA证书（可选）
);
```

### 证书验证

```typescript
const isValid = CertificateManager.validateConfig(tlsOptions);
if (!isValid) {
  throw new Error('证书配置无效');
}
```

## TLS配置选项

https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-socket#tlssecureoptions9

```typescript
const secureOptions: socket.TLSSecureOptions = {
  key: privateKey,
  cert: certificate,
  protocols: ['TLSv1.2', 'TLSv1.3'], // 只支持安全协议
  cipherSuite: 'ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:DHE+CHACHA20:!aNULL:!MD5:!DSS'
};
```

## 中间件支持

HTTPS服务器完全支持所有现有中间件：

```typescript
const httpsServer = new TLSServer(tlsOptions);

// 日志中间件
httpsServer.logger({
  format: 'combined',
  logLevel: 'info'
});

// CORS中间件
httpsServer.cors({
  origin: ['https://yourdomain.com'],
  credentials: true
});

// 请求体解析
httpsServer.json();
httpsServer.urlencoded();

// 静态文件服务
httpsServer.serveStatic('/public');
```

## 路由配置

```typescript
// GET路由
httpsServer.get('/api/secure', (req, res) => {
  res.json({ secure: true, data: 'Encrypted data' });
});

// POST路由
httpsServer.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  // 处理安全登录逻辑
  res.json({ token: 'secure-jwt-token' });
});

// 带参数路由
httpsServer.get('/api/users/:id', (req, res) => {
  const userId = req.params.id;
  res.json({ userId, secure: true });
});
```

## 错误处理

```typescript
httpsServer.use((err, req, res, next) => {
  console.error('HTTPS服务器错误:', err);
  if (!res.isHeadersSent()) {
    res.status(500).json({
      error: 'Internal Server Error',
      secure: true
    });
  }
});
```

## 性能优化

### 1. 连接复用

```typescript
// 默认启用Keep-Alive
httpsServer.use((req, res, next) => {
  res.setHeader('Connection', 'keep-alive');
  next();
});
```

### 2. 压缩支持

```typescript
// 可以添加压缩中间件
httpsServer.use((req, res, next) => {
  const acceptEncoding = req.get('accept-encoding') || '';
  if (acceptEncoding.includes('gzip')) {
    res.setHeader('Content-Encoding', 'gzip');
    // 实现gzip压缩逻辑
  }
  next();
});
```

## 安全最佳实践

### 1. 强制HTTPS重定向

```typescript
// 在HTTP服务器上添加重定向
httpServer.use((req, res, next) => {
  if (req.get('x-forwarded-proto') !== 'https') {
    return res.status(301).setHeader('Location', `https://${req.get('host')}${req.url}`).send();
  }
  next();
});
```

### 2. 安全头部

```typescript
httpsServer.use((req, res, next) => {
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  next();
});
```

### 3. 证书管理

- 使用有效的SSL证书（Let's Encrypt、商业CA等）
- 定期更新证书
- 监控证书过期时间
- 使用强加密算法

## 部署注意事项

### 1. 端口配置

- 开发环境：8443
- 生产环境：443（需要管理员权限）

### 2. 防火墙配置

确保HTTPS端口在防火墙中开放：

```bash
# 示例防火墙规则
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

### 3. 负载均衡

在生产环境中，建议使用负载均衡器处理SSL终止：

```
Client -> Load Balancer (SSL终止) -> HarmonyOS HTTPS Server
```

## 故障排除

### 常见问题

1. **证书错误**
    - 检查证书格式和有效期
    - 验证私钥与证书匹配

2. **连接被拒绝**
    - 检查端口是否被占用
    - 验证防火墙设置

3. **性能问题**
    - 监控TLS握手时间
    - 考虑使用会话复用

### 调试技巧

```typescript
// 启用详细日志
httpsServer.logger({
  logLevel: 'debug',
  format: 'dev'
});

// 监控连接事件
httpsServer.on('connect', (socket) => {
  console.log('新的HTTPS连接:', socket.remoteAddress);
});
```

## API参考

详细的API文档请参考各个类的TypeScript定义文件。

## 示例项目

完整的示例项目可以在 `examples/https/HttpsExample.ets` 中找到。