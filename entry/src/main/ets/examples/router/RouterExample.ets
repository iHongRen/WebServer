// /**
//  * @fileName : RouterExample.ets
//  * @author : @cxy
//  * @date : 2025/10/29
//  * @description : Router示例 - 展示路由系统功能
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
//  * 路由配置接口
//  */
// interface RouterConfig {
//   port: number;
//   staticRoot: string;
//   enableLogging: boolean;
//   enableCors: boolean;
// }
//
// /**
//  * 路由记录接口
//  */
// interface RouteRecord {
//   id: number;
//   method: string;
//   path: string;
//   pattern: string;
//   params: Record<string, string>;
//   query: Record<string, string>;
//   timestamp: Date;
//   responseTime: number;
//   statusCode: number;
// }
//
// /**
//  * Router示例类
//  * 展示路由系统的各种功能
//  */
// export class RouterExample {
//   private server: HttpServer | null = null;
//   private serverInfo: ServerInfo | null = null;
//   private isRunning: boolean = false;
//   private config: RouterConfig;
//   private context: common.UIAbilityContext;
//   // 路由记录
//   private routeRecords: RouteRecord[] = [];
//   private nextRouteId: number = 1;
//   // 动态路由存储
//   private dynamicRoutes: Map<string, any> = new Map();
//
//   constructor(context: common.UIAbilityContext, config?: Partial<RouterConfig>) {
//     this.context = context;
//     this.config = {
//       port: config?.port || 8086,
//       staticRoot: config?.staticRoot || context.filesDir + '/static',
//       enableLogging: config?.enableLogging || true,
//       enableCors: config?.enableCors || true,
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
//     await this.copyStaticFile('router-demo.html');
//     await this.copyStaticFile('route-tester.html');
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
//         throw new Error('Router服务器初始化失败');
//       }
//
//       const info = await this.server.startServer(this.config.port);
//
//       if (info.address) {
//         this.serverInfo = info;
//         this.isRunning = true;
//
//         console.log('✅ Router服务器启动成功!');
//         console.log(`🌐 访问地址: http://${info.address}:${info.port}`);
//         this.printApiEndpoints(info);
//
//         return info;
//       } else {
//         throw new Error('未能获取服务器地址');
//       }
//     } catch (error) {
//       console.error('❌ 启动Router服务器失败:', error);
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
//       console.log('🛑 Router服务器已停止');
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
//   public getConfig(): RouterConfig {
//     return this.config;
//   }
//
//   public getRouteCount(): number {
//     return this.routeRecords.length;
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
//       console.error(`🚨 Router服务器错误 [${error.type}]: ${JSON.stringify(error.error)}`);
//     });
//
//     this.server.on(ServerEventType.SERVER_STARTED, (event) => {
//       console.log('✅ Router服务器启动成功:', event.data);
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
//         stream: (log: string) => console.log(`🛣️  ${log}`)
//       });
//     }
//
//     if (this.config.enableCors) {
//       this.server.cors({ origin: '*' });
//     }
//
//     // 路由记录中间件
//     this.server.use((req, res, next) => {
//       const startTime = Date.now();
//
//       res.onFinish((statusCode) => {
//         const responseTime = Date.now() - startTime;
//
//         const routeRecord: RouteRecord = {
//           id: this.nextRouteId++,
//           method: req.method,
//           path: req.path,
//           pattern: req.url,
//           params: req.params,
//           query: Object.fromEntries(req.query),
//           timestamp: new Date(),
//           responseTime,
//           statusCode
//         };
//
//         this.routeRecords.push(routeRecord);
//
//         // 限制记录数量
//         if (this.routeRecords.length > 500) {
//           this.routeRecords = this.routeRecords.slice(-500);
//         }
//       });
//
//       next();
//     });
//
//     this.server.auto();
//     this.server.serveStatic(this.config.staticRoot);
//   }
//
//   /**
//    * 配置路由
//    */
//   private setupRoutes(): void {
//     this.setupBasicRoutes();
//     this.setupParameterRoutes();
//     this.setupWildcardRoutes();
//     this.setupDynamicRoutes();
//     this.setupRouteManagement();
//   }
//
//   /**
//    * 基础路由
//    */
//   private setupBasicRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 根路径
//     this.server.get('/', (req: HttpRequest, res: HttpResponse) => {
//       res.json({
//         message: 'Router示例首页',
//         availableRoutes: [
//           'GET /',
//           'GET /about',
//           'GET /contact',
//           'GET /api/users/:id',
//           'GET /api/products/:category/:id',
//           'GET /files/*',
//           'POST /api/routes'
//         ],
//         timestamp: new Date().toISOString()
//       });
//     });
//
//     // 关于页面
//     this.server.get('/about', (req: HttpRequest, res: HttpResponse) => {
//       res.json({
//         page: 'About',
//         message: '这是关于页面',
//         version: '1.0.0',
//         features: ['路由参数', '通配符路由', '动态路由', '路由统计']
//       });
//     });
//
//     // 联系页面
//     this.server.get('/contact', (req: HttpRequest, res: HttpResponse) => {
//       res.json({
//         page: 'Contact',
//         message: '联系我们',
//         email: 'contact@example.com',
//         phone: '+86 123-4567-8900'
//       });
//     });
//   }
//
//   /**
//    * 参数路由
//    */
//   private setupParameterRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 单个参数
//     this.server.get('/api/users/:id', (req: HttpRequest, res: HttpResponse) => {
//       const userId = req.params['id'];
//
//       res.json({
//         route: '/api/users/:id',
//         userId,
//         userInfo: {
//           id: userId,
//           name: `User ${userId}`,
//           email: `user${userId}@example.com`
//         },
//         params: req.params,
//         query: Object.fromEntries(req.query)
//       });
//     });
//
//     // 多个参数
//     this.server.get('/api/products/:category/:id', (req: HttpRequest, res: HttpResponse) => {
//       const { category, id } = req.params;
//
//       res.json({
//         route: '/api/products/:category/:id',
//         category,
//         productId: id,
//         product: {
//           id,
//           name: `Product ${id}`,
//           category,
//           price: Math.floor(Math.random() * 1000) + 100
//         },
//         params: req.params
//       });
//     });
//
//     // 可选参数模拟
//     this.server.get('/api/posts/:id', (req: HttpRequest, res: HttpResponse) => {
//       const postId = req.params['id'];
//       const format = req.query.get('format') || 'json';
//
//       const post = {
//         id: postId,
//         title: `Post ${postId}`,
//         content: `This is the content of post ${postId}`,
//         author: 'Admin',
//         createdAt: new Date().toISOString()
//       };
//
//       if (format === 'xml') {
//         res.setHeader('Content-Type', 'application/xml');
//         res.send(`<?xml version="1.0"?>
// <post>
//   <id>${post.id}</id>
//   <title>${post.title}</title>
//   <content>${post.content}</content>
//   <author>${post.author}</author>
//   <createdAt>${post.createdAt}</createdAt>
// </post>`);
//       } else {
//         res.json(post);
//       }
//     });
//   }
//
//   /**
//    * 通配符路由
//    */
//   private setupWildcardRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 文件路径通配符
//     this.server.get('/files/*', (req: HttpRequest, res: HttpResponse) => {
//       const filePath = req.path.replace('/files/', '');
//
//       res.json({
//         route: '/files/*',
//         requestedFile: filePath,
//         message: `访问文件: ${filePath}`,
//         fileInfo: {
//           path: filePath,
//           extension: filePath.split('.').pop() || 'unknown',
//           directory: filePath.includes('/') ? filePath.substring(0, filePath.lastIndexOf('/')) : '/',
//           filename: filePath.includes('/') ? filePath.substring(filePath.lastIndexOf('/') + 1) : filePath
//         }
//       });
//     });
//
//     // API版本通配符
//     this.server.get('/api/v*/status', (req: HttpRequest, res: HttpResponse) => {
//       const version = req.path.match(/\/api\/(v\d+)\/status/)?.[1] || 'unknown';
//
//       res.json({
//         route: '/api/v*/status',
//         apiVersion: version,
//         status: 'ok',
//         features: version === 'v1' ? ['basic'] : ['basic', 'advanced', 'premium'],
//         timestamp: new Date().toISOString()
//       });
//     });
//   }
//
//   /**
//    * 动态路由管理
//    */
//   private setupDynamicRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 动态路由处理器
//     this.server.use((req, res, next) => {
//       const routeKey = `${req.method}:${req.path}`;
//       const dynamicRoute = this.dynamicRoutes.get(routeKey);
//
//       if (dynamicRoute) {
//         res.json({
//           message: '动态路由响应',
//           route: req.path,
//           method: req.method,
//           config: dynamicRoute,
//           timestamp: new Date().toISOString()
//         });
//       } else {
//         next();
//       }
//     });
//   }
//
//   /**
//    * 路由管理API
//    */
//   private setupRouteManagement(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 获取路由统计
//     this.server.get('/api/routes/stats', (req: HttpRequest, res: HttpResponse) => {
//       const stats = this.analyzeRouteStats();
//
//       res.json({
//         totalRequests: this.routeRecords.length,
//         routeStats: stats.routeStats,
//         methodStats: stats.methodStats,
//         averageResponseTime: stats.averageResponseTime,
//         popularRoutes: stats.popularRoutes,
//         recentRequests: this.routeRecords.slice(-10).reverse()
//       });
//     });
//
//     // 获取路由记录
//     this.server.get('/api/routes/records', (req: HttpRequest, res: HttpResponse) => {
//       const limit = parseInt(req.query.get('limit') || '50');
//       const offset = parseInt(req.query.get('offset') || '0');
//       const method = req.query.get('method');
//
//       let filteredRecords = this.routeRecords;
//
//       if (method) {
//         filteredRecords = filteredRecords.filter(record => record.method === method);
//       }
//
//       const records = filteredRecords
//         .slice(offset, offset + limit)
//         .reverse();
//
//       res.json({
//         records,
//         total: filteredRecords.length,
//         limit,
//         offset,
//         filters: { method }
//       });
//     });
//
//     // 添加动态路由
//     this.server.post('/api/routes', (req: HttpRequest, res: HttpResponse) => {
//       const { method, path, response } = req.body as any;
//
//       if (!method || !path) {
//         return res.status(400).json({
//           error: 'Method and path are required'
//         });
//       }
//
//       const routeKey = `${method.toUpperCase()}:${path}`;
//       this.dynamicRoutes.set(routeKey, {
//         method: method.toUpperCase(),
//         path,
//         response: response || { message: 'Dynamic route response' },
//         createdAt: new Date().toISOString()
//       });
//
//       res.json({
//         message: 'Dynamic route added',
//         routeKey,
//         totalDynamicRoutes: this.dynamicRoutes.size
//       });
//     });
//
//     // 删除动态路由
//     this.server.delete('/api/routes/:method/:path', (req: HttpRequest, res: HttpResponse) => {
//       const { method, path } = req.params;
//       const routeKey = `${method.toUpperCase()}:/${path}`;
//
//       const deleted = this.dynamicRoutes.delete(routeKey);
//
//       res.json({
//         message: deleted ? 'Dynamic route deleted' : 'Route not found',
//         routeKey,
//         deleted,
//         remainingRoutes: this.dynamicRoutes.size
//       });
//     });
//
//     // 获取所有动态路由
//     this.server.get('/api/routes/dynamic', (req: HttpRequest, res: HttpResponse) => {
//       const routes = Array.from(this.dynamicRoutes.entries()).map(([key, config]) => ({
//         routeKey: key,
//         ...config
//       }));
//
//       res.json({
//         dynamicRoutes: routes,
//         count: routes.length
//       });
//     });
//
//     // 清除路由记录
//     this.server.delete('/api/routes/records', (req: HttpRequest, res: HttpResponse) => {
//       const count = this.routeRecords.length;
//       this.routeRecords = [];
//       this.nextRouteId = 1;
//
//       res.json({
//         message: 'Route records cleared',
//         clearedCount: count
//       });
//     });
//   }
//
//   /**
//    * 分析路由统计
//    */
//   private analyzeRouteStats() {
//     const routeStats: Record<string, number> = {};
//     const methodStats: Record<string, number> = {};
//     let totalResponseTime = 0;
//
//     this.routeRecords.forEach(record => {
//       const routeKey = `${record.method} ${record.path}`;
//       routeStats[routeKey] = (routeStats[routeKey] || 0) + 1;
//       methodStats[record.method] = (methodStats[record.method] || 0) + 1;
//       totalResponseTime += record.responseTime;
//     });
//
//     const popularRoutes = Object.entries(routeStats)
//       .sort(([, a], [, b]) => b - a)
//       .slice(0, 5)
//       .map(([route, count]) => ({ route, count }));
//
//     return {
//       routeStats,
//       methodStats,
//       averageResponseTime: this.routeRecords.length > 0 ? totalResponseTime / this.routeRecords.length : 0,
//       popularRoutes
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
//       console.error(`🚨 [Router Error Handler] ${req.method} ${req.path}: ${error.message}`);
//
//       if (res.isHeadersSent()) {
//         return next(error);
//       }
//
//       res.status(500).json({
//         error: 'Router Server Error',
//         message: error.message,
//         route: req.path,
//         method: req.method,
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
//     console.log('\n🛣️  Router API端点:');
//     console.log('='.repeat(50));
//
//     console.log('📄 演示页面:');
//     console.log(`   GET  ${baseUrl}/router-demo.html      - Router演示页面`);
//     console.log(`   GET  ${baseUrl}/route-tester.html     - 路由测试工具`);
//
//     console.log('\n🏠 基础路由:');
//     console.log(`   GET    ${baseUrl}/                    - 首页`);
//     console.log(`   GET    ${baseUrl}/about               - 关于页面`);
//     console.log(`   GET    ${baseUrl}/contact             - 联系页面`);
//
//     console.log('\n🔗 参数路由:');
//     console.log(`   GET    ${baseUrl}/api/users/:id       - 用户详情`);
//     console.log(`   GET    ${baseUrl}/api/products/:category/:id - 产品详情`);
//     console.log(`   GET    ${baseUrl}/api/posts/:id       - 文章详情`);
//
//     console.log('\n🌟 通配符路由:');
//     console.log(`   GET    ${baseUrl}/files/*             - 文件访问`);
//     console.log(`   GET    ${baseUrl}/api/v*/status       - API版本状态`);
//
//     console.log('\n⚙️  路由管理:');
//     console.log(`   GET    ${baseUrl}/api/routes/stats    - 路由统计`);
//     console.log(`   GET    ${baseUrl}/api/routes/records  - 路由记录`);
//     console.log(`   POST   ${baseUrl}/api/routes          - 添加动态路由`);
//     console.log(`   GET    ${baseUrl}/api/routes/dynamic  - 获取动态路由`);
//     console.log(`   DELETE ${baseUrl}/api/routes/records  - 清除路由记录`);
//
//     console.log('='.repeat(50));
//   }
// }