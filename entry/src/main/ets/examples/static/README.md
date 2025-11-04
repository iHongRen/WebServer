# Static File Server 示例

这个示例展示了如何使用 WebServer 创建一个功能完整的静态文件服务器。

## 功能特性

### 🗂️ 静态文件服务
- 自动 MIME 类型检测
- 文件缓存支持 (ETag, Last-Modified)
- 目录浏览功能
- 文件上传和删除

### 📊 访问统计
- 文件访问次数统计
- 热门文件排行
- 文件类型分布
- 小时访问统计
- 缓存命中率统计

### ⚙️ 配置管理
- 动态缓存配置
- 日志记录控制
- CORS 支持
- 自定义静态目录

## API 端点

### 静态文件访问
```
GET  /                      - 首页 (index.html)
GET  /css/style.css         - CSS 样式文件
GET  /js/app.js             - JavaScript 文件
GET  /data.json             - JSON 数据文件
GET  /docs/readme.txt       - 文档文件
```

### 文件管理 API
```
GET    /api/files           - 文件浏览器
POST   /api/upload          - 文件上传
DELETE /api/files/*         - 文件删除
GET    /api/file-info/*     - 文件信息
```

### 统计分析 API
```
GET    /api/stats           - 访问统计
GET    /api/access-log      - 访问日志
DELETE /api/access-log      - 清除日志
```

### 配置管理 API
```
GET    /api/config          - 获取配置
POST   /api/config/cache    - 更新缓存配置
```

## 使用示例

### 1. 启动服务器
```typescript
const context = getContext() as common.UIAbilityContext;
const staticExample = new StaticExample(context, {
  port: 8087,
  enableCache: true,
  maxAge: 3600
});

await staticExample.setupStaticFiles();
const serverInfo = await staticExample.start();
```

### 2. 文件上传
```bash
curl -X POST http://localhost:8087/api/upload \
  -F "file=@example.txt"
```

### 3. 获取访问统计
```bash
curl http://localhost:8087/api/stats
```

### 4. 更新缓存配置
```bash
curl -X POST http://localhost:8087/api/config/cache \
  -H "Content-Type: application/json" \
  -d '{"enableCache": true, "maxAge": 7200}'
```

## 配置选项

```typescript
interface StaticConfig {
  port: number;           // 服务器端口
  staticRoot: string;     // 静态文件根目录
  enableLogging: boolean; // 启用日志记录
  enableCors: boolean;    // 启用 CORS
  enableCache: boolean;   // 启用文件缓存
  maxAge: number;         // 缓存最大时间(秒)
}
```

## 文件结构

服务器会自动创建以下文件结构：

```
static/
├── index.html          # 主页
├── data.json          # JSON 数据
├── css/
│   └── style.css      # 样式文件
├── js/
│   └── app.js         # JavaScript 文件
├── images/            # 图片目录
└── docs/
    └── readme.txt     # 文档文件
```

## 缓存机制

- **ETag**: 基于文件内容的哈希值
- **Last-Modified**: 文件最后修改时间
- **Cache-Control**: 可配置的缓存时间
- **304 Not Modified**: 自动处理缓存验证

## 访问日志格式

每个文件访问都会记录以下信息：
- 文件路径
- 文件大小
- MIME 类型
- 客户端 IP
- User-Agent
- 响应时间
- 状态码
- 时间戳

## 注意事项

1. 文件上传会保存到静态目录
2. 访问日志最多保留 1000 条记录
3. 支持的文件类型由系统 MIME 类型决定
4. 缓存配置可以动态修改
5. 文件删除操作不可恢复

## 性能优化

- 启用文件缓存减少磁盘 I/O
- 使用 ETag 避免重复传输
- 压缩静态资源
- 设置合适的缓存时间