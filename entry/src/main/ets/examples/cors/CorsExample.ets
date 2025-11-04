// /**
//  * @fileName : CorsExample.ets
//  * @author : @cxy
//  * @date : 2025/10/29
//  * @description : CORS示例 - 展示跨域资源共享功能
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
//
// /**
//  * CORS配置接口
//  */
// interface CorsConfig {
//   port: number;
//   staticRoot: string;
//   enableLogging: boolean;
//   corsOrigins: string[];
//   corsMethods: string[];
//   corsHeaders: string[];
//   corsCredentials: boolean;
// }
//
// /**
//  * CORS示例类
//  * 展示跨域资源共享的各种配置和功能
//  */
// export class CorsExample {
//   private server: HttpServer | null = null;
//   private serverInfo: ServerInfo | null = null;
//   private isRunning: boolean = false;
//   private config: CorsConfig;
//   private context: common.UIAbilityContext;
//   // CORS请求统计
//   private corsRequests: Array<{
//     id: number;
//     origin: string;
//     method: string;
//     headers: string[];
//     allowed: boolean;
//     timestamp: Date;
//   }> = [];
//   private nextId: number = 1;
//
//   constructor(context: common.UIAbilityContext, config?: Partial<CorsConfig>) {
//     this.context = context;
//     this.config = {
//       port: config?.port || 8083,
//       staticRoot: config?.staticRoot || context.filesDir + '/static',
//       enableLogging: config?.enableLogging || true,
//       corsOrigins: config?.corsOrigins || ['*'],
//       corsMethods: config?.corsMethods || ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
//       corsHeaders: config?.corsHeaders || ['Content-Type', 'Authorization', 'X-Requested-With'],
//       corsCredentials: config?.corsCredentials || true,
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
//     await this.copyStaticFile('cors-demo.html');
//     await this.copyStaticFile('cors-test.html');
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
//         throw new Error('CORS服务器初始化失败');
//       }
//
//       const info = await this.server.startServer(this.config.port);
//
//       if (info.address) {
//         this.serverInfo = info;
//         this.isRunning = true;
//
//         console.log('✅ CORS服务器启动成功!');
//         console.log(`🌐 访问地址: http://${info.address}:${info.port}`);
//         this.printApiEndpoints(info);
//
//         return info;
//       } else {
//         throw new Error('未能获取服务器地址');
//       }
//     } catch (error) {
//       console.error('❌ 启动CORS服务器失败:', error);
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
//       console.log('🛑 CORS服务器已停止');
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
//   public getConfig(): CorsConfig {
//     return this.config;
//   }
//
//   public getCorsRequestCount(): number {
//     return this.corsRequests.length;
//   }
//
//   /**
//    * 复制静态文件
//    */
//   private async copyStaticFile(fileName: string): Promise<void> {
//     try {
//       const buffer = await this.context.resourceManager.getRawFileContent(fileName);
//       const filePath = `${this.config.staticRoot}/${fileName}`;
//
//       const file = await fileIo.open(filePath,
//         fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
//       await fileIo.write(file.fd, buffer.buffer);
//       await fileIo.close(file.fd);
//     } catch (error) {
//       console.warn(`⚠️  无法复制文件 ${fileName}:`, error);
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
//       console.error(`🚨 CORS服务器错误 [${error.type}]: ${JSON.stringify(error.error)}`);
//     });
//
//     this.server.on(ServerEventType.SERVER_STARTED, (event) => {
//       console.log('✅ CORS服务器启动成功:', event.data);
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
//         stream: (log: string) => console.log(`🌐 ${log}`)
//       });
//     }
//
//     // 自定义CORS中间件，用于记录CORS请求
//     this.server.use((req, res, next) => {
//       const origin = req.get('origin') || req.get('referer') || 'unknown';
//       const method = req.method;
//       const requestedHeaders = req.get('access-control-request-headers')?.split(',') || [];
//
//       // 记录CORS请求
//       const corsRequest = {
//         id: this.nextId++,
//         origin,
//         method,
//         headers: requestedHeaders,
//         allowed: this.isOriginAllowed(origin),
//         timestamp: new Date()
//       };
//       this.corsRequests.push(corsRequest);
//
//       console.log(`🌐 CORS请求: ${method} from ${origin} - ${corsRequest.allowed ? '✅ 允许' : '❌ 拒绝'}`);
//
//       next();
//     });
//
//     // 配置CORS
//     this.server.cors({
//       origin: this.config.corsOrigins,
//       methods: this.config.corsMethods,
//       allowedHeaders: this.config.corsHeaders
//     });
//
//     this.server.auto();
//     this.server.serveStatic(this.config.staticRoot);
//   }
//
//   /**
//    * 检查来源是否被允许
//    */
//   private isOriginAllowed(origin: string): boolean {
//     if (this.config.corsOrigins.includes('*')) {
//       return true;
//     }
//     return this.config.corsOrigins.some(allowed =>
//     origin.includes(allowed) || allowed.includes(origin)
//     );
//   }
//
//   /**
//    * 配置路由
//    */
//   private setupRoutes(): void {
//     this.setupCorsTestRoutes();
//     this.setupCorsConfigRoutes();
//     this.setupCorsStatsRoutes();
//   }
//
//   /**
//    * CORS测试路由
//    */
//   private setupCorsTestRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 简单请求测试
//     this.server.get('/api/cors/simple', (req: HttpRequest, res: HttpResponse) => {
//       const origin = req.get('origin') || 'unknown';
//
//       res.json({
//         message: 'CORS简单请求测试成功',
//         origin,
//         method: req.method,
//         timestamp: new Date().toISOString(),
//         corsType: 'Simple Request'
//       });
//     });
//
//     // 预检请求测试
//     this.server.post('/api/cors/preflight', (req: HttpRequest, res: HttpResponse) => {
//       const origin = req.get('origin') || 'unknown';
//
//       res.json({
//         message: 'CORS预检请求测试成功',
//         origin,
//         method: req.method,
//         body: req.body,
//         timestamp: new Date().toISOString(),
//         corsType: 'Preflight Request'
//       });
//     });
//
//     // 带凭证的请求测试
//     this.server.post('/api/cors/credentials', (req: HttpRequest, res: HttpResponse) => {
//       const origin = req.get('origin') || 'unknown';
//       const cookies = req.get('cookie') || 'none';
//
//       // 设置一个测试cookie
//       res.setHeader('Set-Cookie', 'cors-test=success; Path=/; HttpOnly');
//
//       res.json({
//         message: 'CORS凭证请求测试成功',
//         origin,
//         cookies,
//         credentialsSupported: this.config.corsCredentials,
//         timestamp: new Date().toISOString(),
//         corsType: 'Credentialed Request'
//       });
//     });
//
//     // 自定义头部测试
//     this.server.put('/api/cors/custom-headers', (req: HttpRequest, res: HttpResponse) => {
//       const origin = req.get('origin') || 'unknown';
//       const customHeader = req.get('x-custom-header') || 'none';
//       const authorization = req.get('authorization') || 'none';
//
//       res.json({
//         message: 'CORS自定义头部测试成功',
//         origin,
//         customHeader,
//         authorization,
//         allowedHeaders: this.config.corsHeaders,
//         timestamp: new Date().toISOString(),
//         corsType: 'Custom Headers Request'
//       });
//     });
//   }
//
//   /**
//    * CORS配置路由
//    */
//   private setupCorsConfigRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 获取CORS配置
//     this.server.get('/api/cors/config', (req: HttpRequest, res: HttpResponse) => {
//       res.json({
//         corsConfig: {
//           origins: this.config.corsOrigins,
//           methods: this.config.corsMethods,
//           headers: this.config.corsHeaders,
//           credentials: this.config.corsCredentials
//         },
//         description: {
//           origins: 'Allowed origins for CORS requests',
//           methods: 'Allowed HTTP methods',
//           headers: 'Allowed request headers',
//           credentials: 'Whether credentials are supported'
//         }
//       });
//     });
//
//     // 更新CORS配置
//     this.server.post('/api/cors/config', (req: HttpRequest, res: HttpResponse) => {
//       const { origins, methods, headers, credentials } = req.body as any;
//
//       if (origins) {
//         this.config.corsOrigins = origins;
//       }
//       if (methods) {
//         this.config.corsMethods = methods;
//       }
//       if (headers) {
//         this.config.corsHeaders = headers;
//       }
//       if (credentials !== undefined) {
//         this.config.corsCredentials = credentials;
//       }
//
//       res.json({
//         message: 'CORS配置已更新',
//         newConfig: {
//           origins: this.config.corsOrigins,
//           methods: this.config.corsMethods,
//           headers: this.config.corsHeaders,
//           credentials: this.config.corsCredentials
//         },
//         note: '需要重启服务器以应用新配置'
//       });
//     });
//
//     // 测试特定来源
//     this.server.post('/api/cors/test-origin', (req: HttpRequest, res: HttpResponse) => {
//       const { testOrigin } = req.body as { testOrigin: string };
//       const allowed = this.isOriginAllowed(testOrigin);
//
//       res.json({
//         origin: testOrigin,
//         allowed,
//         reason: allowed ? 'Origin is in allowed list' : 'Origin not in allowed list',
//         allowedOrigins: this.config.corsOrigins
//       });
//     });
//   }
//
//   /**
//    * CORS统计路由
//    */
//   private setupCorsStatsRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 获取CORS请求统计
//     this.server.get('/api/cors/stats', (req: HttpRequest, res: HttpResponse) => {
//       const stats = this.analyzeCorsRequests();
//
//       res.json({
//         totalRequests: this.corsRequests.length,
//         allowedRequests: stats.allowed,
//         blockedRequests: stats.blocked,
//         topOrigins: stats.topOrigins,
//         methodDistribution: stats.methodDistribution,
//         recentRequests: this.corsRequests.slice(-10).reverse()
//       });
//     });
//
//     // 获取CORS请求历史
//     this.server.get('/api/cors/history', (req: HttpRequest, res: HttpResponse) => {
//       const limit = parseInt(req.query.get('limit') || '50');
//       const offset = parseInt(req.query.get('offset') || '0');
//
//       const history = this.corsRequests
//         .slice(offset, offset + limit)
//         .reverse();
//
//       res.json({
//         history,
//         total: this.corsRequests.length,
//         limit,
//         offset
//       });
//     });
//
//     // 清除CORS统计
//     this.server.delete('/api/cors/stats', (req: HttpRequest, res: HttpResponse) => {
//       const count = this.corsRequests.length;
//       this.corsRequests = [];
//       this.nextId = 1;
//
//       res.json({
//         message: 'CORS统计已清除',
//         clearedCount: count
//       });
//     });
//   }
//
//   /**
//    * 分析CORS请求统计
//    */
//   private analyzeCorsRequests() {
//     const allowed = this.corsRequests.filter(req => req.allowed).length;
//     const blocked = this.corsRequests.length - allowed;
//
//     // 统计来源
//     const originCounts: Record<string, number> = {};
//     this.corsRequests.forEach(req => {
//       originCounts[req.origin] = (originCounts[req.origin] || 0) + 1;
//     });
//
//     const topOrigins = Object.entries(originCounts)
//       .sort(([, a], [, b]) => b - a)
//       .slice(0, 5)
//       .map(([origin, count]) => ({ origin, count }));
//
//     // 统计方法
//     const methodCounts: Record<string, number> = {};
//     this.corsRequests.forEach(req => {
//       methodCounts[req.method] = (methodCounts[req.method] || 0) + 1;
//     });
//
//     return {
//       allowed,
//       blocked,
//       topOrigins,
//       methodDistribution: methodCounts
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
//       console.error(`🚨 [CORS Error Handler] ${req.method} ${req.path}: ${error.message}`);
//
//       if (res.isHeadersSent()) {
//         return next(error);
//       }
//
//       res.status(500).json({
//         error: 'CORS Server Error',
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
//     console.log('\n🌐 CORS API端点:');
//     console.log('='.repeat(50));
//
//     console.log('📄 演示页面:');
//     console.log(`   GET  ${baseUrl}/cors-demo.html          - CORS演示页面`);
//     console.log(`   GET  ${baseUrl}/cors-test.html          - CORS测试页面`);
//
//     console.log('\n🧪 CORS测试:');
//     console.log(`   GET    ${baseUrl}/api/cors/simple       - 简单请求测试`);
//     console.log(`   POST   ${baseUrl}/api/cors/preflight    - 预检请求测试`);
//     console.log(`   POST   ${baseUrl}/api/cors/credentials  - 凭证请求测试`);
//     console.log(`   PUT    ${baseUrl}/api/cors/custom-headers - 自定义头部测试`);
//
//     console.log('\n⚙️  CORS配置:');
//     console.log(`   GET    ${baseUrl}/api/cors/config       - 获取CORS配置`);
//     console.log(`   POST   ${baseUrl}/api/cors/config       - 更新CORS配置`);
//     console.log(`   POST   ${baseUrl}/api/cors/test-origin  - 测试特定来源`);
//
//     console.log('\n📊 CORS统计:');
//     console.log(`   GET    ${baseUrl}/api/cors/stats        - 获取CORS统计`);
//     console.log(`   GET    ${baseUrl}/api/cors/history      - 获取请求历史`);
//     console.log(`   DELETE ${baseUrl}/api/cors/stats        - 清除统计数据`);
//
//     console.log('='.repeat(50));
//   }
// }