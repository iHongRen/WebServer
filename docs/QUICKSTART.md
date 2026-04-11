# WebServer 快速开始指南

## 简介

这是一个高性能、生产级的 ArkTS Web 服务器，具有以下特性：

- ⚡ **高性能**: 优化的请求解析和响应缓存
- 🔒 **安全**: 内置XSS、SQL注入防护和限流
- 📊 **监控**: 实时性能指标和慢请求检测
- 🗜️ **压缩**: Gzip压缩减少传输数据
- 🔄 **连接池**: 智能连接管理和资源复用
- 📦 **缓存**: LRU缓存策略提升静态文件性能

## 快速开始

### 1. 基础服务器

```typescript
import { HttpServer } from '@cxy/webserver';

const server = new HttpServer();

// 定义路由
server.get('/', (req, res) => {
  res.send('Hello World!');
});

server.get('/api/users', (req, res) => {
  res.json({
    users: [
      { id: 1, name: 'Alice' },
      { id: 2, name: 'Bob' }
    ]
  });
});

// 启动服务器
await server.startServer(8080);
console.log('服务器运行在 http://127.0.0.1:8080');
```

### 2. 添加中间件

```typescript
import { HttpServer, Logger, RateLimit, Compression } from '@cxy/webserver';

const server = new HttpServer();

// 日志
server.use(Logger.create());

// 限流
server.use(RateLimit.create({
  windowMs: 60000,  // 1分钟
  max: 100          // 最多100个请求
}));

// 压缩
server.use(Compression.create());

// 请求体解析
server.auto();

// CORS
server.cors();

// 路由
server.get('/', (req, res) => {
  res.send('Hello World!');
});

await server.startServer(8080);
```

### 3. 静态文件服务

```typescript
import { HttpServer } from '@cxy/webserver';

const server = new HttpServer();

// 提供静态文件
server.serveStatic('/data/storage/el2/base/haps/entry/files/public', {
  maxAge: 3600  // 1小时缓存
});

await server.startServer(8080);
```

### 4. RESTful API

```typescript
import { HttpServer } from '@cxy/webserver';

const server = new HttpServer();
server.auto();  // 自动解析请求体

// 获取所有用户
server.get('/api/users', (req, res) => {
  res.json({ users: [] });
});

// 获取单个用户
server.get('/api/users/:id', (req, res) => {
  const userId = req.params.id;
  res.json({ id: userId, name: 'User' });
});

// 创建用户
server.post('/api/users', (req, res) => {
  const userData = req.body;
  res.status(201).json({ success: true, data: userData });
});

// 更新用户
server.put('/api/users/:id', (req, res) => {
  const userId = req.params.id;
  const userData = req.body;
  res.json({ success: true, id: userId, data: userData });
});

// 删除用户
server.delete('/api/users/:id', (req, res) => {
  const userId = req.params.id;
  res.json({ success: true, deleted: userId });
});

await server.startServer(8080);
```

### 5. 文件上传

```typescript
import { HttpServer, FileUpload } from '@cxy/webserver';

const server = new HttpServer();

// 配置文件上传
server.use(FileUpload.create({
  useTempFiles: true,
  tempFileDir: '/tmp/uploads',
  limits: {
    fileSize: 50 * 1024 * 1024,  // 50MB
    files: 10
  }
}));

server.post('/upload', async (req, res) => {
  const files = req.files;
  
  if (!files || Object.keys(files).length === 0) {
    return res.status(400).json({ error: 'No files uploaded' });
  }

  // 处理上传的文件
  const file = files['file'];
  if (file) {
    // 移动文件到目标位置
    await file.mv('/data/storage/uploads/' + file.name);
    res.json({ success: true, filename: file.name });
  }
});

await server.startServer(8080);
```

### 6. 生产环境配置

```typescript
import { 
  HttpServer, 
  RateLimit, 
  Compression, 
  Security, 
  Performance,
  Logger 
} from '@cxy/webserver';

// 创建服务器（配置连接池和缓存）
const server = new HttpServer(
  {
    maxConnections: 2000,
    connectionTimeout: 30000,
    idleTimeout: 60000
  },
  {
    maxSize: 200 * 1024 * 1024,  // 200MB
    maxAge: 3600000,
    maxEntries: 2000
  }
);

// 安全防护
server.use(Security.create({
  enableXssProtection: true,
  enableFrameGuard: true,
  enableHsts: true,
  maxRequestSize: 10 * 1024 * 1024
}));

// 限流
server.use(RateLimit.create({
  windowMs: 60000,
  max: 100
}));

// 压缩
server.use(Compression.create());

// 性能监控
server.use(Performance.create({
  slowThreshold: 1000,
  onSlowRequest: (req, duration) => {
    console.warn(`慢请求: ${req.method} ${req.path} - ${duration}ms`);
  }
}));

// 日志
server.use(Logger.create());

// 请求处理
server.auto();
server.cors();

// 健康检查
server.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    connections: server.getClientCount(),
    cache: server.getCacheStats()
  });
});

// 性能指标
server.get('/metrics', (req, res) => {
  res.setHeader('Content-Type', 'text/plain');
  res.send(Performance.getReport());
});

// 静态文件
server.serveStatic('/data/storage/public');

// 启动服务器
await server.startServer(8080);

// 定期输出性能报告
setInterval(() => {
  console.log(Performance.getReport());
}, 60000);
```

