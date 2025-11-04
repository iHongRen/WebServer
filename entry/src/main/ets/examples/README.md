# WebServer 示例集合

本目录包含了HarmonyOS WebServer的完整示例集合，展示了各种功能和使用场景。

## 📁 示例目录结构

```
entry/src/main/ets/examples/
├── http/                    # HTTP服务器基础示例
│   ├── HttpExample.ets      # HTTP服务器核心逻辑
│   ├── HttpPage.ets         # HTTP服务器UI界面
│   ├── test-api.sh          # API测试脚本
│   └── README.md            # HTTP示例文档
├── https/                   # HTTPS安全服务器示例
│   ├── HttpsExample.ets     # HTTPS服务器核心逻辑
│   ├── HttpsPage.ets        # HTTPS服务器UI界面
│   ├── test-https-api.sh    # HTTPS API测试脚本
│   ├── scripts/             # 证书生成脚本
│   └── README.md            # HTTPS示例文档
├── body-parser/             # 请求体解析示例
│   ├── BodyParserExample.ets # Body Parser核心逻辑
│   ├── BodyParserPage.ets   # Body Parser UI界面
│   └── README.md            # Body Parser示例文档
├── cors/                    # 跨域资源共享示例
│   ├── CorsExample.ets      # CORS核心逻辑
│   ├── CorsPage.ets         # CORS UI界面
│   └── README.md            # CORS示例文档
├── event/                   # 事件系统示例
│   ├── EventExample.ets     # Event核心逻辑
│   ├── EventPage.ets        # Event UI界面
│   └── README.md            # Event示例文档
├── logger/                  # 日志系统示例
│   ├── LoggerExample.ets    # Logger核心逻辑
│   ├── LoggerPage.ets       # Logger UI界面
│   ├── test-logger-api.sh   # Logger API测试脚本
│   └── README.md            # Logger示例文档
├── router/                  # 路由系统示例
│   ├── RouterExample.ets    # Router核心逻辑
│   ├── RouterPage.ets       # Router UI界面
│   ├── test-router-api.sh   # Router API测试脚本
│   └── README.md            # Router示例文档
├── static/                  # 静态文件服务示例
│   ├── StaticExample.ets    # Static核心逻辑
│   ├── StaticPage.ets       # Static UI界面
│   ├── test-static-api.sh   # Static API测试脚本
│   └── README.md            # Static示例文档
└── README.md               # 本文档
```

## 🚀 示例概览

### 1. HTTP服务器示例 (端口: 8080)

**功能特性:**

- ✅ RESTful API (用户管理CRUD)
- ✅ 文件上传下载
- ✅ 静态文件服务
- ✅ 请求体解析 (JSON, Form, Multipart)
- ✅ CORS跨域支持
- ✅ 错误处理和日志记录

**主要API:**

- `GET /api/users` - 获取用户列表
- `POST /api/users` - 创建用户
- `POST /api/upload` - 文件上传
- `GET /api/files` - 文件列表

### 2. HTTPS安全服务器示例 (端口: 8443)

**功能特性:**

- 🔒 SSL/TLS加密传输
- 🛡️ 安全头部设置
- 🔐 证书管理 (自签名/正式证书)
- 🔑 安全用户认证
- 📋 SSL信息查询

**主要API:**

- `GET /api/secure/users` - 安全用户管理
- `POST /api/secure/login` - 安全登录
- `GET /api/ssl/info` - SSL证书信息

### 3. WebSocket实时通信示例 (端口: 8081)

**功能特性:**

- 🔌 WebSocket实时双向通信
- 💬 多房间聊天系统
- 👥 在线用户管理
- 💓 心跳保活机制
- 📢 消息广播推送

**主要API:**

- `GET /ws` - WebSocket连接端点
- `POST /api/chat/send` - 发送聊天消息
- `GET /api/ws/users` - 在线用户列表

### 4. Body Parser解析示例 (端口: 8082)

**功能特性:**

- 📝 JSON数据解析
- 📋 表单数据解析 (URL-encoded)
- 📁 多部分表单解析 (文件上传)
- 📄 纯文本解析
- 🤖 智能自动解析

**主要API:**

- `POST /api/json` - JSON解析器测试
- `POST /api/multipart` - 文件上传解析
- `POST /api/auto` - 自动解析器

### 5. CORS跨域示例 (端口: 8083)

**功能特性:**

- 🌐 跨域资源共享
- 🛡️ 来源访问控制
- 🔍 预检请求处理
- 🔑 凭证请求支持
- 📊 CORS请求统计

**主要API:**

- `GET /api/cors/simple` - 简单请求测试
- `POST /api/cors/preflight` - 预检请求测试
- `GET /api/cors/config` - CORS配置管理

### 6. Event事件系统示例 (端口: 8084)

**功能特性:**

- 📡 服务器事件监听
- ⚠️ 错误事件捕获
- 🔗 客户端连接事件
- 🎯 自定义事件触发
- 📊 事件统计分析

**主要API:**

- `GET /api/events` - 获取事件历史
- `POST /api/events/trigger` - 触发自定义事件
- `GET /api/monitor/dashboard` - 监控仪表板

### 7. Logger日志系统示例 (端口: 8085)

**功能特性:**

