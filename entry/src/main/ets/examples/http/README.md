# HTTP服务器示例 - 快速入门指南

本示例展示了如何使用HarmonyOS WebServer创建一个功能完整的HTTP服务器，包含RESTful API、文件上传、静态文件服务等功能。

## 📁 文件结构

```
entry/src/main/ets/examples/http/
├── HttpExample.ets     # 核心业务逻辑类
├── HttpPage.ets        # UI界面组件
└── README.md          # 本文档
```

## 🚀 快速开始

### 1. 基本使用

```typescript
import { HttpExample } from './HttpExample';
import { common } from '@kit.AbilityKit';

// 获取应用上下文
const context = getContext() as common.UIAbilityContext;

// 创建HTTP服务器示例
const httpExample = new HttpExample(context, {
  port: 8080,
  enableLogging: true,
  enableCors: true
});

// 设置静态文件
await httpExample.setupStaticFiles();

// 初始化服务器
httpExample.initializeServer();

// 启动服务器
const serverInfo = await httpExample.start();
console.log(`服务器启动成功: http://${serverInfo.address}:${serverInfo.port}`);
```

### 2. 自定义配置

```typescript
const httpExample = new HttpExample(context, {
  port: 3000,                    // 自定义端口
  staticRoot: '/custom/path',    // 自定义静态文件目录
  enableLogging: false,          // 禁用日志
  enableCors: true              // 启用CORS
});
```

## 📋 API端点说明

### 用户管理API

| 方法 | 路径 | 描述 | 示例 |
|------|------|------|------|
| GET | `/api/users` | 获取用户列表 | `curl http://localhost:8080/api/users` |
| GET | `/api/users/:id` | 获取单个用户 | `curl http://localhost:8080/api/users/1` |
| POST | `/api/users` | 创建用户 | `curl -X POST -H "Content-Type: application/json" -d '{"name":"Alice","email":"alice@example.com"}' http://localhost:8080/api/users` |
| PUT | `/api/users/:id` | 更新用户 | `curl -X PUT -H "Content-Type: application/json" -d '{"name":"Bob"}' http://localhost:8080/api/users/1` |
| DELETE | `/api/users/:id` | 删除用户 | `curl -X DELETE http://localhost:8080/api/users/1` |

### 用户列表支持查询参数

```bash
# 分页查询
curl "http://localhost:8080/api/users?page=1&limit=5"

# 搜索用户
curl "http://localhost:8080/api/users?search=alice"

# 组合查询
curl "http://localhost:8080/api/users?page=1&limit=10&search=bob"
```

### 文件管理API

| 方法 | 路径 | 描述 | 示例 |
|------|------|------|------|
| POST | `/api/upload` | 上传文件 | `curl -X POST -F "uploadFile=@test.txt" http://localhost:8080/api/upload` |
| GET | `/api/files` | 获取文件列表 | `curl http://localhost:8080/api/files` |

### 工具API

| 方法 | 路径 | 描述 | 示例 |
|------|------|------|------|
| GET | `/api/status` | 服务器状态 | `curl http://localhost:8080/api/status` |
| GET | `/api/headers` | 请求头信息 | `curl http://localhost:8080/api/headers` |
| POST | `/api/echo` | 回显请求 | `curl -X POST -H "Content-Type: application/json" -d '{"test":"data"}' http://localhost:8080/api/echo` |
| GET | `/api/error` | 测试错误处理 | `curl http://localhost:8080/api/error?type=validation` |

## 🔧 核心功能详解

### 1. 中间件配置

```typescript
// HttpExample.ets 中的 setupMiddleware() 方法
private setupMiddleware(): void {
  // 1. 日志中间件 - 记录所有请求
  this.server.logger({
    format: 'dev',
    stream: (log: string) => console.log(`📝 ${log}`)
  });

  // 2. CORS中间件 - 支持跨域请求
  this.server.cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
  });

  // 3. 请求体解析 - 自动解析JSON、表单等
  this.server.auto();

  // 4. 静态文件服务
  this.server.serveStatic(this.config.staticRoot);
}
```

### 2. 错误处理

