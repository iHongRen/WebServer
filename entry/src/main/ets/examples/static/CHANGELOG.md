# 静态文件服务更新日志

## [2.0.0] - 2026-04-11

### 新增功能 🎉

#### 多站点静态文件服务
- 支持在同一服务器上托管多个独立的静态网站
- 每个站点有独立的URL路径前缀和根目录
- 站点级别的配置（缓存、索引文件、目录浏览）
- 最长前缀匹配路由算法
- 统一的缓存管理

#### 目录浏览功能
- 可选的目录浏览功能（`directoryListing: true`）
- 美观的HTML文件列表界面
- 显示文件大小和修改时间
- 文件夹和文件图标区分
- 响应式设计

#### 站点管理API
- `registerStaticSite()` - 注册新站点
- `unregisterStaticSite()` - 注销站点
- `getStaticSites()` - 获取所有站点信息
- `serveMultiSite()` - 启用多站点服务

### 改进 ✨

#### 索引文件查找
- 支持多个索引文件（如 `['index.html', 'index.htm']`）
- 按顺序查找，找到第一个存在的文件
- 未找到索引文件时，可选择显示目录列表或404

#### 缓存策略
- 站点级别的缓存配置
- 所有站点共享缓存池，提高效率
- 支持ETag验证和304响应

#### 安全性
- 路径遍历攻击防护（检测 `..` 路径）
- 站点隔离（每个站点独立的根目录）
- 可控的目录浏览权限

### 示例更新 📝

#### StaticExample.ets
- 创建4个独立站点的完整示例
- 主站点：主页和导航
- 站点1：文档中心（禁用目录浏览）
- 站点2：图片画廊（启用目录浏览）
- 站点3：API文档（启用目录浏览）
- 新增站点管理API端点

### 文档 📚

#### 新增文档
- `README.md` - 快速开始指南
- `多站点静态服务使用指南.md` - 详细使用指南
- `test-multi-site.sh` - 多站点测试脚本

#### 更新文档
- `静态文件服务中间件说明.md` - 添加多站点模式说明

### API变更 🔧

#### 新增API
```typescript
// HttpServer类
server.registerStaticSite(prefix: string, root: string, options?: {
  maxAge?: number;
  index?: string[];
  directoryListing?: boolean;
})
server.serveMultiSite()
server.unregisterStaticSite(prefix: string): boolean
server.getStaticSites(): StaticSiteConfig[]

// StaticFiles类
StaticFiles.registerSite(config: StaticSiteConfig): void
StaticFiles.unregisterSite(prefix: string): boolean
StaticFiles.getSites(): StaticSiteConfig[]
StaticFiles.serveMultiSite(): RequestHandler
```

#### 新增类型
```typescript
interface StaticSiteConfig extends CacheOptions {
  root: string;
  prefix: string;
  index?: string[];
  directoryListing?: boolean;
}
```

### 兼容性 ✅

- ✅ 向后兼容：保留原有的 `serveStatic()` 方法
- ✅ 渐进增强：可选择使用多站点功能
- ✅ 灵活组合：可同时使用单站点和多站点模式

### 测试 🧪

- ✅ 16个测试用例覆盖所有功能
- ✅ 主站点和子站点访问测试
- ✅ 目录浏览功能测试
- ✅ 缓存控制验证
- ✅ 404错误处理测试
- ✅ 站点管理API测试

### 性能 ⚡

- 统一缓存池，减少内存占用
- 最长前缀匹配算法，O(n)时间复杂度
- ETag支持，减少不必要的数据传输
- 站点预排序，优化路由匹配

### 使用场景 💡

1. **企业网站**：主站 + 文档中心 + 博客
2. **API服务**：多版本API文档托管
3. **多语言网站**：不同语言的独立站点
4. **开发环境**：前端项目 + 后端文档 + 测试页面

---

## [1.0.0] - 2025-10-29

### 初始版本

- 基础静态文件服务
- 单一根目录支持
- 缓存控制
- ETag支持
- 文件浏览器API
- 文件上传API
- 文件删除API
