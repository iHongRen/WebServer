// /**
//  * @fileName : StaticExample.ets
//  * @author : @cxy
//  * @date : 2025/10/29
//  * @description : Static示例 - 展示静态文件服务功能
//  */
//
// import { fileIo } from '@kit.CoreFileKit';
// import { common } from '@kit.AbilityKit';
// import {
//   HttpServer,
//   ErrorHandler,
//   ServerInfo,
//   ServerEventType,
//   HttpRequest,
//   HttpResponse,
// } from '@cxy/webserver';
// import { util } from '@kit.ArkTS';
//
// /**
//  * 静态文件配置接口
//  */
// interface StaticConfig {
//   port: number;
//   staticRoot: string;
//   enableLogging: boolean;
//   enableCors: boolean;
//   enableCache: boolean;
//   maxAge: number;
// }
//
// /**
//  * 文件访问记录接口
//  */
// interface FileAccessRecord {
//   id: number;
//   filePath: string;
//   fileSize: number;
//   mimeType: string;
//   clientIP: string;
//   userAgent: string;
//   timestamp: Date;
//   responseTime: number;
//   statusCode: number;
// }
//
// /**
//  * Static示例类
//  * 展示静态文件服务的各种功能
//  */
// export class StaticExample {
//   private server: HttpServer | null = null;
//   private serverInfo: ServerInfo | null = null;
//   private isRunning: boolean = false;
//   private config: StaticConfig;
//   private context: common.UIAbilityContext;
//   // 文件访问记录
//   private accessRecords: FileAccessRecord[] = [];
//   private nextRecordId: number = 1;
//   // 文件缓存统计
//   private cacheStats = {
//     hits: 0,
//     misses: 0,
//     totalSize: 0
//   };
//
//   constructor(context: common.UIAbilityContext, config?: Partial<StaticConfig>) {
//     this.context = context;
//     this.config = {
//       port: config?.port || 8087,
//       staticRoot: config?.staticRoot || context.filesDir + '/static',
//       enableLogging: config?.enableLogging || true,
//       enableCors: config?.enableCors || true,
//       enableCache: config?.enableCache || true,
//       maxAge: config?.maxAge || 3600, // 1小时缓存
//     };
//   }
//
//   /**
//    * 设置静态文件
//    */
//   public async setupStaticFiles(): Promise<void> {
//     const access = await fileIo.access(this.config.staticRoot);
//     if (!access) {
//       await fileIo.mkdir(this.config.staticRoot);
//     }
//
//     // 创建示例文件结构
//     await this.createExampleFiles();
//   }
//
//   /**
//    * 初始化服务器
//    */
//   public initializeServer(): void {
//     this.server = new HttpServer();
//
//     this.setupEventHandling();
//     this.setupMiddleware();
//     this.setupRoutes();
//     this.setupGlobalErrorHandler();
//   }
//
//   /**
//    * 启动服务器
//    */
//   public async start(): Promise<ServerInfo | null> {
//     try {
//       if (!this.server) {
//         this.initializeServer();
//       }
//
//       if (!this.server) {
//         throw new Error('Static服务器初始化失败');
//       }
//
//       const info = await this.server.startServer(this.config.port);
//
//       if (info.address) {
//         this.serverInfo = info;
//         this.isRunning = true;
//
//         console.log('✅ Static服务器启动成功!');
//         console.log(`🌐 访问地址: http://${info.address}:${info.port}`);
//         this.printApiEndpoints(info);
//
//         return info;
//       } else {
//         throw new Error('未能获取服务器地址');
//       }
//     } catch (error) {
//       console.error('❌ 启动Static服务器失败:', error);
//       this.isRunning = false;
//       return null;
//     }
//   }
//
//   /**
//    * 停止服务器
//    */
//   public async stop(): Promise<void> {
//     if (this.server && this.isRunning) {
//       await this.server.stopServer();
//       this.isRunning = false;
//       this.serverInfo = null;
//       console.log('🛑 Static服务器已停止');
//     }
//   }
//
//   // Getter方法
//   public getServerInfo(): ServerInfo | null {
//     return this.serverInfo;
//   }
//
//   public getIsRunning(): boolean {
//     return this.isRunning;
//   }
//
//   public getConfig(): StaticConfig {
//     return this.config;
//   }
//
//   public getAccessCount(): number {
//     return this.accessRecords.length;
//   }
//
//   /**
//    * 创建示例文件
//    */
//   private async createExampleFiles(): Promise<void> {
//     // 创建子目录
//     const dirs = ['css', 'js', 'images', 'docs'];
//     for (const dir of dirs) {
//       const dirPath = `${this.config.staticRoot}/${dir}`;
//       const exists = await fileIo.access(dirPath);
//       if (!exists) {
//         await fileIo.mkdir(dirPath);
//       }
//     }
//
//     // 创建示例HTML文件
//     await this.createFile('index.html', `<!DOCTYPE html>
// <html>
// <head>
//     <title>Static File Server Demo</title>
//     <link rel="stylesheet" href="/css/style.css">
// </head>
// <body>
//     <h1>静态文件服务器演示</h1>
//     <p>这是一个静态HTML文件示例</p>
//     <img src="/images/logo.png" alt="Logo" style="max-width: 200px;">
//     <script src="/js/app.js"></script>
// </body>
// </html>`);
//
//     // 创建CSS文件
//     await this.createFile('css/style.css', `body {
//     font-family: Arial, sans-serif;
//     margin: 40px;
//     background-color: #f5f5f5;
// }
//
// h1 {
//     color: #333;
//     text-align: center;
// }
//
// p {
//     color: #666;
//     line-height: 1.6;
// }`);
//
//     // 创建JavaScript文件
//     await this.createFile('js/app.js', `console.log('Static file server is working!');
//
// document.addEventListener('DOMContentLoaded', function() {
//     console.log('Page loaded successfully');
//
//     // 添加一些交互
//     const h1 = document.querySelector('h1');
//     if (h1) {
//         h1.addEventListener('click', function() {
//             alert('Hello from static JavaScript!');
//         });
//     }
// });`);
//
//     // 创建文档文件
//     await this.createFile('docs/readme.txt', `Static File Server Documentation
//
// This is a demonstration of static file serving capabilities.
//
// Features:
// - File serving with proper MIME types
// - Caching support
// - Access logging
// - File browser
// - Upload functionality
//
// Created: ${new Date().toISOString()}`);
//
//     // 创建JSON数据文件
//     await this.createFile('data.json', JSON.stringify({
//       name: 'Static File Server',
//       version: '1.0.0',
//       features: ['file serving', 'caching', 'logging'],
//       created: new Date().toISOString()
//     }, null, 2));
//   }
//
//   /**
//    * 创建文件
//    */
//   private async createFile(relativePath: string, content: string): Promise<void> {
//     try {
//       const filePath = `${this.config.staticRoot}/${relativePath}`;
//       const file = await fileIo.open(filePath,
//         fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
//       await fileIo.write(file.fd, new util.TextEncoder().encode(content).buffer);
//       await fileIo.close(file.fd);
//     } catch (error) {
//       console.warn(`创建文件失败 ${relativePath}:`, error);
//     }
//   }
//
//   /**
//    * 设置事件处理
//    */
//   private setupEventHandling(): void {
//     if (!this.server) {
//       return;
//     }
//
//     this.server.onError((error) => {
//       console.error(`🚨 Static服务器错误 [${error.type}]: ${JSON.stringify(error)}`);
//     });
//
//     this.server.on(ServerEventType.SERVER_STARTED, (event) => {
//       console.log('✅ Static服务器启动成功:', event.data);
//     });
//   }
//
//   /**
//    * 配置中间件
//    */
//   private setupMiddleware(): void {
//     if (!this.server) {
//       return;
//     }
//
//     if (this.config.enableLogging) {
//       this.server.logger({
//         format: 'dev',
//         stream: (log: string) => console.log(`📁 ${log}`)
//       });
//     }
//
//     if (this.config.enableCors) {
//       this.server.cors({ origin: '*' });
//     }
//
//     // 文件访问记录中间件
//     this.server.use((req, res, next) => {
//       const startTime = Date.now();
//
//       res.onFinish((statusCode) => {
//         // 只记录静态文件访问
//         if (req.path.startsWith('/api/') || req.path === '/') {
//           return;
//         }
//
//         const responseTime = Date.now() - startTime;
//
//         const record: FileAccessRecord = {
//           id: this.nextRecordId++,
//           filePath: req.path,
//           fileSize: 0, // 实际实现中可以获取文件大小
//           mimeType: res.get('content-type') || 'unknown',
//           clientIP: req.ip,
//           userAgent: req.userAgent,
//           timestamp: new Date(),
//           responseTime,
//           statusCode
//         };
//
//         this.accessRecords.push(record);
//
//         // 限制记录数量
//         if (this.accessRecords.length > 1000) {
//           this.accessRecords = this.accessRecords.slice(-1000);
//         }
//
//         // 更新缓存统计
//         if (statusCode === 304) {
//           this.cacheStats.hits++;
//         } else if (statusCode === 200) {
//           this.cacheStats.misses++;
//         }
//       });
//
//       next();
//     });
//
//     this.server.auto();
//
//     // 配置静态文件服务
//     this.server.serveStatic(this.config.staticRoot, {
//       maxAge: this.config.enableCache ? this.config.maxAge : 0,
//     });
//   }
//
//   /**
//    * 配置路由
//    */
//   private setupRoutes(): void {
//     this.setupFileManagementRoutes();
//     this.setupStatisticsRoutes();
//     this.setupUtilityRoutes();
//   }
//
//   /**
//    * 文件管理路由
//    */
//   private setupFileManagementRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 文件浏览器API
//     this.server.get('/api/files', async (req: HttpRequest, res: HttpResponse) => {
//       try {
//         const path = req.query.get('path') || '';
//         const fullPath = `${this.config.staticRoot}/${path}`.replace(/\/+/g, '/');
//
//         const files = await fileIo.listFile(fullPath);
//         const fileList = [];
//
//         for (const fileName of files) {
//           const filePath = `${fullPath}/${fileName}`;
//           try {
//             const stat = await fileIo.stat(filePath);
//             fileList.push({
//               name: fileName,
//               path: `${path}/${fileName}`.replace(/^\//, ''),
//               isDirectory: stat.isDirectory(),
//               size: stat.size,
//               mtime: new Date(stat.mtime).toISOString()
//             });
//           } catch (e) {
//             // 忽略无法访问的文件
//           }
//         }
//
//         res.json({
//           currentPath: path,
//           files: fileList.sort((a, b) => {
//             if (a.isDirectory && !b.isDirectory) {
//               return -1;
//             }
//             if (!a.isDirectory && b.isDirectory) {
//               return 1;
//             }
//             return a.name.localeCompare(b.name);
//           })
//         });
//       } catch (error) {
//         res.status(500).json({ error: 'Failed to list files' });
//       }
//     });
//
//     // 文件上传API
//     this.server.post('/api/upload', async (req: HttpRequest, res: HttpResponse) => {
//       try {
//         const uploadedFile = req.files?.['file'];
//
//         if (!uploadedFile) {
//           return res.status(400).json({ error: 'No file uploaded' });
//         }
//
//         const fileName = uploadedFile.fileName;
//         const filePath = `${this.config.staticRoot}/${fileName}`;
//
//         const file = await fileIo.open(filePath,
//           fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
//         await fileIo.write(file.fd, uploadedFile.data);
//         await fileIo.close(file.fd);
//
//         res.json({
//           message: 'File uploaded successfully',
//           fileName,
//           size: uploadedFile.data.byteLength,
//           url: `/${fileName}`
//         });
//       } catch (error) {
//         res.status(500).json({ error: 'Upload failed' });
//       }
//     });
//
//     // 文件删除API
//     this.server.delete('/api/files/*', async (req: HttpRequest, res: HttpResponse) => {
//       try {
//         const filePath = req.path.replace('/api/files/', '');
//         const fullPath = `${this.config.staticRoot}/${filePath}`;
//
//         await fileIo.unlink(fullPath);
//
//         res.json({
//           message: 'File deleted successfully',
//           filePath
//         });
//       } catch (error) {
//         res.status(500).json({ error: 'Delete failed' });
//       }
//     });
//   }
//
//   /**
//    * 统计路由
//    */
//   private setupStatisticsRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 访问统计
//     this.server.get('/api/stats', (req: HttpRequest, res: HttpResponse) => {
//       const stats = this.analyzeAccessStats();
//
//       res.json({
//         totalAccess: this.accessRecords.length,
//         cacheStats: this.cacheStats,
//         popularFiles: stats.popularFiles,
//         fileTypes: stats.fileTypes,
//         hourlyAccess: stats.hourlyAccess,
//         recentAccess: this.accessRecords.slice(-10).reverse()
//       });
//     });
//
//     // 访问记录
//     this.server.get('/api/access-log', (req: HttpRequest, res: HttpResponse) => {
//       const limit = parseInt(req.query.get('limit') || '50');
//       const offset = parseInt(req.query.get('offset') || '0');
//
//       const records = this.accessRecords
//         .slice(offset, offset + limit)
//         .reverse();
//
//       res.json({
//         records,
//         total: this.accessRecords.length,
//         limit,
//         offset
//       });
//     });
//
//     // 清除访问记录
//     this.server.delete('/api/access-log', (req: HttpRequest, res: HttpResponse) => {
//       const count = this.accessRecords.length;
//       this.accessRecords = [];
//       this.nextRecordId = 1;
//       this.cacheStats = { hits: 0, misses: 0, totalSize: 0 };
//
//       res.json({
//         message: 'Access log cleared',
//         clearedCount: count
//       });
//     });
//   }
//
//   /**
//    * 工具路由
//    */
//   private setupUtilityRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 服务器配置
//     this.server.get('/api/config', (req: HttpRequest, res: HttpResponse) => {
//       res.json({
//         config: this.config,
//         cacheEnabled: this.config.enableCache,
//         staticRoot: this.config.staticRoot
//       });
//     });
//
//     // 更新缓存配置
//     this.server.post('/api/config/cache', (req: HttpRequest, res: HttpResponse) => {
//       const { enableCache, maxAge } = req.body as any;
//
//       if (enableCache !== undefined) {
//         this.config.enableCache = enableCache;
//       }
//
//       if (maxAge !== undefined) {
//         this.config.maxAge = maxAge;
//       }
//
//       res.json({
//         message: 'Cache configuration updated',
//         config: {
//           enableCache: this.config.enableCache,
//           maxAge: this.config.maxAge
//         }
//       });
//     });
//
//     // 文件信息
//     this.server.get('/api/file-info/*', async (req: HttpRequest, res: HttpResponse) => {
//       try {
//         const filePath = req.path.replace('/api/file-info/', '');
//         const fullPath = `${this.config.staticRoot}/${filePath}`;
//
//         const stat = await fileIo.stat(fullPath);
//
//         res.json({
//           name: filePath.split('/').pop(),
//           path: filePath,
//           size: stat.size,
//           isDirectory: stat.isDirectory(),
//           mtime: new Date(stat.mtime).toISOString(),
//           atime: new Date(stat.atime).toISOString(),
//           ctime: new Date(stat.ctime).toISOString()
//         });
//       } catch (error) {
//         res.status(404).json({ error: 'File not found' });
//       }
//     });
//   }
//
//   /**
//    * 分析访问统计
//    */
//   private analyzeAccessStats() {
//     const fileAccess: Record<string, number> = {};
//     const fileTypes: Record<string, number> = {};
//     const hourlyAccess: Record<string, number> = {};
//
//     this.accessRecords.forEach(record => {
//       // 文件访问统计
//       fileAccess[record.filePath] = (fileAccess[record.filePath] || 0) + 1;
//
//       // 文件类型统计
//       const ext = record.filePath.split('.').pop() || 'unknown';
//       fileTypes[ext] = (fileTypes[ext] || 0) + 1;
//
//       // 小时访问统计
//       const hour = record.timestamp.getHours();
//       const hourKey = `${hour}:00`;
//       hourlyAccess[hourKey] = (hourlyAccess[hourKey] || 0) + 1;
//     });
//
//     const popularFiles = Object.entries(fileAccess)
//       .sort(([, a], [, b]) => b - a)
//       .slice(0, 10)
//       .map(([file, count]) => ({ file, count }));
//
//     return {
//       popularFiles,
//       fileTypes,
//       hourlyAccess
//     };
//   }
//
//   /**
//    * 设置全局错误处理
//    */
//   private setupGlobalErrorHandler(): void {
//     if (!this.server) {
//       return;
//     }
//
//     const errorHandler: ErrorHandler = (error, req, res, next) => {
//       console.error(`🚨 [Static Error Handler] ${req.method} ${req.path}: ${error.message}`);
//
//       if (res.isHeadersSent()) {
//         return next(error);
//       }
//
//       res.status(500).json({
//         error: 'Static Server Error',
//         message: error.message,
//         timestamp: new Date().toISOString()
//       });
//     };
//
//     this.server.use(errorHandler);
//   }
//
//   /**
//    * 打印API端点信息
//    */
//   private printApiEndpoints(info: ServerInfo): void {
//     const baseUrl = `http://${info.address}:${info.port}`;
//
//     console.log('\n📁 Static File Server API端点:');
//     console.log('='.repeat(50));
//
//     console.log('📄 静态文件:');
//     console.log(`   GET  ${baseUrl}/                      - 首页`);
//     console.log(`   GET  ${baseUrl}/css/style.css         - CSS文件`);
//     console.log(`   GET  ${baseUrl}/js/app.js             - JavaScript文件`);
//     console.log(`   GET  ${baseUrl}/data.json             - JSON数据`);
//
//     console.log('\n📂 文件管理:');
//     console.log(`   GET    ${baseUrl}/api/files           - 文件浏览器`);
//     console.log(`   POST   ${baseUrl}/api/upload          - 文件上传`);
//     console.log(`   DELETE ${baseUrl}/api/files/*         - 文件删除`);
//     console.log(`   GET    ${baseUrl}/api/file-info/*     - 文件信息`);
//
//     console.log('\n📊 统计分析:');
//     console.log(`   GET    ${baseUrl}/api/stats           - 访问统计`);
//     console.log(`   GET    ${baseUrl}/api/access-log      - 访问日志`);
//     console.log(`   DELETE ${baseUrl}/api/access-log      - 清除日志`);
//
//     console.log('\n⚙️  配置管理:');
//     console.log(`   GET    ${baseUrl}/api/config          - 获取配置`);
//     console.log(`   POST   ${baseUrl}/api/config/cache    - 更新缓存配置`);
//
//     console.log('='.repeat(50));
//   }
// }
