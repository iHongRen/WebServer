![Version](https://img.shields.io/badge/version-2.0.1-blue)  ![License](https://img.shields.io/badge/License-Apache%202.0-green.svg) ![GitHub Stars](https://img.shields.io/github/stars/iHongRen/WebServer.svg?style=social)

# WebServer - 鸿蒙Web服务器框架

这是一个基于 HarmonyOS 的轻量级Web服务器框架，提供了类似 Express.js 的 API 设计，支持路由、中间件、静态文件服务等功能。

## 特性

- 类 Express.js 的 API 设计
- 支持 https
- 支持路由参数和查询字符串
- CORS 跨域支持
- 静态文件服务
- 文件上传支持
- 缓存控制
- 错误处理
- 中间件系统
- 多种日志格式支持

## 安装

```sh
ohpm install @cxy/webserver
```

或在`oh-package.json5` 添加依赖，然后同步

```json
{
  "dependencies": {
    "@cxy/webserver": "^2.0.1"
  }
}
```


## 快速开始

```typescript
import { HttpServer } from '@cxy/webserver';

const server = new HttpServer();

// 注册 GET / 接口
server.get('/', (req, res, next) => {
  res.status(200).json({
    message: '欢迎使用 WebServer'
  })
})

// 在8080端口 启动服务器
server.startServer(8080).then((info) => {
  console.log(`http://${info.address}:${info.port}`)
})

// 访问：http://设备的ip:8080/   
```

## 示例

完整的代码示例请查看 [demo](https://github.com/iHongRen/WebServer/blob/main/entry/src/main/ets/pages/Index.ets)

```typescript
import { HttpServer } from '@cxy/webserver';

// 初始化服务器
initServer()
{
  this.server = new HttpServer();

  // --- 1. 中间件注册 ---
  // 顺序很重要，通常日志和CORS最先，然后是请求体解析，再是静态文件和路由
  this.server.logger({
    stream: (log: string) => {
      console.log(log) //自定义写入日志文件
    }
  }) //日志记录
  this.server.cors(); //支持跨域

  this.server.auto(); //自动解析
  // this.server.json(); // 解析 application/json
  // this.server.urlencoded(); // 解析 application/x-www-form-urlencoded
  // this.server.multipart(); // 解析 multipart/form-data (用于文件上传)
  // this.server.plain(); // 解析文本

  this.server.serveStatic(this.staticFilesRoot); // 提供静态文件服务

  // --- 2. 模拟数据 ---
  const users: User[] = [
    { id: 1, name: 'cxy' },
    { id: 2, name: 'ihongren' },
    { id: 3, name: '仙银' }
  ];
  let nextUserId = 4;


  // --- 3. API 示例 ---
  // GET /api/users - 获取所有用户
  // curl http://192.168.2.38:8080/api/users
  this.server.get('/api/users', (req, res) => {
    res.json(users);
  });

  // GET /api/users/:id - 使用路由参数，获取单个用户
  // curl http://192.168.2.38:8080/api/users/1
  this.server.get('/api/users/:id', (req, res) => {
    const user = users.find(u => u.id === parseInt(req.params.id));
    if (user) {
      res.json(user);
    } else {
      res.status(404).json({ error: 'User not found' });
    }
  });

  // POST /api/users - 创建新用户
  // curl -X POST -H "Content-Type: application/json" -d '{"name":"NewUser"}' http://192.168.2.38:8080/api/users
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
  // curl -X POST -H "Content-Type: application/json" -d '{"name":"UpdatedUser"}' http://192.168.2.38:8080/api/users/1
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
  // curl -X POST -F "uploadFile=@/path/to/your/file.txt" http://192.168.2.38:8080/api/upload
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
  // curl http://192.168.2.38:8080/api/users/123/books/456
  this.server.get('/api/users/:userId/books/:bookId', (req, res) => {
    res.json({
      message: `You requested book ${req.params.bookId} for user ${req.params.userId}.`
    });
  });

  // 获取自定义请求头示例
  // curl -H "X-Custom-Request-Header: MyValue" http://192.168.2.38:8080/api/custom-request-header
  this.server.get('/api/custom-request-header', (req, res) => {
    const customHeader = req.get('x-custom-request-header');
    res.json({
      message: 'Received custom request header',
      headerValue: customHeader || 'Not found'
    });
  });

  // 自定义响应头示例
  // curl -i http://192.168.2.38:8080/api/custom-header
  this.server.get('/api/custom-header', (req, res) => {
    res.setHeader('X-Custom-Header', 'Hello from WebServer!');
    res.json({ message: 'Check the response headers!' });
  });

  // 错误触发示例
  // curl http://192.168.2.38:8080/crash
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
}


