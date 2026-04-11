# 静态文件服务示例

## 功能特性

本示例展示了WebServer的静态文件服务功能，包括：

### 1. 单站点模式
- 传统的单一静态文件目录服务
- 支持缓存控制
- 自动索引文件查找

### 2. 多站点模式（新功能）
- 支持多个独立的静态站点
- 每个站点有独立的URL前缀和根目录
- 站点级别的配置（缓存、索引文件、目录浏览）
- 最长前缀匹配路由算法
- 统一的缓存管理

### 3. 目录浏览
- 可选的目录浏览功能
- 美观的HTML文件列表
- 文件大小和修改时间显示

### 4. 文件管理API
- 文件浏览器API
- 文件上传API
- 文件删除API
- 站点管理API

## 示例站点

本示例创建了4个站点：

### 主站点 (/)
- 路径：`/`
- 功能：主页和导航
- 缓存：禁用（开发模式）

### 站点1 - 文档中心 (/site1)
- 路径：`/site1`
- 功能：文档和指南
- 缓存：1小时
- 目录浏览：禁用

### 站点2 - 图片画廊 (/site2)
- 路径：`/site2`
- 功能：图片展示
- 缓存：2小时
- 目录浏览：启用

### 站点3 - API文档 (/site3)
- 路径：`/site3`
- 功能：API文档和规范
- 缓存：30分钟
- 目录浏览：启用

## 快速开始

### 1. 启动服务器

在应用中运行 `StaticExample`：

```typescript
import { StaticExample } from './examples/static/StaticExample';

const example = new StaticExample();
example.init(context);
await example.start(8080);
```

### 2. 访问站点

打开浏览器访问：
- 主站点：`http://127.0.0.1:8080/`
- 文档中心：`http://127.0.0.1:8080/site1/`
- 图片画廊：`http://127.0.0.1:8080/site2/`
- API文档：`http://127.0.0.1:8080/site3/`

### 3. 测试API

```bash
# 获取所有站点信息
curl http://127.0.0.1:8080/api/sites

# 浏览文件
curl http://127.0.0.1:8080/api/files

# 上传文件
curl -X POST -F "file=@test.txt" http://127.0.0.1:8080/api/upload
```

### 4. 运行测试脚本

```bash
chmod +x test-multi-site.sh
./test-multi-site.sh
```

## 文件结构

```
static/
├── StaticExample.ets              # 示例实现
├── StaticPage.ets                 # UI页面
├── README.md                      # 本文件
├── 静态文件服务中间件说明.md      # 基础说明
├── 多站点静态服务使用指南.md      # 详细指南
├── test-static-api.sh             # 单站点测试
└── test-multi-site.sh             # 多站点测试
```

## 核心代码

### 注册多个站点

```typescript
// 站点1：文档中心
server.registerStaticSite('/site1', site1Root, {
  maxAge: 3600,
  index: ['index.html'],
  directoryListing: false
});

// 站点2：图片画廊
server.registerStaticSite('/site2', site2Root, {
  maxAge: 7200,
  index: ['index.html'],
  directoryListing: true
});

// 站点3：API文档
server.registerStaticSite('/site3', site3Root, {
  maxAge: 1800,
  index: ['index.html', 'index.htm'],
  directoryListing: true
});

// 启用多站点服务
server.serveMultiSite();
```

### 站点管理

```typescript
// 获取所有站点
const sites = server.getStaticSites();

// 注销站点
server.unregisterStaticSite('/site1');
```

## API端点

### 站点管理
- `GET /api/sites` - 获取所有站点信息

### 文件管理
- `GET /api/files?path=<path>` - 浏览文件
- `POST /api/upload` - 上传文件
- `DELETE /api/files/<path>` - 删除文件

## 配置选项

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `maxAge` | number | 3600 | 缓存时间（秒） |
| `index` | string[] | `['index.html', 'index.htm']` | 索引文件列表 |
| `directoryListing` | boolean | false | 是否启用目录浏览 |

## 性能特性

- **统一缓存**：所有站点共享缓存池
- **ETag支持**：自动生成和验证ETag
- **304响应**：支持客户端缓存验证
- **最长匹配**：高效的路由匹配算法

## 安全特性

- **路径遍历防护**：自动检测和阻止 `..` 路径
- **站点隔离**：每个站点独立，互不影响
- **可控目录浏览**：默认禁用，按需启用

## 使用场景

1. **企业网站**：主站 + 文档中心 + 博客
2. **API服务**：多版本API文档托管
3. **多语言网站**：不同语言的独立站点
4. **开发环境**：前端项目 + 后端文档 + 测试页面

## 更多信息

- [静态文件服务中间件说明.md](./静态文件服务中间件说明.md) - 基础使用
- [多站点静态服务使用指南.md](./多站点静态服务使用指南.md) - 详细指南
- [StaticExample.ets](./StaticExample.ets) - 完整代码

## 故障排查

### 站点无法访问
1. 检查站点是否已注册：`server.getStaticSites()`
2. 确认已调用：`server.serveMultiSite()`
3. 检查路径前缀格式（需要前导斜杠）

### 缓存问题
- 清空缓存：`StaticFiles.clearCache()`
- 查看统计：`StaticFiles.getCacheStats()`

### 目录浏览不工作
1. 确认 `directoryListing: true`
2. 检查目录存在且有权限
3. 确认没有索引文件（否则会优先显示索引）

## 贡献

欢迎提交问题和改进建议！
