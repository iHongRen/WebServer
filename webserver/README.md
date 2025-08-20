
![Version](https://img.shields.io/badge/version-1.0.0-blue)  ![License](https://img.shields.io/badge/License-Apache%202.0-green.svg) ![GitHub Stars](https://img.shields.io/github/stars/iHongRen/WebServer.svg?style=social)



# WebServer - 鸿蒙Web服务器框架

这是一个基于 HarmonyOS 的轻量级Web服务器框架，提供了类似 Express.js 的 API 设计，支持路由、中间件、静态文件服务等功能。



## 特性

- 类 Express.js 的 API 设计

- 支持路由参数和查询字符串

- 内置多种请求体解析器

- CORS 跨域支持

- 静态文件服务

- 文件上传支持

- 缓存控制

- 错误处理

- 中间件系统

- 多种日志格式支持



##  安装

```sh
ohpm install @cxy/webserver
```

或`oh-package.json5` 添加依赖，然后同步项目

```json
{
  "dependencies": {
    "@cxy/webserver": "^1.0.0"
  }
}
```



## 快速开始

```typescript
import { WebServer } from '@cxy/webserver';

this.server = new WebServer();

// 注册 GET / 接口
this.server.get('/', (req, res, next) => {
  res.status(200).json({
    message: '欢迎使用 WebServer'
  })
})

// 在8080端口 启动服务器
const info = await this.server.startServer(8080);
if (info.address) {
   console.log(`http://${info.address}:${info.port}`)   
} else {
  console.error("启动失败，未获取到地址");
}

// 访问：http://设备的ip:8080/   
```



## 更多示例

```typescript
import { WebServer } from '@cxy/webserver';

this.server = new WebServer();

// --- 1. 中间件注册 ---
// 日志记录, 顺序很重要，通常日志和CORS最先，然后是请求体解析，再是静态文件和路由
this.server.logger({
  stream: (log: string) => {
    console.log(log)
  }
}) 
this.server.cors(); //支持跨域
this.server.json(); // 解析 application/json
this.server.urlencoded(); // 解析 application/x-www-form-urlencoded
this.server.multipart(); // 解析 multipart/form-data (用于文件上传)
this.server.serveStatic(this.staticFilesRoot); // 提供静态文件服务

// --- 2. 模拟数据 ---
const users: User[] = [
  { id: 1, name: 'cxy' },
  { id: 2, name: 'ihongren' }
];
let nextUserId = 3;


// --- 3. API 示例 ---
// GET /api/users - 获取所有用户
this.server.get('/api/users', (req, res) => {
  res.json(users);
});

// GET /api/users/:id - 使用路由参数，获取单个用户
this.server.get('/api/users/:id', (req, res) => {
  const user = users.find(u => u.id === parseInt(req.params.id));
  if (user) {
    res.json(user);
  } else {
    res.status(404).json({ error: 'User not found' });
  }
});

// POST /api/users - 创建新用户
this.server.post('/api/users', (req, res) => {
  const newUser: User = {
    id: nextUserId++,
    name: (req.body as Record<string, string>).name || 'Unnamed'
  };
  users.push(newUser);
  console.log('Created new user:', JSON.stringify(newUser));
  res.status(201).json(newUser);
});

// post /api/users/:id - 更新用户
this.server.post('/api/users/:id', (req, res) => {
  const userId = parseInt(req.params.id);
  const userIndex = users.findIndex(u => u.id === userId);
  if (userIndex !== -1) {
    users[userIndex].name = (req.body as Record<string, string>).name || users[userIndex].name;
    res.json(users[userIndex]);
  } else {
    res.status(404).json({ error: 'User not found' });
  }
});