//启动服务器
const info = await this.server.startServer(8080);
if (info.address) {
  console.log(`http://${info.address}:${info.port}`)
} else {
  console.error("启动失败，未获取到地址");
}

// 停止服务器
await this.server.stopServer();
```

## 运行 [demo](https://github.com/iHongRen/WebServer)

|                           未开启服务                            |                             已开启服务                             |
|:----------------------------------------------------------:|:-------------------------------------------------------------:|
| <img src="https://7up.pics/images/2025/11/16/stop.jpeg" /> | <img src="https://7up.pics/images/2025/11/16/started.jpeg" /> |

**浏览器访问：http://192.168.xx.xx:8080**

<img src="https://7up.pics/images/2025/08/20/E4DAB553-8134-44F9-8C00-B97C1C2FEFC4.png" alt="E4DAB553 8134 44F9 8C00 B97C1C2FEFC4" border="0" style="display: inline-block;">

## 完整示例

查看 [examples/](https://github.com/iHongRen/WebServer/tree/main/entry/src/main/ets/examples) 目录获取更多示例：

- **HTTP服务器** - 完整的RESTful API和文件管理

- **HTTPS服务器** - SSL/TLS加密通信

- **Body Parser** - 各种请求体解析

- **CORS** - 跨域资源共享

- **Event** - 事件系统使用

- **Logger** - 日志记录

- **Router** - 路由系统

- **Static** - 静态文件服务

# WebServer API [文档](https://github.com/iHongRen/WebServer)

## 核心类

### HttpServer 类

Web服务器主类，提供HTTP服务器功能。

#### 路由方法

- `get(path: string, handler: RequestHandler)` - 注册GET路由
- `post(path: string, handler: RequestHandler)` - 注册POST路由
- `put(path: string, handler: RequestHandler)` - 注册PUT路由
- `delete(path: string, handler: RequestHandler)` - 注册DELETE路由
- `use(handler: RequestHandler | ErrorHandler)` - 注册中间件或错误处理器

#### 中间件方法

- `auto()` - 启用自动请求体解析（智能识别类型）
- `json()` - 启用JSON请求体解析
- `urlencoded()` - 启用URL编码请求体解析
- `multipart()` - 启用多部分表单解析（文件上传）
- `plain()` - 启用文本请求体解析
- `serveStatic(directoryPath: string, options?: CacheOptions)` - 启用静态文件服务
- `cors(options?: CorsOptions)` - 启用CORS跨域支持
- `logger(options?: LoggerOptions)` - 启用日志中间件

#### 服务器控制方法

- `startServer(port: number): Promise<socket.NetAddress>` - 启动服务器
- `stopServer(): Promise<void>` - 停止服务器

#### 事件监听方法

- `onError(listener: ErrorEventListener): void` - 监听服务器错误事件
- `on(eventType: ServerEventType, listener: ServerEventListener): void` - 监听服务器事件
- `removeErrorListener(listener: ErrorEventListener): void` - 移除错误监听器
- `removeListener(eventType: ServerEventType, listener: ServerEventListener): void` - 移除事件监听器
- `removeAllListeners(): void` - 清除所有事件监听器

#### 配置方法

- `setConfig(key: string, value: Object)` - 设置配置项
- `getConfig(key: string): Object | undefined` - 获取配置项

------

### TLSServer 类

HTTPS服务器类，继承自HttpServer，提供TLS加密的HTTP服务。

#### 构造函数

- `constructor(options: socket.TLSSecureOptions)` - 创建HTTPS服务器实例

#### 主要方法

- 继承HttpServer的所有方法
- `startServer(port: number): Promise<socket.NetAddress>` - 启动HTTPS服务器
- `stopServer(): Promise<void>` - 停止HTTPS服务器

------

### HttpRequest 类

HTTP请求解析类，包含请求的所有信息。

#### 主要属性

- `method: string` - HTTP请求方法（GET、POST等）
- `path: string` - 请求路径（不包含查询字符串）
- `url: string` - 完整URL路径（包含查询字符串）
- `version: string` - HTTP版本
- `ip: string` - 客户端IP地址
- `headers: Map<string, string>` - 请求头集合
- `body: ESObject` - 解析后的请求体数据
- `query: Map<string, string>` - 查询字符串参数
- `params: Record<string, string>` - 路由参数
- `files: Record<string, File>` - 上传的文件

#### 主要方法

- `parseBody(): void` - 解析请求体数据
- `getRawBody(): ArrayBuffer` - 获取原始请求体数据
- `get(headerName: string): string | undefined` - 获取请求头
- `is(type: string): boolean` - 检查Content-Type

#### 便捷属性

- `get userAgent(): string` - 获取User-Agent
- `get referer(): string` - 获取Referer
- `get contentLength(): number` - 获取Content-Length

------

### HttpResponse 类

HTTP响应构建类，用于构建和发送响应。

#### 主要方法

- `status(code: number): HttpResponse` - 设置HTTP状态码（支持链式调用）
- `setHeader(name: string, value: string): HttpResponse` - 设置响应头（支持链式调用）
- `getHeader(name: string): string | undefined` - 获取响应头
- `send(body?: string | ArrayBuffer): Promise<void>` - 发送响应数据
- `json(data: ESObject): Promise<void>` - 发送JSON响应
- `isHeadersSent(): boolean` - 检查响应头是否已发送
- `getStatusCode(): number` - 获取当前状态码
- `onFinish(callback: ResponseFinishCallback): void` - 添加响应完成回调

------

### Router 类

路由管理器，负责路由的注册、匹配和执行。

#### 主要方法

- `addRoute(method: string, path: string, handler: RequestHandler | ErrorHandler)` - 添加路由
- `handle(req: HttpRequest, res: HttpResponse)` - 处理HTTP请求
- `getRoutes(): Route[]` - 获取所有路由

------

## 中间件

### BodyParser 类

请求体解析中间件，支持多种格式。

- `static auto(): RequestHandler` - 自动解析中间件
- `static json(): RequestHandler` - JSON解析中间件
- `static urlencoded(): RequestHandler` - URL编码解析中间件
- `static plain(): RequestHandler` - 纯文本解析中间件
- `static multipart(): RequestHandler` - 多部分表单解析中间件（文件上传）

### Cors 类

CORS跨域资源共享中间件。

- `static create(options?: CorsOptions): RequestHandler` - 创建CORS中间件

**CorsOptions 配置项：**

```typescript
interface CorsOptions {
	origin?: string | string[]; // 允许的源
	methods?: string[]; // 允许的HTTP方法
	allowedHeaders?: string[]; // 允许的请求头
}
```

### StaticFiles 类

静态文件服务中间件。

- `static serve(directoryPath: string, options?: CacheOptions): RequestHandler` - 创建静态文件服务中间件

**CacheOptions 配置项：**

```typescript
interface CacheOptions {
	maxAge?: number; // 缓存最大时间（秒）
}
```

### Logger 类

日志中间件，提供HTTP请求日志记录功能。

- `static create(options?: LoggerOptions): RequestHandler` - 创建自定义日志中间件

**LoggerOptions 配置项：**

```typescript
interface LoggerOptions {
	format?: 'dev' | 'combined' | 'common' | 'short' | 'tiny'; // 日志格式
	stream?: (log: string) => void; // 自定义日志输出流
}
```

**日志格式说明：**

- `dev` - 开发环境格式，带颜色标识
- `combined` - Apache Combined Log Format（生产环境推荐）
- `common` - Apache Common Log Format
- `short` - 简短格式
- `tiny` - 最简格式

------

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

------

## 事件系统

### ServerEventType 枚举

服务器事件类型：

- `SERVER_STARTED` - 服务器启动
- `SERVER_STOPPED` - 服务器停止
- `CLIENT_CONNECTED` - 客户端连接
- `CLIENT_DISCONNECTED` - 客户端断开
- `REQUEST_RECEIVED` - 收到请求
- `RESPONSE_SENT` - 发送响应

### ServerErrorType 枚举

服务器错误类型：

- `STARTUP_FAILED` - 启动失败
- `LISTEN_ERROR` - 监听错误
- `CONNECTION_ERROR` - 连接错误
- `CLIENT_ERROR` - 客户端错误
- `SOCKET_ERROR` - Socket错误
- `UNKNOWN_ERROR` - 未知错误

------



## 类型定义

### 函数类型

```typescript
/**
 * 下一步函数类型
 * 用于中间件链式调用
 */
