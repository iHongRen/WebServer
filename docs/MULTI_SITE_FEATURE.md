# WebServer 多站点静态文件服务功能

## 功能概述

为WebServer添加了多静态子站点功能，允许在同一个服务器上托管多个独立的静态网站。

## 设计特点

### 1. 优秀的架构设计

#### 站点配置接口
```typescript
export interface StaticSiteConfig extends CacheOptions {
  root: string;              // 站点根目录
  prefix: string;            // URL路径前缀
  index?: string[];          // 默认索引文件列表
  directoryListing?: boolean; // 是否启用目录浏览
}
```

#### 核心功能
- **多站点注册**：`registerSite(config)` - 注册新站点
- **站点注销**：`unregisterSite(prefix)` - 移除站点
- **站点查询**：`getSites()` - 获取所有站点
- **多站点服务**：`serveMultiSite()` - 创建多站点中间件

### 2. 路由匹配算法

采用**最长前缀匹配**算法：
- 站点按前缀长度降序排序
- 优先匹配最长的前缀
- 确保精确的路由分发

```typescript
// 示例
/site1/page.html     -> 匹配 /site1 站点
/site1/sub/page.html -> 匹配 /site1 站点
/site2/              -> 匹配 /site2 站点
/other.html          -> 不匹配，传递给下一个中间件
```

### 3. 统一缓存管理

- 所有站点共享同一个缓存池
- 基于文件路径的缓存键
- 支持ETag验证
- 自动缓存失效

### 4. 目录浏览功能

当启用 `directoryListing: true` 时：
- 自动生成美观的HTML文件列表
- 显示文件大小和修改时间
- 支持文件夹图标和文件图标
- 响应式设计

### 5. 安全性

- **路径遍历防护**：自动检测和阻止 `..` 路径
- **站点隔离**：每个站点独立，互不影响
- **可控访问**：目录浏览默认禁用

## 核心代码修改

### 1. staticFiles.ets

新增功能：
- `StaticSiteConfig` 接口
- `registerSite()` - 注册站点
- `unregisterSite()` - 注销站点
- `getSites()` - 获取站点列表
- `serveMultiSite()` - 多站点中间件
- `sendDirectoryListing()` - 目录浏览
- `generateDirectoryListingHTML()` - 生成HTML
- `formatFileSize()` - 格式化文件大小

### 2. HttpServer.ets

新增方法：
- `registerStaticSite()` - 注册站点
- `serveMultiSite()` - 启用多站点服务
- `unregisterStaticSite()` - 注销站点
- `getStaticSites()` - 获取站点列表

### 3. middleware/index.ets

新增导出：
- `StaticSiteConfig` 类型

## 示例实现

### StaticExample.ets

完整的多站点示例，包括：

#### 4个独立站点
1. **主站点** (`/`) - 主页和导航
2. **站点1** (`/site1`) - 文档中心
3. **站点2** (`/site2`) - 图片画廊（启用目录浏览）
4. **站点3** (`/site3`) - API文档（启用目录浏览）

#### 站点配置
```typescript
// 站点1：文档中心
server.registerStaticSite('/site1', site1Root, {
  maxAge: 3600,              // 1小时缓存
  index: ['index.html'],
  directoryListing: false
});

// 站点2：图片画廊
server.registerStaticSite('/site2', site2Root, {
  maxAge: 7200,              // 2小时缓存
  index: ['index.html'],
  directoryListing: true     // 启用目录浏览
});

// 站点3：API文档
server.registerStaticSite('/site3', site3Root, {
  maxAge: 1800,              // 30分钟缓存
  index: ['index.html', 'index.htm'],
  directoryListing: true
});

// 启用多站点服务
server.serveMultiSite();
```

#### 管理API
- `GET /api/sites` - 获取所有站点信息
- `GET /api/files` - 文件浏览器
- `POST /api/upload` - 文件上传
- `DELETE /api/files/*` - 文件删除

## 文档

### 1. README.md
- 快速开始指南
- 功能特性概述
- API端点说明
- 故障排查

### 2. 静态文件服务中间件说明.md
- 单站点模式使用
- 多站点模式使用
- 配置选项说明
- 测试用例

### 3. 多站点静态服务使用指南.md
- 详细的使用指南
- 高级功能说明
- 性能优化建议
- 安全注意事项
- 完整的使用场景

### 4. 测试脚本