- 📝 多格式日志记录 (dev, combined, common等)
- 📊 日志统计分析
- 📁 文件日志存储
- 🔍 日志查询过滤
- ⚙️ 动态配置管理

**主要API:**

- `GET /api/logs` - 获取日志记录
- `POST /api/logs/config` - 更新日志配置
- `POST /api/logs/test/:level` - 测试日志级别

### 8. Router路由系统示例 (端口: 8086)

**功能特性:**

- 🛣️ 动态路由管理
- 📋 路由参数解析 (`:id`, `:category`)
- 🌟 通配符路由支持 (`*`)
- 📊 路由统计分析
- 🧪 路由测试工具

**主要API:**

- `GET /api/users/:id` - 参数路由测试
- `GET /files/*` - 通配符路由测试
- `POST /api/routes` - 添加动态路由
- `GET /api/routes/stats` - 路由统计

### 9. Static静态文件示例 (端口: 8087)

**功能特性:**

- 📁 静态文件服务
- 💾 文件缓存管理 (ETag, Last-Modified)
- 🔍 文件浏览器
- 📊 访问统计分析
- ⚙️ 动态缓存配置

**主要API:**

- `GET /` - 静态文件访问
- `POST /api/upload` - 文件上传
- `GET /api/files` - 文件浏览器
- `GET /api/stats` - 访问统计

## 🎯 使用方法

### 1. 基本使用

每个示例都遵循相同的使用模式：

```typescript
import { ExampleClass } from './ExampleClass';
import { common } from '@kit.AbilityKit';

const context = getContext() as common.UIAbilityContext;

// 创建示例实例
const example = new ExampleClass(context, {
  port: 8080,
  enableLogging: true,
  enableCors: true
});

// 设置静态文件
await example.setupStaticFiles();

// 初始化服务器
example.initializeServer();

// 启动服务器
const serverInfo = await example.start();
```

### 2. UI界面使用

每个示例都提供了对应的UI界面：

```typescript
import { exampleBuilder } from './ExamplePage';

// 在页面中使用
@
Entry
@
Component
struct
MainPage
{
  build()
  {
    Navigation()
    {
      exampleBuilder()
    }
  }
}
```

### 3. API测试

每个示例都提供了测试脚本：

```bash
# HTTP示例测试
./examples/http/test-api.sh 192.168.2.38 8080

# HTTPS示例测试
./examples/https/test-https-api.sh 192.168.2.38 8443

# WebSocket示例测试
./examples/websocket/test-websocket-api.sh 192.168.2.38 8081

# Logger示例测试
./examples/logger/test-logger-api.sh 192.168.2.38 8085

# Router示例测试
./examples/router/test-router-api.sh 192.168.2.38 8086

# Static示例测试
./examples/static/test-static-api.sh 192.168.2.38 8087
```

## 📚 学习路径

### 初学者路径

1. **HTTP示例** - 了解基础HTTP服务器功能
2. **Body Parser示例** - 学习请求体解析
3. **Static示例** - 掌握静态文件服务
4. **Logger示例** - 理解日志记录

### 进阶路径

1. **CORS示例** - 掌握跨域处理
2. **Router示例** - 深入路由系统
3. **Event示例** - 理解事件驱动架构
4. **HTTPS示例** - 学习安全通信

### 高级路径

1. **WebSocket示例** - 实现实时通信
2. **组合使用** - 将多个功能组合使用
3. **性能优化** - 优化服务器性能
4. **生产部署** - 部署到生产环境

## 🔧 开发工具

### 测试工具

- **curl** - HTTP请求测试
- **wscat** - WebSocket连接测试
- **jq** - JSON数据处理
- **openssl** - SSL证书管理

### 监控工具

- **浏览器开发者工具** - 网络请求监控
- **Postman** - API测试工具
- **各示例内置监控页面** - 实时状态监控

## 📖 相关文档

- [WebServer完整文档](../../../webserver/README.md)
- [错误处理指南](../../../webserver/ERROR_HANDLING_GUIDE.md)
- [HTTPS使用指南](../../../webserver/HTTPS_GUIDE.md)
- [各示例详细文档](./*/README.md)

## 🎯 最佳实践

### 1. 代码组织

- 将业务逻辑与UI逻辑分离
- 使用TypeScript接口定义数据结构
- 遵循单一职责原则

### 2. 错误处理

- 使用全局错误处理中间件
- 记录详细的错误日志
- 提供友好的错误响应

### 3. 性能优化

- 启用适当的缓存策略
- 使用连接池管理
- 监控服务器性能指标

### 4. 安全考虑

- 使用HTTPS加密传输
- 验证和清理用户输入
- 实施适当的访问控制

### 5. 测试策略

- 编写单元测试和集成测试
- 使用自动化测试脚本
- 进行性能和压力测试

## 🤝 贡献指南

欢迎为示例集合贡献新的功能和改进：

1. Fork项目仓库
2. 创建功能分支
3. 添加新示例或改进现有示例
4. 编写相应的测试和文档
5. 提交Pull Request

## 📞 支持与反馈

如果在使用示例过程中遇到问题或有改进建议，请：

1. 查看相关文档和FAQ
2. 在项目仓库提交Issue
3. 参与社区讨论
4. 联系维护团队

---

**Happy Coding! 🚀**