// --- 4. 文件上传路由 ---
this.server.post('/api/upload', async (req, res, next) => {
  try {
    const uploadedFile = req.files?.uploadFile; // 'uploadFile' 对应 HTML form 中的 input name
    if (!uploadedFile) {
      return res.status(400).json({ error: 'No file uploaded.' });
    }

    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const tempPath = `${context.filesDir}/${uploadedFile.fileName}`;
    const f = await fileIo.open(tempPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
    await fileIo.write(f.fd, uploadedFile.data);

    console.log(`File uploaded successfully: ${uploadedFile.fileName}`);
    res.json({
      message: 'File uploaded successfully!',
      filename: uploadedFile.fileName,
      size: uploadedFile.data.byteLength,
      contentType: uploadedFile.contentType,
      savedTo: tempPath
    });
  } catch (error) {
    next(error);
  }
});

// --- 5. 其他高级示例 ---
// 路由参数示例
this.server.get('/users/:userId/books/:bookId', (req, res) => {
  res.json({
    message: `You requested book ${req.params.bookId} for user ${req.params.userId}.`
  });
});

// 自定义响应头示例
this.server.get('/api/custom-header', (req, res) => {
  res.setHeader('X-Custom-Header', 'Hello from WebServer!');
  res.json({ message: 'Check the response headers!' });
});

// 错误触发示例
this.server.get('/crash', (req, res, next) => {
  // 故意抛出一个错误来测试错误处理中间件
  throw new Error('This is a simulated crash!');
});

// --- 6. 统一错误处理中间件 (必须在路由之后注册) ---
const customErrorHandler: ErrorHandler = (error, req, res, next) => {
  console.error(`[WebServer Error] Path: ${req.path}, Message: ${error.message}`);
  if (res.isHeadersSent()) {
    return next(error); // 如果头已发送，则委托给默认错误处理器
  }
  res.status(500).json({
    error: 'Internal Server Error',
    message: error.message || 'An unknown error occurred.'
  });
};

this.server.use(customErrorHandler);


// 停止服务器
await this.server.stopServer();
```



## 运行 [demo](https://github.com/iHongRen/WebServer)

| 未开启服务 | 已开启服务 |
| :-: | :-: |
|<img src="https://7up.pics/images/2025/08/20/Screenshot_20250820150234282.jpeg" /> | <img src="https://7up.pics/images/2025/08/20/app.jpeg" /> |

浏览器访问：http://192.168.xx.xx:8080
<img src="https://7up.pics/images/2025/08/20/E4DAB553-8134-44F9-8C00-B97C1C2FEFC4.png" alt="E4DAB553 8134 44F9 8C00 B97C1C2FEFC4" border="0" style="display: inline-block;">


# WebServer API [文档](https://github.com/iHongRen/WebServer)


### WebServer 类

Web服务器主类，提供HTTP服务器功能。


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
- `logger()` - 启用日志中间件（开发环境格式）
- `loggerWithFormat(format: LogFormat)` - 启用自定义格式的日志中间件
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

### Logger 类

日志中间件，提供HTTP请求日志记录功能。

- `static create(options?: LoggerOptions): RequestHandler` - 创建自定义日志中间件
- `static dev(): RequestHandler` - 开发环境日志格式
- `static combined(): RequestHandler` - 生产环境日志格式（Apache Combined）
- `static common(): RequestHandler` - 通用日志格式（Apache Common）
- `static short(): RequestHandler` - 简短日志格式
- `static tiny(): RequestHandler` - 最简日志格式

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
- `LoggerOptions` - 日志配置选项
- `ServerInfo` - 服务器信息接口

### 枚举定义

- `LogFormat` - 日志格式枚举（DEV, TINY, SHORT, COMMON, COMBINED）



❓如果是使用过程中有什么问题，欢迎提 [issues](https://github.com/iHongRen/WebServer/issues)



# 作者

[@仙银](https://github.com/iHongRen) 鸿蒙相关开源作品

1、[hpack](https://github.com/iHongRen/hpack) - 鸿蒙内部测试分发，一键脚本打包工具

2、[Open-in-DevEco-Studio](https://github.com/iHongRen/Open-in-DevEco-Studio)  - macOS 直接在 Finder 工具栏上，使用
DevEco-Studio 打开鸿蒙工程。

3、[cxy-theme](https://github.com/iHongRen/cxy-theme) - DevEco-Studio 绿色背景主题

4、[harmony-udid-tool](https://github.com/iHongRen/harmony-udid-tool) -  简单易用的 HarmonyOS 设备 UDID 获取工具，适用于非开发人员。

5、[SandboxFinder](https://github.com/iHongRen/SandboxFinder) - 鸿蒙沙箱文件浏览器

6、[WebServer](https://github.com/iHongRen/WebServer) - 鸿蒙轻量级Web服务器框架



🌟 如果项目对你有帮助，欢迎持续关注和 Star ，[赞助](https://ihongren.github.io/donate.html)