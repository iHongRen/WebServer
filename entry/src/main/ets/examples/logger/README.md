# Logger 示例

这个示例展示了如何使用 WebServer 的日志记录功能，包括多种日志格式、级别控制和统计分析。

## 功能特性

### 📝 多格式日志记录
- **dev**: 开发友好格式，带颜色标识
- **combined**: Apache Combined Log Format
- **common**: Apache Common Log Format  
- **short**: 简短格式
- **tiny**: 极简格式

### 🎯 日志级别控制
- **debug**: 调试信息
- **info**: 一般信息
- **warn**: 警告信息
- **error**: 错误信息

### 💾 日志存储
- 内存日志记录 (最多1000条)
- 文件日志存储
- 日志轮转支持

### 📊 统计分析
- 按级别统计
- 按HTTP方法统计
- 按状态码统计
- 平均响应时间
- 错误率计算

## API 端点

### 演示页面
```
GET  /logger-demo.html       - Logger演示页面
GET  /log-viewer.html        - 日志查看器
```

### 日志查询 API
```
GET    /api/logs             - 获取日志记录
GET    /api/logs/stats       - 获取日志统计
DELETE /api/logs             - 清除日志记录
```

### 日志配置 API
```
GET    /api/logs/config      - 获取日志配置
POST   /api/logs/config      - 更新日志配置
```

### 日志测试 API
```
POST   /api/logs/test/:level - 测试日志级别
GET    /api/test/slow        - 慢请求测试
GET    /api/test/error/:code - 错误请求测试
```

## 使用示例

### 1. 启动服务器
```typescript
const context = getContext() as common.UIAbilityContext;
const loggerExample = new LoggerExample(context, {
  port: 8085,
  logFormat: 'dev',
  logLevel: 'info',
  logToFile: true
});

await loggerExample.setupStaticFiles();
const serverInfo = await loggerExample.start();
```

### 2. 查询日志记录
```bash
# 获取最近50条日志
curl "http://localhost:8085/api/logs?limit=50"

# 按级别过滤
curl "http://localhost:8085/api/logs?level=error"

# 按HTTP方法过滤
curl "http://localhost:8085/api/logs?method=POST"
```

### 3. 获取日志统计
```bash
curl http://localhost:8085/api/logs/stats
```

### 4. 更新日志配置
```bash
curl -X POST http://localhost:8085/api/logs/config \
  -H "Content-Type: application/json" \
  -d '{
    "logFormat": "combined",
    "logLevel": "debug",
    "logToFile": true
  }'
```

### 5. 测试不同日志级别
```bash
# 测试错误日志
curl -X POST http://localhost:8085/api/logs/test/error \
  -H "Content-Type: application/json" \
  -d '{"message": "测试错误日志"}'

# 测试警告日志
curl -X POST http://localhost:8085/api/logs/test/warn \
  -d '{"message": "测试警告日志"}'
```

## 日志格式示例

### Dev 格式
```
🟢 GET /api/users 200 15ms - 1024b
🔴 POST /api/login 401 8ms - 256b
```

### Combined 格式
```
192.168.1.100 - - [2024-01-01T12:00:00.000Z] "GET /api/users HTTP/1.1" 200 1024 "http://example.com" "Mozilla/5.0..."
```

### Common 格式
```
192.168.1.100 - - [2024-01-01T12:00:00.000Z] "GET /api/users HTTP/1.1" 200 1024
```

### Short 格式
```
192.168.1.100 GET /api/users HTTP/1.1 200 1024 - 15ms
```

### Tiny 格式
```
GET /api/users 200 1024 - 15ms
```

## 配置选项

```typescript
interface LoggerConfig {
  port: number;                    // 服务器端口
  staticRoot: string;              // 静态文件根目录
  enableCors: boolean;             // 启用CORS
  logFormat: 'dev' | 'combined' | 'common' | 'short' | 'tiny';
  logLevel: 'debug' | 'info' | 'warn' | 'error';
  logToFile: boolean;              // 是否写入文件
  logFilePath: string;             // 日志文件路径
}
```

## 日志记录结构

```typescript
interface LogRecord {
  id: number;                      // 日志ID
  timestamp: Date;                 // 时间戳
  level: 'debug' | 'info' | 'warn' | 'error';
  method: string;                  // HTTP方法
  url: string;                     // 请求URL
  statusCode: number;              // 状态码
  responseTime: number;            // 响应时间(ms)
  userAgent: string;               // User-Agent
  ip: string;                      // 客户端IP
  message: string;                 // 日志消息
}
```

## 统计数据

日志统计包含以下信息：
- **总日志数**: 记录的日志总数
- **按级别统计**: debug/info/warn/error 各级别数量
- **按方法统计**: GET/POST/PUT/DELETE 等方法数量
- **按状态码统计**: 2xx/3xx/4xx/5xx 状态码分布
- **平均响应时间**: 所有请求的平均响应时间
- **错误率**: 4xx和5xx状态码的比例

## 性能监控

### 慢请求检测
```bash
# 模拟3秒慢请求
curl "http://localhost:8085/api/test/slow?delay=3000"
```

### 错误模拟
```bash
# 模拟404错误
curl http://localhost:8085/api/test/error/404

# 模拟500错误
curl http://localhost:8085/api/test/error/500
```

## 最佳实践

1. **生产环境**: 使用 `combined` 或 `common` 格式
2. **开发环境**: 使用 `dev` 格式便于调试
3. **日志级别**: 生产环境建议使用 `warn` 或 `error`
4. **文件日志**: 生产环境务必启用文件日志
5. **日志轮转**: 定期清理或归档日志文件
6. **性能考虑**: 高并发时考虑异步日志写入

## 注意事项

1. 内存日志最多保留1000条记录
2. 文件日志会追加写入，需要定期清理
3. 日志级别过滤在记录时生效
4. 响应时间精度为毫秒
5. IP地址可能是代理服务器地址
6. User-Agent可能被客户端伪造