#### test-multi-site.sh
完整的测试脚本，包括：
- 主站点测试
- 各子站点测试
- 目录浏览测试
- 缓存头验证
- 404错误测试
- 站点管理API测试

## 使用场景

### 1. 企业网站 + 文档中心
```typescript
server.registerStaticSite('/', '/var/www/main');
server.registerStaticSite('/docs', '/var/www/docs');
server.registerStaticSite('/blog', '/var/www/blog');
server.serveMultiSite();
```

### 2. 多版本API文档
```typescript
server.registerStaticSite('/api/v1', '/docs/api/v1');
server.registerStaticSite('/api/v2', '/docs/api/v2');
server.registerStaticSite('/api/v3', '/docs/api/v3');
server.serveMultiSite();
```

### 3. 多语言网站
```typescript
server.registerStaticSite('/zh', '/var/www/zh');
server.registerStaticSite('/en', '/var/www/en');
server.registerStaticSite('/ja', '/var/www/ja');
server.serveMultiSite();
```

### 4. 开发环境
```typescript
server.registerStaticSite('/frontend', '/project/dist');
server.registerStaticSite('/docs', '/project/docs');
server.registerStaticSite('/test', '/project/test-pages');
server.serveMultiSite();
```

## 性能特性

1. **统一缓存池**
   - 所有站点共享缓存
   - 减少内存占用
   - 提高缓存命中率

2. **高效路由**
   - 最长前缀匹配
   - O(n) 时间复杂度（n为站点数）
   - 预排序优化

3. **ETag支持**
   - 自动生成ETag
   - 客户端缓存验证
   - 304 Not Modified响应

4. **灵活配置**
   - 站点级别的缓存策略
   - 独立的索引文件配置
   - 可选的目录浏览

## 安全特性

1. **路径遍历防护**
   ```typescript
   if (requestedPath.includes('..')) {
     res.status(400).send('Invalid Path');
     return;
   }
   ```

2. **站点隔离**
   - 每个站点有独立的根目录
   - 无法跨站点访问文件

3. **可控目录浏览**
   - 默认禁用
   - 按站点配置
   - 防止信息泄露

## 测试验证

### 运行测试
```bash
chmod +x entry/src/main/ets/examples/static/test-multi-site.sh
./entry/src/main/ets/examples/static/test-multi-site.sh
```

### 测试覆盖
- ✅ 主站点访问
- ✅ 子站点访问
- ✅ 目录浏览功能
- ✅ 缓存控制
- ✅ ETag验证
- ✅ 404处理
- ✅ 站点管理API
- ✅ 路径遍历防护

## 兼容性

- ✅ 向后兼容：保留原有的 `serveStatic()` 方法
- ✅ 渐进增强：可选择使用多站点功能
- ✅ 灵活组合：可同时使用单站点和多站点模式

## 文件清单

### 核心代码
- `webserver/src/main/ets/middleware/staticFiles.ets` - 静态文件中间件（已更新）
- `webserver/src/main/ets/HttpServer.ets` - HTTP服务器（已更新）
- `webserver/src/main/ets/middleware/index.ets` - 中间件导出（已更新）

### 示例代码
- `entry/src/main/ets/examples/static/StaticExample.ets` - 完整示例（已更新）
- `entry/src/main/ets/examples/static/StaticPage.ets` - UI页面（保持不变）

### 文档
- `entry/src/main/ets/examples/static/README.md` - 快速开始（新增）
- `entry/src/main/ets/examples/static/静态文件服务中间件说明.md` - 基础说明（已更新）
- `entry/src/main/ets/examples/static/多站点静态服务使用指南.md` - 详细指南（新增）

### 测试
- `entry/src/main/ets/examples/static/test-multi-site.sh` - 多站点测试脚本（新增）
- `entry/src/main/ets/examples/static/test-static-api.sh` - 单站点测试脚本（保持不变）

## 总结

成功为WebServer添加了企业级的多站点静态文件服务功能，具有：

✅ **优秀的设计**
- 清晰的接口定义
- 灵活的配置选项
- 高效的路由算法

✅ **完善的功能**
- 多站点管理
- 目录浏览
- 缓存控制
- 安全防护

✅ **详细的文档**
- 快速开始指南
- 详细使用说明
- 完整的示例代码
- 测试脚本

✅ **良好的兼容性**
- 向后兼容
- 渐进增强
- 灵活组合

该功能适用于各种场景，从简单的多页面网站到复杂的多版本文档系统，为开发者提供了强大而灵活的静态文件托管解决方案。
