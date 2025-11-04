// /**
//  * @fileName : EventExample.ets
//  * @author : @cxy
//  * @date : 2025/10/29
//  * @description : Event示例 - 展示服务器事件系统功能
//  */
//
// import { fileIo } from '@kit.CoreFileKit';
// import { common } from '@kit.AbilityKit';
// import {
//   HttpServer,
//   ErrorHandler,
//   ServerInfo,
//   ServerEventType,
//   ServerErrorType,
//   HttpRequest,
//   HttpResponse,
// } from '@cxy/webserver';
//
// /**
//  * 事件配置接口
//  */
// interface EventConfig {
//   port: number;
//   staticRoot: string;
//   enableLogging: boolean;
//   enableCors: boolean;
//   eventHistoryLimit: number;
// }
//
// /**
//  * 事件记录接口
//  */
// interface EventRecord {
//   id: number;
//   type: 'server' | 'error' | 'client' | 'custom';
//   eventName: string;
//   message: string;
//   data?: any;
//   timestamp: Date;
//   level: 'info' | 'warn' | 'error';
// }
//
// /**
//  * Event示例类
//  * 展示服务器事件系统的各种功能
//  */
// export class EventExample {
//   private server: HttpServer | null = null;
//   private serverInfo: ServerInfo | null = null;
//   private isRunning: boolean = false;
//   private config: EventConfig;
//   private context: common.UIAbilityContext;
//   // 事件记录
//   private eventHistory: EventRecord[] = [];
//   private nextEventId: number = 1;
//   private eventListeners: Map<string, Function[]> = new Map();
//
//   constructor(context: common.UIAbilityContext, config?: Partial<EventConfig>) {
//     this.context = context;
//     this.config = {
//       port: config?.port || 8084,
//       staticRoot: config?.staticRoot || context.filesDir + '/static',
//       enableLogging: config?.enableLogging || true,
//       enableCors: config?.enableCors || true,
//       eventHistoryLimit: config?.eventHistoryLimit || 1000,
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
//     await this.copyStaticFile('event-demo.html');
//     await this.copyStaticFile('event-monitor.html');
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
//         throw new Error('Event服务器初始化失败');
//       }
//
//       const info = await this.server.startServer(this.config.port);
//
//       if (info.address) {
//         this.serverInfo = info;
//         this.isRunning = true;
//
//         console.log('✅ Event服务器启动成功!');
//         console.log(`🌐 访问地址: http://${info.address}:${info.port}`);
//         this.printApiEndpoints(info);
//
//         // 触发自定义启动事件
//         this.emitCustomEvent('server_ready', {
//           address: info.address,
//           port: info.port,
//           startTime: new Date()
//         });
//
//         return info;
//       } else {
//         throw new Error('未能获取服务器地址');
//       }
//     } catch (error) {
//       console.error('❌ 启动Event服务器失败:', error);
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
//
//       // 触发自定义停止事件
//       this.emitCustomEvent('server_shutdown', {
//         stopTime: new Date(),
//         totalEvents: this.eventHistory.length
//       });
//
//       console.log('🛑 Event服务器已停止');
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
//   public getConfig(): EventConfig {
//     return this.config;
//   }
//
//   public getEventCount(): number {
//     return this.eventHistory.length;
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
//     // 监听服务器错误事件
//     this.server.onError((error) => {
//       // this.recordEvent({
//       //   type: 'error',
//       //   eventName: error.type,
//       //   message: error.message,
//       //   data: {
//       //     originalError: error.originalError,
//       //     context: error.context
//       //   },
//       //   level: 'error'
//       // });
//
//       console.error(`🚨 服务器错误 [${error.type}]: ${JSON.stringify(error.error)}`);
//     });
//
//     // 监听服务器事件
//     Object.values(ServerEventType).forEach(eventType => {
//       this.server!.on(eventType, (event) => {
//         // this.recordEvent({
//         //   type: 'server',
//         //   eventName: eventType,
//         //   data: event.data,
//         //   level: 'info'
//         // });
//
//         console.log(`📡 服务器事件 [${eventType}]: ${JSON.stringify(event.data)}`);
//       });
//     });
//
//
//   }
//
//   /**
//    * 记录事件
//    */
//   private recordEvent(eventData: Omit<EventRecord, 'id' | 'timestamp'>): void {
//     const event: EventRecord = {
//       id: this.nextEventId++,
//       timestamp: new Date(),
//       ...eventData
//     };
//
//     this.eventHistory.push(event);
//
//     // 限制历史记录数量
//     if (this.eventHistory.length > this.config.eventHistoryLimit) {
//       this.eventHistory = this.eventHistory.slice(-this.config.eventHistoryLimit);
//     }
//
//     // 触发事件监听器
//     this.triggerEventListeners(event.eventName, event);
//   }
//
//   /**
//    * 触发自定义事件
//    */
//   private emitCustomEvent(eventName: string, data?: any): void {
//     this.recordEvent({
//       type: 'custom',
//       eventName,
//       message: `自定义事件: ${eventName}`,
//       data,
//       level: 'info'
//     });
//   }
//
//   /**
//    * 添加事件监听器
//    */
//   private addEventListener(eventName: string, listener: Function): void {
//     if (!this.eventListeners.has(eventName)) {
//       this.eventListeners.set(eventName, []);
//     }
//     this.eventListeners.get(eventName)!.push(listener);
//   }
//
//   /**
//    * 触发事件监听器
//    */
//   private triggerEventListeners(eventName: string, event: EventRecord): void {
//     const listeners = this.eventListeners.get(eventName) || [];
//     listeners.forEach(listener => {
//       try {
//         listener(event);
//       } catch (error) {
//         console.error(`事件监听器执行错误 [${eventName}]:`, error);
//       }
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
//         stream: (log: string) => {
//           console.log(`📝 ${log}`);
//           // 记录日志事件
//           this.recordEvent({
//             type: 'server',
//             eventName: 'request_log',
//             message: log,
//             level: 'info'
//           });
//         }
//       });
//     }
//
//     if (this.config.enableCors) {
//       this.server.cors({ origin: '*' });
//     }
//
//     this.server.auto();
//     this.server.serveStatic(this.config.staticRoot);
//   }
//
//   /**
//    * 配置路由
//    */
//   private setupRoutes(): void {
//     this.setupEventRoutes();
//     this.setupMonitorRoutes();
//     this.setupTriggerRoutes();
//   }
//
//   /**
//    * 事件查询路由
//    */
//   private setupEventRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 获取事件历史
//     this.server.get('/api/events', (req: HttpRequest, res: HttpResponse) => {
//       const limit = parseInt(req.query.get('limit') || '50');
//       const offset = parseInt(req.query.get('offset') || '0');
//       const type = req.query.get('type');
//       const level = req.query.get('level');
//
//       let filteredEvents = this.eventHistory;
//
//       if (type) {
//         filteredEvents = filteredEvents.filter(event => event.type === type);
//       }
//
//       if (level) {
//         filteredEvents = filteredEvents.filter(event => event.level === level);
//       }
//
//       const events = filteredEvents
//         .slice(offset, offset + limit)
//         .reverse(); // 最新的在前
//
//       res.json({
//         events,
//         total: filteredEvents.length,
//         limit,
//         offset,
//         filters: { type, level }
//       });
//     });
//
//     // 获取特定事件
//     this.server.get('/api/events/:id', (req: HttpRequest, res: HttpResponse) => {
//       const id = parseInt(req.params['id']);
//       const event = this.eventHistory.find(e => e.id === id);
//
//       if (event) {
//         res.json({ event });
//       } else {
//         res.status(404).json({ error: 'Event not found', id });
//       }
//     });
//
//     // 获取事件统计
//     this.server.get('/api/events/stats', (req: HttpRequest, res: HttpResponse) => {
//       // const stats = this.analyzeEvents();
//
//       res.json({
//         // totalEvents: this.eventHistory.length,
//         // byType: stats.byType,
//         // byLevel: stats.byLevel,
//         // recentActivity: stats.recentActivity,
//         // topEvents: stats.topEvents
//       });
//     });
//
//     // 清除事件历史
//     this.server.delete('/api/events', (req: HttpRequest, res: HttpResponse) => {
//       const count = this.eventHistory.length;
//       this.eventHistory = [];
//       this.nextEventId = 1;
//
//       this.emitCustomEvent('events_cleared', { clearedCount: count });
//
//       res.json({
//         message: 'Event history cleared',
//         clearedCount: count
//       });
//     });
//   }
//
//   /**
//    * 监控路由
//    */
//   private setupMonitorRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 实时事件流 (模拟Server-Sent Events)
//     this.server.get('/api/events/stream', (req: HttpRequest, res: HttpResponse) => {
//       // 在真实实现中，这里会建立SSE连接
//       const recentEvents = this.eventHistory.slice(-10).reverse();
//
//       res.json({
//         message: 'Event stream endpoint',
//         note: 'In real implementation, this would be a Server-Sent Events stream',
//         recentEvents,
//         streamUrl: '/api/events/stream'
//       });
//     });
//
//     // 事件监控仪表板数据
//     this.server.get('/api/monitor/dashboard', (req: HttpRequest, res: HttpResponse) => {
//       const now = new Date();
//       const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
//
//       const recentEvents = this.eventHistory.filter(event =>
//       event.timestamp >= oneHourAgo
//       );
//
//       const dashboard = {
//         server: {
//           status: this.isRunning ? 'running' : 'stopped',
//           // uptime: process.uptime(),
//           clientCount: this.server?.getClientCount() || 0
//         },
//         events: {
//           total: this.eventHistory.length,
//           lastHour: recentEvents.length,
//           errorCount: recentEvents.filter(e => e.level === 'error').length,
//           warningCount: recentEvents.filter(e => e.level === 'warn').length
//         },
//         activity: this.getActivityTimeline(recentEvents)
//       };
//
//       res.json(dashboard);
//     });
//   }
//
//   /**
//    * 事件触发路由
//    */
//   private setupTriggerRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 触发自定义事件
//     this.server.post('/api/events/trigger', (req: HttpRequest, res: HttpResponse) => {
//       const { eventName, message, data, level = 'info' } = req.body as any;
//
//       if (!eventName) {
//         return res.status(400).json({ error: 'eventName is required' });
//       }
//
//       this.recordEvent({
//         type: 'custom',
//         eventName,
//         message: message || `Custom event: ${eventName}`,
//         data,
//         level: level as 'info' | 'warn' | 'error'
//       });
//
//       res.json({
//         message: 'Custom event triggered',
//         eventName,
//         triggeredAt: new Date().toISOString()
//       });
//     });
//
//     // 模拟错误事件
//     this.server.post('/api/events/simulate-error', (req: HttpRequest, res: HttpResponse) => {
//       const { errorType = 'test_error', message = 'Simulated error for testing' } = req.body as any;
//
//       this.recordEvent({
//         type: 'error',
//         eventName: errorType,
//         message,
//         data: { simulated: true, triggeredBy: 'api' },
//         level: 'error'
//       });
//
//       res.json({
//         message: 'Error event simulated',
//         errorType,
//         simulatedAt: new Date().toISOString()
//       });
//     });
//
//     // 批量触发事件
//     this.server.post('/api/events/batch-trigger', (req: HttpRequest, res: HttpResponse) => {
//       const { events } = req.body as { events: any[] };
//
//       if (!Array.isArray(events)) {
//         return res.status(400).json({ error: 'events must be an array' });
//       }
//
//       const triggeredEvents = events.map(eventData => {
//         this.recordEvent({
//           type: 'custom',
//           eventName: eventData.eventName || 'batch_event',
//           message: eventData.message || 'Batch triggered event',
//           data: eventData.data,
//           level: eventData.level || 'info'
//         });
//
//         return {
//           eventName: eventData.eventName,
//           triggeredAt: new Date().toISOString()
//         };
//       });
//
//       res.json({
//         message: 'Batch events triggered',
//         count: triggeredEvents.length,
//         events: triggeredEvents
//       });
//     });
//   }
//
//   /**
//    * 分析事件统计
//    */
//   // private analyzeEvents() {
//   //   // 按类型统计
//   //   const byType: Record<string, number> = {};
//   //   this.eventHistory.forEach(event => {
//   //     byType[event.type] = (byType[event.type] || 0) + 1;
//   //   });
//   //
//   //   // 按级别统计
//   //   const byLevel: Record<string, number> = {};
//   //   this.eventHistory.forEach(event => {
//   //     byLevel[event.level] = (byLevel[event.level] || 0) + 1;
//   //   });
//   //
//   //   // 最近活动
//   //   const now = new Date();
//   //   const recentActivity = this.eventHistory.filter(event =>
//   //   now.getTime() - event.timestamp.getTime() < 10 * 60 * 1000 // 最近10分钟
//   //   ).length;
//   //
//   //   // 热门事件
//   //   const eventCounts: Record<string, number> = {};
//   //   this.eventHistory.forEach(event => {
//   //     eventCounts[event.eventName] = (eventCounts[event.eventName] || 0) + 1;
//   //   });
//   //
//   //   // const topEvents = Object.entries(eventCounts)
//   //   //   .sort(([, a], [, b]) => b - a)
//   //   //   .slice(0, 5)
//   //   //   .map(([eventName, count]) => ({ eventName, count } as ESObject));
//   //
//   //   return {
//   //     byType,
//   //     byLevel,
//   //     recentActivity,
//   //     // topEvents
//   //   } as ESObject;
//   // }
//
//   /**
//    * 获取活动时间线
//    */
//   private getActivityTimeline(events: EventRecord[]) {
//     const timeline: Record<string, number> = {};
//
//     events.forEach(event => {
//       const hour = event.timestamp.getHours();
//       const key = `${hour}:00`;
//       timeline[key] = (timeline[key] || 0) + 1;
//     });
//
//     return timeline;
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
//       console.error(`🚨 [Event Error Handler] ${req.method} ${req.path}: ${error.message}`);
//
//       // 记录错误处理事件
//       // this.recordEvent({
//       //   type: 'error',
//       //   eventName: 'global_error_handler',
//       //   message: `Global error: ${error.message}`,
//       //   data: {
//       //     path: req.path,
//       //     method: req.method,
//       //     error: error.message
//       //   },
//       //   level: 'error'
//       // });
//
//       if (res.isHeadersSent()) {
//         return next(error);
//       }
//
//       res.status(500).json({
//         error: 'Event Server Error',
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
//     console.log('\n📡 Event API端点:');
//     console.log('='.repeat(50));
//
//     console.log('📄 演示页面:');
//     console.log(`   GET  ${baseUrl}/event-demo.html         - Event演示页面`);
//     console.log(`   GET  ${baseUrl}/event-monitor.html      - 事件监控页面`);
//
//     console.log('\n📊 事件查询:');
//     console.log(`   GET    ${baseUrl}/api/events            - 获取事件历史`);
//     console.log(`   GET    ${baseUrl}/api/events/:id        - 获取特定事件`);
//     console.log(`   GET    ${baseUrl}/api/events/stats      - 获取事件统计`);
//     console.log(`   DELETE ${baseUrl}/api/events            - 清除事件历史`);
//
//     console.log('\n📡 事件监控:');
//     console.log(`   GET    ${baseUrl}/api/events/stream     - 实时事件流`);
//     console.log(`   GET    ${baseUrl}/api/monitor/dashboard - 监控仪表板`);
//
//     console.log('\n🎯 事件触发:');
//     console.log(`   POST   ${baseUrl}/api/events/trigger    - 触发自定义事件`);
//     console.log(`   POST   ${baseUrl}/api/events/simulate-error - 模拟错误事件`);
//     console.log(`   POST   ${baseUrl}/api/events/batch-trigger - 批量触发事件`);
//
//     console.log('='.repeat(50));
//   }
// }