```typescript
// 全局错误处理中间件
const errorHandler: ErrorHandler = (error, req, res, next) => {
  console.error(`🚨 [Global Error Handler] ${req.method} ${req.path}: ${error.message}`);
  
  // 根据错误类型返回不同状态码
  let statusCode = 500;
  if (error.message.includes('Validation')) {
    statusCode = 400;
  } else if (error.message.includes('timeout')) {
    statusCode = 408;
  }
  
  res.status(statusCode).json({
    error: 'Internal Server Error',
    message: error.message,
    timestamp: new Date().toISOString()
  });
};
```

### 3. 事件监听

```typescript
// 服务器事件监听
this.server.onError((error) => {
  console.error(`🚨 服务器错误: [${error.type}] ${error.message}`);
});

this.server.on(ServerEventType.SERVER_STARTED, (event) => {
  console.log('✅ 服务器启动成功:', event.data);
});

this.server.onClientConnect((client) => {
  console.log(`👤 新客户端连接: ${client.address}:${client.port}`);
});
```

## 📱 UI界面使用

### 启动服务器
1. 打开应用，进入HTTP服务器示例页面
2. 配置端口号（默认8080）
3. 点击"启动服务器"按钮
4. 查看服务器信息和访问地址

### 测试API
1. 使用浏览器访问 `http://IP:端口/` 查看首页
2. 访问 `http://IP:端口/upload.html` 测试文件上传
3. 使用curl或Postman测试各种API端点

## 🛠️ 自定义扩展

### 添加新的API端点

```typescript
// 在 HttpExample.ets 的 setupApiRoutes() 方法中添加
this.server.get('/api/custom', (req: HttpRequest, res: HttpResponse) => {
  res.json({
    message: 'Custom API endpoint',
    timestamp: new Date().toISOString()
  });
});
```

### 添加中间件

```typescript
// 在 setupMiddleware() 方法中添加
this.server.use((req, res, next) => {
  // 自定义中间件逻辑
  console.log(`请求: ${req.method} ${req.path}`);
  next();
});
```

### 自定义错误处理

```typescript
// 添加特定错误处理
this.server.use((error, req, res, next) => {
  if (error.message.includes('CustomError')) {
    return res.status(400).json({ error: 'Custom error occurred' });
  }
  next(error);
});
```

## 📊 性能监控

HttpExample类提供了多种监控方法：

```typescript
// 获取服务器状态
const isRunning = httpExample.getIsRunning();
const serverInfo = httpExample.getServerInfo();
const config = httpExample.getConfig();

// 获取用户数据统计
const users = httpExample.getUsers();
const userCount = httpExample.getUserCount();
```

## 🔍 调试技巧

### 1. 启用详细日志
```typescript
const httpExample = new HttpExample(context, {
  enableLogging: true  // 启用详细日志
});
```

### 2. 测试错误处理
```bash
# 测试不同类型的错误
curl "http://localhost:8080/api/error?type=validation"
curl "http://localhost:8080/api/error?type=timeout"
curl "http://localhost:8080/api/error?type=database"
```

### 3. 查看服务器状态
```bash
curl http://localhost:8080/api/status
```

## 🚨 常见问题

### Q: 服务器启动失败
A: 检查端口是否被占用，尝试使用其他端口号

### Q: 无法访问API
A: 确认防火墙设置，检查IP地址和端口号是否正确

### Q: 文件上传失败
A: 检查文件大小限制，确认表单字段名为"uploadFile"

### Q: CORS错误
A: 确认已启用CORS中间件，检查请求头设置

## 📚 相关文档

- [WebServer完整文档](../../../webserver/README.md)
- [错误处理指南](../../../webserver/ERROR_HANDLING_GUIDE.md)
- [HTTPS服务器示例](../https/README.md)

## 🎯 最佳实践

1. **中间件顺序**: 日志 → CORS → 请求解析 → 静态文件 → 路由 → 错误处理
2. **错误处理**: 使用全局错误处理中间件统一处理错误
3. **日志记录**: 启用详细日志便于调试和监控
4. **安全性**: 在生产环境中限制CORS来源和请求方法
5. **性能**: 合理设置静态文件缓存和请求体大小限制