export type NextFunction = (error?: Error) => void;

/**
 * 请求处理函数类型
 * 标准的中间件处理函数
 */
export type RequestHandler = (req: HttpRequest, res: HttpResponse, next: NextFunction) => void;

/**
 * 错误处理函数类型
 * 用于处理中间件中的错误
 */
export type ErrorHandler = (error: Error, req: HttpRequest, res: HttpResponse, next: NextFunction) => void;

/**
 * 响应完成回调函数类型
 */
export type ResponseFinishCallback = (statusCode: number, responseSize: number) => void;

/**
 * 事件监听器类型定义
 */
type ErrorEventListener = (error: ServerError) => void;
type ServerEventListener = (event: ServerEvent) => void;
```

### 接口定义

```typescript
// 上传文件接口
interface File {
  fieldName: string; // 表单字段名
  fileName: string; // 文件名
  contentType: string; // 文件类型
  data: ArrayBuffer; // 文件数据
}

// 路由接口
interface Route {
  method: string; // HTTP方法
  path: string; // 路由路径
  handler: RequestHandler | ErrorHandler; // 处理函数
  pathRegex: RegExp | null; // 路径正则表达式
  paramNames: string[]; // 参数名列表
}

// 服务器事件接口
interface ServerEvent {
  type: ServerEventType; // 事件类型
  data?: any; // 事件数据
}

