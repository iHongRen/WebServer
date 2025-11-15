# HTTPS服务器使用指南

本指南专注于HarmonyOS WebServer的HTTPS核心安全特性，包括SSL/TLS加密、数字证书管理、安全头部配置等关键功能。

## 🔒 HTTPS核心特性

### SSL/TLS加密通信
- **端到端加密**: 所有数据传输均通过SSL/TLS加密
- **协议支持**: TLS 1.2+ (推荐TLS 1.3)
- **完美前向保密**: 支持ECDHE密钥交换
- **强加密套件**: AES256-GCM、ChaCha20-Poly1305等

### 数字证书验证
- **X.509证书**: 标准数字证书格式
- **证书链验证**: 支持完整的证书信任链
- **自签名证书**: 开发环境快速部署
- **证书管理**: 安全的证书加载和存储

## 快速开始

### 1. 基本HTTPS服务器

```typescript
import { HttpsExample } from './HttpsExample';

// 创建HTTPS服务器实例
const httpsServer = new HttpsExample();

// 初始化配置
httpsServer.init();

// 启动安全服务器
const serverInfo = await httpsServer.start(8443);
console.log(`🔒 HTTPS服务器运行: https://${serverInfo.address}:${serverInfo.port}`);
```

### 2. 手动TLS配置

```typescript
import { TLSServer } from '@cxy/webserver';
import { socket } from '@kit.NetworkKit';

// 配置TLS选项
const tlsOptions: socket.TLSSecureOptions = {
  key: privateKeyPEM,
  cert: certificatePEM,
  protocols: [socket.Protocol.TLSv12, socket.Protocol.TLSv13]
};

// 创建HTTPS服务器
const server = new TLSServer(tlsOptions);

// 配置安全路由
server.get('/secure', (req, res) => {
  res.json({ 
    message: '安全数据传输',
    encrypted: true,
    timestamp: new Date().toISOString()
  });
});

await server.startServer(8443);
```

## 🔐 SSL/TLS证书管理

### 开发环境证书生成

```bash
# 快速生成开发证书
cd scripts
./generate-dev-cert.sh 192.168.1.100

# 生成的文件
# - dev-key.pem  (私钥)
# - dev-cert.pem (证书)
```

### 证书文件加载

```typescript
// 从文件系统加载证书
const loadCertificate = async (certPath: string, keyPath: string) => {
  const tlsOptions: socket.TLSSecureOptions = {
    key: await loadFileAsString(keyPath),
    cert: await loadFileAsString(certPath),
    protocols: [socket.Protocol.TLSv12, socket.Protocol.TLSv13]
  };
  return tlsOptions;
};

// 使用证书创建服务器
const tlsOptions = await loadCertificate('/path/to/cert.pem', '/path/to/key.pem');
const server = new TLSServer(tlsOptions);
```

### 生产环境证书配置

```typescript
// 生产环境推荐配置
const productionTLSOptions: socket.TLSSecureOptions = {
  key: productionPrivateKey,
  cert: productionCertificate,
  ca: caCertificate, // CA证书链
  protocols: [socket.Protocol.TLSv13], // 仅使用最新协议
  cipherSuite: 'ECDHE+AESGCM:ECDHE+CHACHA20:!aNULL:!MD5:!DSS'
};
```

## 🛡️ 安全配置选项

### TLS协议配置

参考: [HarmonyOS TLSSecureOptions](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-socket#tlssecureoptions9)

```typescript
const secureOptions: socket.TLSSecureOptions = {
  key: privateKey,           // 私钥 (PEM格式)
  cert: certificate,         // 证书 (PEM格式)
  ca: caCertificate,        // CA证书 (可选)
  protocols: [              // 支持的TLS协议版本
    socket.Protocol.TLSv12,
    socket.Protocol.TLSv13
  ],
  // 加密套件配置 (可选)
  cipherSuite: 'ECDHE+AESGCM:ECDHE+CHACHA20:!aNULL:!MD5:!DSS'
};
```

### 安全头部配置

```typescript
// HTTPS安全中间件
server.use((req, res, next) => {
  // HSTS - 强制HTTPS
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');
  
  // 内容安全策略
  res.setHeader('Content-Security-Policy', "default-src 'self'");
  
  // 防止MIME嗅探
  res.setHeader('X-Content-Type-Options', 'nosniff');
  
  // 防止点击劫持
  res.setHeader('X-Frame-Options', 'DENY');
  
  // XSS保护
  res.setHeader('X-XSS-Protection', '1; mode=block');
  
  next();
});
```

## 🔗 HTTPS路由和中间件

### 安全路由配置

```typescript
const httpsServer = new TLSServer(tlsOptions);

// HTTPS首页 - 展示加密连接状态
httpsServer.get('/', (req, res) => {
  res.json({
    message: '🔒 欢迎访问HTTPS安全服务器',
    features: {
      encryption: 'SSL/TLS加密传输',
      security: '安全头部保护',
      certificate: 'X.509数字证书验证',
      protocol: 'HTTPS协议'
    },
    connection: {
      secure: true,
      encrypted: true,
      protocol: 'HTTPS/1.1',
      timestamp: new Date().toISOString()
    }
  });
});

// SSL证书信息端点
httpsServer.get('/api/ssl/info', (req, res) => {
  res.json({
    ssl: {
      enabled: true,
      protocol: 'TLS',
      version: '1.2+',
      cipher: 'AES256-GCM-SHA384',
      keyExchange: 'ECDHE',
      keySize: 2048,
      signatureAlgorithm: 'RSA-SHA256'
    },
    certificate: {
      type: 'X.509',
      selfSigned: true,
      validFrom: new Date().toISOString(),
      validTo: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
      subject: 'CN=localhost',
      issuer: 'CN=Dev-CA'
    },
    security: {
      hsts: true,
      perfectForwardSecrecy: true,
      secureRenegotiation: true,
      compression: false
    }
  });
});

// 安全Token获取 (需要认证)
httpsServer.get('/api/secure/token', (req, res) => {
  const authHeader = req.headers?.['authorization'];
  
  if (!authHeader || authHeader !== 'Basic ZGVtbzpzZWN1cmU=') {
    res.status(401).json({
      error: 'Authentication required',
      message: '请提供有效的认证信息',
      note: 'HTTPS确保认证信息在传输过程中被加密保护'
    });
    return;
  }

  const secureToken = `secure_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  res.json({
    message: '🔐 安全Token已生成',
    token: secureToken,
    expiresIn: 3600,
    tokenType: 'Bearer',
    secureTransport: true,
    issuedAt: new Date().toISOString()
  });
});

// Token验证端点
httpsServer.get('/api/secure/verify/:token', (req, res) => {
  const token = req.params['token'];
  const isValidToken = token && token.startsWith('secure_') && token.length > 20;

  if (isValidToken) {
    res.json({
      message: '✅ Token验证成功',
      valid: true,
      token: token.substring(0, 15) + '...',
      verifiedAt: new Date().toISOString(),
      secureConnection: true
    });
  } else {
    res.status(401).json({
      message: '❌ Token验证失败',
      valid: false,
      error: 'Invalid or expired token'
    });
  }
});
```

### HTTPS中间件配置

```typescript
// 安全日志中间件
httpsServer.logger({
  format: 'combined',
  stream: (log) => console.log(`🔒 [HTTPS] ${log}`)
});

// HTTPS CORS配置
httpsServer.cors({
  origin: 'https://yourdomain.com', // 仅允许HTTPS来源
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE']
});

// 请求体解析
httpsServer.auto();
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