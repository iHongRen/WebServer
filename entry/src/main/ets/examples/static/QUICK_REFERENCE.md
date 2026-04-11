# 多站点静态服务快速参考

## 基本用法

### 注册站点
```typescript
server.registerStaticSite('/prefix', '/path/to/root', {
  maxAge: 3600,              // 缓存时间（秒）
  index: ['index.html'],     // 索引文件
  directoryListing: false    // 目录浏览
});
```

### 启用多站点
```typescript
server.serveMultiSite();
```

### 完整示例
```typescript
import { HttpServer } from '@cxy/webserver';

const server = new HttpServer();

// 注册多个站点
server.registerStaticSite('/docs', '/var/www/docs', {
  maxAge: 3600,
  directoryListing: false
});

server.registerStaticSite('/gallery', '/var/www/gallery', {
  maxAge: 7200,
  directoryListing: true
});

// 启用多站点服务
server.serveMultiSite();

// 启动服务器
await server.startServer(8080);
```

## 配置选项

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `maxAge` | number | 3600 | 缓存时间（秒） |
| `index` | string[] | `['index.html', 'index.htm']` | 索引文件列表 |
| `directoryListing` | boolean | false | 是否启用目录浏览 |

## 站点管理

```typescript
// 获取所有站点
const sites = server.getStaticSites();

// 注销站点
server.unregisterStaticSite('/docs');
```

## 路由规则

```
请求: /docs/guide.html
匹配: /docs 站点

请求: /docs/api/reference.html
匹配: /docs 站点（处理 /api/reference.html）

请求: /gallery/
匹配: /gallery 站点（查找索引文件）

请求: /other.html
不匹配任何站点，传递给下一个中间件
```

## 缓存策略

```typescript
// 静态资源（长期缓存）
server.registerStaticSite('/assets', '/var/www/assets', {
  maxAge: 31536000  // 1年
});

// 动态内容（短期缓存）
server.registerStaticSite('/news', '/var/www/news', {
  maxAge: 300  // 5分钟
});

// 开发环境（不缓存）
server.registerStaticSite('/dev', '/var/www/dev', {
  maxAge: 0
});
```

## 常见场景

### 企业网站 + 文档
```typescript
server.registerStaticSite('/', '/var/www/main');
server.registerStaticSite('/docs', '/var/www/docs');
server.serveMultiSite();
```

### 多版本API文档
```typescript
server.registerStaticSite('/api/v1', '/docs/api/v1');
server.registerStaticSite('/api/v2', '/docs/api/v2');
server.serveMultiSite();
```

### 多语言网站
```typescript
server.registerStaticSite('/zh', '/var/www/zh');
server.registerStaticSite('/en', '/var/www/en');
server.serveMultiSite();
```

## API端点

```bash
# 获取所有站点信息
GET /api/sites

# 响应示例
{
  "total": 2,
  "sites": [
    {
      "prefix": "/docs",
      "root": "/var/www/docs",
      "maxAge": 3600,
      "directoryListing": false,
      "index": ["index.html"]
    }
  ]
}
```

## 测试命令

```bash
# 访问站点
curl http://localhost:8080/docs/

# 测试目录浏览
curl http://localhost:8080/gallery/photos/

# 获取站点信息
curl http://localhost:8080/api/sites

# 测试缓存
curl -I http://localhost:8080/docs/

# 运行完整测试
./test-multi-site.sh
```

## 故障排查

### 站点无法访问
```typescript
// 1. 检查站点是否已注册
console.log(server.getStaticSites());

// 2. 确认已调用 serveMultiSite()
server.serveMultiSite();

// 3. 检查路径前缀（需要前导斜杠）
server.registerStaticSite('/site1', '/path');  // ✅ 正确
server.registerStaticSite('site1', '/path');   // ❌ 错误
```

### 缓存问题
```typescript
// 清空缓存
StaticFiles.clearCache();

// 查看缓存统计
const stats = StaticFiles.getCacheStats();
console.log(stats);
```

### 目录浏览不工作
```typescript
// 确认配置
server.registerStaticSite('/gallery', '/path', {
  directoryListing: true  // ✅ 必须启用
});
```

## 性能提示

1. **合理设置缓存时间**
   - 静态资源：1天-1年
   - 动态内容：5分钟-1小时
   - 开发环境：禁用缓存

2. **站点数量**
   - 建议不超过20个站点
   - 过多站点会影响路由性能

3. **目录浏览**
   - 仅在必要时启用
   - 大目录会影响响应时间

## 安全提示

1. **路径遍历防护**
   - 自动检测 `..` 路径
   - 返回400错误

2. **目录浏览权限**
   - 默认禁用
   - 仅在安全目录启用

3. **文件访问控制**
   - 确保根目录权限正确
   - 避免暴露敏感文件

## 更多资源

- [README.md](./README.md) - 快速开始
- [静态文件服务中间件说明.md](./静态文件服务中间件说明.md) - 基础说明
- [多站点静态服务使用指南.md](./多站点静态服务使用指南.md) - 详细指南
- [StaticExample.ets](./StaticExample.ets) - 完整代码