// 服务器错误接口
interface ServerError {
  type: ServerErrorType; // 错误类型
  error: any; // 错误对象
}

```



如果是使用过程中有什么问题，欢迎提 [issues](https://github.com/iHongRen/WebServer/issues)



# 作者

[@仙银](https://github.com/iHongRen)

鸿蒙开源作品，欢迎持续关注 [🌟Star](https://github.com/iHongRen/WebServer) ，[💖赞助](https://ihongren.github.io/donate.html)

1、[hpack](https://github.com/iHongRen/hpack) - 鸿蒙 HarmonyOS 一键打包上传分发测试工具。

2、[Open-in-DevEco-Studio](https://github.com/iHongRen/Open-in-DevEco-Studio)  - macOS 直接在 Finder 工具栏上，使用
DevEco-Studio 打开鸿蒙工程。

3、[cxy-theme](https://github.com/iHongRen/cxy-theme) - DevEco-Studio 绿色护眼背景主题

4、[harmony-udid-tool](https://github.com/iHongRen/harmony-udid-tool) - 简单易用的 HarmonyOS 设备 UDID 获取工具，适用于非开发人员。

5、[SandboxFinder](https://github.com/iHongRen/SandboxFinder) - 鸿蒙沙箱文件浏览器，支持模拟器和真机

6、[WebServer](https://github.com/iHongRen/WebServer) - 鸿蒙轻量级Web服务器框架，类 Express.js API 风格。

7、[SelectableMenu](https://github.com/iHongRen/SelectableMenu) - 适用于聊天对话框中的文本选择菜单

8、[RefreshList](https://github.com/iHongRen/RefreshList) - 功能完善的上拉下拉加载组件，支持各种自定义。