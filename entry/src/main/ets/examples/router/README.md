# Router 示例

这个示例展示了 WebServer 路由系统的强大功能，包括参数路由、通配符路由、动态路由管理和路由统计分析。

## 功能特性

### 🔗 路由类型
- **基础路由**: 静态路径匹配
- **参数路由**: 动态参数提取 (`:id`, `:category`)
- **通配符路由**: 路径通配符匹配 (`*`)
- **动态路由**: 运行时添加/删除路由

### 📊 路由统计
- 路由访问次数统计
- HTTP方法分布
- 热门路由排行
- 平均响应时间
- 路由性能监控

### ⚙️ 路由管理
- 动态添加路由
- 动态删除路由
- 路由记录查询
- 路由配置管理

## API 端点

### 演示页面
```
GET  /router-demo.html      - Router演示页面
GET  /route-tester.html     - 路由测试工具
```

### 基础路由
```
GET    /                    - 首页
GET    /about               - 关于页面
GET    /contact             - 联系页面
```

### 参数路由
```
GET    /api/users/:id       - 用户详情
GET    /api/products/:category/:id - 产品详情
GET    /api/posts/:id       - 文章详情
```

### 通配符路由
```
GET    /files/*             - 文件访问
GET    /api/v*/status       - API版本状态
```

### 路由管理 API
```
GET    /api/routes/stats    - 路由统计
GET    /api/routes/records  - 路由记录
POST   /api/routes          - 添加动态路由
GET    /api/routes/dynamic  - 获取动态路由
DELETE /api/routes/records  - 清除路由记录
```

## 使用示例

### 1. 启动服务器
```typescript
const context = getContext() as common.UIAbilityContext;
const routerExample = new RouterExample(context, {
  port: 8086,
  enableLogging: true,
  enableCors: true
});

await routerExample.setupStaticFiles();
const serverInfo = await routerExample.start();
```

### 2. 访问参数路由
```bash
# 获取用户信息
curl http://localhost:8086/api/users/123

# 获取产品信息
curl http://localhost:8086/api/products/electronics/456

# 获取文章 (支持格式参数)
curl http://localhost:8086/api/posts/789?format=xml
```

### 3. 访问通配符路由
```bash
# 文件访问
curl http://localhost:8086/files/documents/readme.txt
curl http://localhost:8086/files/images/logo.png

# API版本
curl http://localhost:8086/api/v1/status
curl http://localhost:8086/api/v2/status
```

### 4. 动态路由管理
```bash
# 添加动态路由
curl -X POST http://localhost:8086/api/routes \
  -H "Content-Type: application/json" \
  -d '{
    "method": "GET",
    "path": "/api/custom",
    "response": {"message": "这是一个动态路由"}
  }'

# 访问动态路由
curl http://localhost:8086/api/custom

# 获取所有动态路由
curl http://localhost:8086/api/routes/dynamic

# 删除动态路由
curl -X DELETE http://localhost:8086/api/routes/GET/api/custom
```

### 5. 路由统计查询
```bash
# 获取路由统计
curl http://localhost:8086/api/routes/stats

# 获取路由记录
curl "http://localhost:8086/api/routes/records?limit=20"

# 按方法过滤
curl "http://localhost:8086/api/routes/records?method=POST"
```

## 路由模式

### 参数路由
参数路由使用 `:` 前缀定义参数：

```typescript
// 单个参数
server.get('/users/:id', (req, res) => {
  const userId = req.params['id'];
  // ...
});

// 多个参数
server.get('/products/:category/:id', (req, res) => {
  const { category, id } = req.params;
  // ...
});
```

### 通配符路由
通配符路由使用 `*` 匹配任意路径：

```typescript
// 文件路径通配符
server.get('/files/*', (req, res) => {
  const filePath = req.path.replace('/files/', '');
  // ...
});

// API版本通配符
server.get('/api/v*/status', (req, res) => {
  const version = req.path.match(/\/api\/(v\d+)\/status/)?.[1];
  // ...
});
```

## 路由记录结构

```typescript
interface RouteRecord {
  id: number;                      // 记录ID
  method: string;                  // HTTP方法
  path: string;                    // 请求路径
  pattern: string;                 // 路由模式
  params: Record<string, string>;  // 路由参数
  query: Record<string, string>;   // 查询参数
  timestamp: Date;                 // 时间戳
  responseTime: number;            // 响应时间(ms)
  statusCode: number;              // 状态码
}
```

## 动态路由

动态路由允许在运行时添加和删除路由：

```typescript
// 添加动态路由
const routeConfig = {
  method: 'GET',
  path: '/api/dynamic',
  response: { message: 'Dynamic route' }
};

// 路由会被存储并在请求时匹配
```

## 路由统计

路由统计提供以下信息：
- **总请求数**: 所有路由的请求总数
- **路由统计**: 每个路由的访问次数
- **方法统计**: GET/POST/PUT/DELETE 等方法分布
- **平均响应时间**: 所有请求的平均响应时间
- **热门路由**: 访问次数最多的前5个路由

## 路由优先级

路由匹配按以下优先级进行：
1. **精确匹配**: 完全匹配的静态路由
2. **参数路由**: 带参数的动态路由
3. **通配符路由**: 通配符匹配的路由
4. **动态路由**: 运行时添加的路由

## 性能优化

### 路由缓存
- 路由匹配结果会被缓存
- 参数解析结果会被缓存
- 减少重复的正则表达式匹配

### 路由索引
- 静态路由使用哈希表索引
- 参数路由按模式分组
- 通配符路由最后匹配

## 最佳实践

1. **路由设计**: 保持路由结构清晰和一致
2. **参数验证**: 对路由参数进行验证
3. **错误处理**: 为无效路由提供友好的错误信息
4. **性能监控**: 监控路由响应时间
5. **文档维护**: 保持路由文档的更新

## 调试技巧

### 路由测试
```bash
# 测试路由是否正确匹配
curl -v http://localhost:8086/api/users/123

# 检查路由参数
curl http://localhost:8086/api/products/electronics/456

# 验证查询参数
curl "http://localhost:8086/api/posts/789?format=json&lang=zh"
```

### 路由分析
```bash
# 查看路由统计
curl http://localhost:8086/api/routes/stats | jq

# 查看最近的路由记录
curl "http://localhost:8086/api/routes/records?limit=10" | jq

# 分析热门路由
curl http://localhost:8086/api/routes/stats | jq '.popularRoutes'
```

## 注意事项

1. 路由记录最多保留500条
2. 动态路由在服务器重启后会丢失
3. 通配符路由可能影响性能
4. 参数名不能包含特殊字符
5. 路由路径区分大小写
6. 查询参数不影响路由匹配

## 扩展功能

### 路由中间件
可以为特定路由添加中间件：

```typescript
// 认证中间件
server.use('/api/admin/*', authMiddleware);

// 日志中间件
server.use('/api/*', logMiddleware);
```

### 路由分组
可以对相关路由进行分组管理：

```typescript
// API v1 路由组
server.group('/api/v1', (router) => {
  router.get('/users', getUsersV1);
  router.get('/posts', getPostsV1);
});

// API v2 路由组
server.group('/api/v2', (router) => {
  router.get('/users', getUsersV2);
  router.get('/posts', getPostsV2);
});
```