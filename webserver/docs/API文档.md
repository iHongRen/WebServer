# WebServer API 文档

## 概述

这是一个基于HarmonyOS的轻量级Web服务器框架，提供了类似Express.js的API设计，支持路由、中间件、静态文件服务等功能。

## 核心类

### WebServer 类

Web服务器主类，提供HTTP服务器功能。

#### 构造函数
```typescript
constructor()
```
初始化服务器并设置默认404处理。

#### 主要方法

- `setConfig(key: string, value: Object)` - 设置配置项
- `getConfig(key: string): Object | undefined` - 获取配置项
- `use(handler: RequestHandler | ErrorHandler)` - 注册中间件
- `get(path: string, handler: RequestHandler)` - 注册GET路由
- `post(path: string, handler: RequestHandler)` - 注册POST路由
- `json()` - 启用JSON请求体解析
- `urlencoded()` - 启用URL编码请求体解析
- `multipart()` - 启用多部分表单解析
- `serveStatic(directoryPath: string, options?: CacheOptions)` - 启用静态文件服务
- `cors(options?: CorsOptions)` - 启用CORS跨域支持
- `startServer(port: number): Promise<ServerInfo>` - 启动服务器
- `stopServer(): Promise<void>` - 停止服务器

### HttpRequest 类

HTTP请求解析类，包含请求的所有信息。

#### 主要属性

- `method: string` - HTTP请求方法
- `path: string` - 请求路径
- `url: string` - 完整URL路径
- `ip: string` - 客户端IP地址
- `headers: Map<string, string>` - 请求头集合
- `body: any` - 解析后的请求体数据
- `query: Map<string, string>` - 查询字符串参数
- `params: Record<string, string>` - 路由参数
- `files: Record<string, File>` - 上传的文件

#### 主要方法

- `parseBody(): void` - 解析请求体数据
- `getRawBody(): ArrayBuffer` - 获取原始请求体数据
- `get(headerName: string): string | undefined` - 获取请求头
- `is(type: string): boolean` - 检查Content-Type
- `get userAgent(): string` - 获取User-Agent
- `get contentLength(): number` - 获取Content-Length

### HttpResponse 类

HTTP响应构建类，用于构建和发送响应。

#### 主要方法

- `isHeadersSent(): boolean` - 检查响应头是否已发送
- `setHeader(name: string, value: string): HttpResponse` - 设置响应头
- `status(code: number): HttpResponse` - 设置HTTP状态码
- `send(body?: string | ArrayBuffer): Promise<void>` - 发送响应数据
- `json(data: ESObject): Promise<void>` - 发送JSON响应

### Router 类

路由管理器，负责路由的注册、匹配和执行。

#### 主要方法

- `addRoute(method: string, path: string, handler: RequestHandler | ErrorHandler)` - 添加路由
- `handle(req: HttpRequest, res: HttpResponse)` - 处理HTTP请求
- `getRoutes(): Route[]` - 获取所有路由

## 中间件

### BodyParser 类

请求体解析中间件。

- `static json(): RequestHandler` - JSON解析中间件
- `static urlencoded(): RequestHandler` - URL编码解析中间件
- `static multipart(): RequestHandler` - 多部分表单解析中间件
- `static auto(): RequestHandler` - 通用解析中间件

### Cors 类

CORS跨域资源共享中间件。

- `static create(options?: CorsOptions): RequestHandler` - 创建CORS中间件

### StaticFiles 类

静态文件服务中间件。

- `static serve(directoryPath: string, options?: CacheOptions): RequestHandler` - 创建静态文件服务中间件

## 工具类

### Utils 类

通用工具类，提供各种实用方法。

- `static arrayBufferToStr(arr: ArrayBuffer): string` - ArrayBuffer转字符串
- `static strToArrayBuffer(str: string): ArrayBuffer` - 字符串转ArrayBuffer
- `static mergeArrayBuffers(buffer1: ArrayBuffer, buffer2: ArrayBuffer): ArrayBuffer` - 合并ArrayBuffer
- `static getMimeType(filePath: string): string` - 获取MIME类型
- `static normalizePath(path: string): string` - 规范化路径
- `static joinPath(...paths: string[]): string` - 拼接路径
- `static sanitizeFilename(filename: string): string` - 清理文件名

## 类型定义

### 函数类型

- `NextFunction` - 下一步函数类型
- `RequestHandler` - 请求处理函数类型
- `ErrorHandler` - 错误处理函数类型

### 接口定义

- `File` - 上传文件接口
- `Route` - 路由接口
- `CorsOptions` - CORS配置选项
- `CacheOptions` - 缓存配置选项
- `ServerInfo` - 服务器信息接口

## 使用示例

```typescript
import { WebServer } from './WebServer';

const app = new WebServer();

// 启用中间件
app.json();
app.cors();
app.serveStatic('/static');

// 注册路由
app.get('/', (req, res) => {
  res.json({ message: 'Hello World!' });
});

app.post('/api/data', (req, res) => {
  console.log('收到数据:', req.body);
  res.json({ success: true });
});

// 启动服务器
app.startServer(3000).then(info => {
  console.log(`服务器启动成功: http://${info.address}:${info.port}`);
});
```

## 特性

- ✅ 类Express.js的API设计
- ✅ 支持路由参数和查询字符串
- ✅ 内置多种请求体解析器
- ✅ CORS跨域支持
- ✅ 静态文件服务
- ✅ 文件上传支持
- ✅ 缓存控制
- ✅ 错误处理
- ✅ 中间件系统
- ✅ 完整的中文注释