## 中间件

### 内置中间件

| 中间件 | 说明 | 使用 |
|--------|------|------|
| BodyParser | 请求体解析 | `server.auto()` |
| Logger | 日志记录 | `server.logger()` |
| Cors | 跨域支持 | `server.cors()` |
| StaticFiles | 静态文件 | `server.serveStatic(path)` |
| RateLimit | 限流保护 | `server.use(RateLimit.create())` |
| Compression | Gzip压缩 | `server.use(Compression.create())` |
| Security | 安全防护 | `server.use(Security.create())` |
| Performance | 性能监控 | `server.use(Performance.create())` |

### 自定义中间件

```typescript
// 自定义中间件
server.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`);
  next();
});

// 错误处理中间件
server.use((err, req, res, next) => {
  console.error('错误:', err);
  res.status(500).json({ error: 'Internal Server Error' });
});
```

## API 参考

### HttpServer

```typescript
// 创建服务器
const server = new HttpServer(poolConfig?, cacheConfig?);

// 路由方法
server.get(path, handler);
server.post(path, handler);
server.put(path, handler);
server.delete(path, handler);
server.use(middleware);

// 便捷方法
server.auto();           // 自动解析请求体
server.json();           // JSON解析
server.urlencoded();     // URL编码解析
server.multipart();      // 多部分表单解析
server.cors(options?);   // CORS支持
server.logger(options?); // 日志记录
server.serveStatic(path, options?);  // 静态文件

// 服务器控制
await server.startServer(port, address?);
await server.stopServer();

// 状态查询
server.getClientCount();
server.getClients();
server.getCacheStats();
await server.getState();

// 事件监听
server.onError(listener);
server.on(eventType, listener);
```

### HttpRequest

```typescript
req.method          // HTTP方法
req.path            // 路径
req.url             // 完整URL
req.ip              // 客户端IP
req.headers         // 请求头
req.body            // 请求体
req.query           // 查询参数
req.params          // 路由参数
req.files           // 上传文件

req.get(headerName)     // 获取请求头
req.is(contentType)     // 检查Content-Type
```

### HttpResponse

```typescript
res.status(code)              // 设置状态码
res.setHeader(name, value)    // 设置响应头
res.getHeader(name)           // 获取响应头
res.removeHeader(name)        // 移除响应头

res.send(data)                // 发送响应
res.json(data)                // 发送JSON
res.write(chunk)              // 流式写入
res.end(chunk?)               // 结束响应

res.onFinish(callback)        // 响应完成回调
```

## 性能优化建议

1. **启用缓存**: 配置合适的缓存大小和过期时间
2. **使用压缩**: 启用Gzip压缩减少传输数据
3. **限流保护**: 防止API滥用和DDoS攻击
4. **连接池**: 配置合适的连接池大小
5. **监控**: 使用性能监控识别瓶颈
6. **静态文件**: 使用CDN或设置长缓存时间

## 安全建议

1. **启用HTTPS**: 在生产环境使用TLS加密
2. **安全头部**: 启用XSS、Frame Guard等防护
3. **限流**: 防止暴力破解和DDoS
4. **输入验证**: 验证和清理用户输入
5. **SQL注入**: 使用参数化查询
6. **定期更新**: 保持依赖库最新

## 故障排查

### 服务器无法启动

```typescript
server.onError((error) => {
  console.error('错误类型:', error.type);
  console.error('错误详情:', error.error);
});
```

### 性能问题

```typescript
// 查看性能报告
console.log(Performance.getReport());

// 查看缓存统计
console.log(server.getCacheStats());

// 监控慢请求
server.use(Performance.create({
  slowThreshold: 1000,
  onSlowRequest: (req, duration) => {
    console.warn(`慢请求: ${req.method} ${req.path} - ${duration}ms`);
  }
}));
```

### 内存问题

```typescript
// 调整缓存大小
const server = new HttpServer(undefined, {
  maxSize: 50 * 1024 * 1024,  // 减少到50MB
  maxEntries: 500
});

// 定期清理缓存
setInterval(() => {
  server.clearCache();
}, 3600000);
```

## 更多资源

- [完整文档](./OPTIMIZATION.md)
- [生产示例](./PRODUCTION_EXAMPLE.ets)
- [性能测试](./benchmark.sh)

## 支持

如有问题或建议，请提交 Issue 或 Pull Request。
