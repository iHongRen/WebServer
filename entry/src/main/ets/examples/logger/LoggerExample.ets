// /**
//  * @fileName : LoggerExample.ets
//  * @author : @cxy
//  * @date : 2025/10/29
//  * @description : Logger示例 - 展示日志记录功能
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
//   NextFunction,
// } from '@cxy/webserver';
// import { util } from '@kit.ArkTS';
//
// /**
//  * 日志配置接口
//  */
// interface LoggerConfig {
//   port: number;
//   staticRoot: string;
//   enableCors: boolean;
//   logFormat: 'dev' | 'combined' | 'common' | 'short' | 'tiny';
//   logLevel: 'debug' | 'info' | 'warn' | 'error';
//   logToFile: boolean;
//   logFilePath: string;
// }
//
// /**
//  * 日志记录接口
//  */
// interface LogRecord {
//   id: number;
//   timestamp: Date;
//   level: 'debug' | 'info' | 'warn' | 'error';
//   method: string;
//   url: string;
//   statusCode: number;
//   responseTime: number;
//   userAgent: string;
//   ip: string;
//   message: string;
// }
//
// /**
//  * Logger示例类
//  * 展示各种日志记录功能和格式
//  */
// export class LoggerExample {
//   private server: HttpServer | null = null;
//   private serverInfo: ServerInfo | null = null;
//   private isRunning: boolean = false;
//   private config: LoggerConfig;
//   private context: common.UIAbilityContext;
//   // 日志记录
//   private logRecords: LogRecord[] = [];
//   private nextLogId: number = 1;
//
//   constructor(context: common.UIAbilityContext, config?: Partial<LoggerConfig>) {
//     this.context = context;
//     this.config = {
//       port: config?.port || 8085,
//       staticRoot: config?.staticRoot || context.filesDir + '/static',
//       enableCors: config?.enableCors || true,
//       logFormat: config?.logFormat || 'dev',
//       logLevel: config?.logLevel || 'info',
//       logToFile: config?.logToFile || true,
//       logFilePath: config?.logFilePath || context.filesDir + '/server.log',
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
//     await this.copyStaticFile('logger-demo.html');
//     await this.copyStaticFile('log-viewer.html');
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
//         throw new Error('Logger服务器初始化失败');
//       }
//
//       const info = await this.server.startServer(this.config.port);
//
//       if (info.address) {
//         this.serverInfo = info;
//         this.isRunning = true;
//
//         console.log('✅ Logger服务器启动成功!');
//         console.log(`🌐 访问地址: http://${info.address}:${info.port}`);
//         this.printApiEndpoints(info);
//
//         return info;
//       } else {
//         throw new Error('未能获取服务器地址');
//       }
//     } catch (error) {
//       console.error('❌ 启动Logger服务器失败:', error);
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
//       console.log('🛑 Logger服务器已停止');
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
//   public getConfig(): LoggerConfig {
//     return this.config;
//   }
//
//   public getLogCount(): number {
//     return this.logRecords.length;
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
//       this.writeLog('error', `服务器错误: ${JSON.stringify(error)}`, {
//         errorType: error.type
//       });
//     });
//
//     this.server.on(ServerEventType.SERVER_STARTED, (event) => {
//       this.writeLog('info', '服务器启动成功', event.data);
//     });
//
//     this.server.on(ServerEventType.SERVER_STOPPED, () => {
//       this.writeLog('info', '服务器已停止');
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
//     if (this.config.enableCors) {
//       this.server.cors({ origin: '*' });
//     }
//
//     // 自定义日志中间件
//     this.server.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
//       const startTime = Date.now();
//
//       // 记录请求开始
//       this.writeLog('debug', `请求开始: ${req.method} ${req.path}`, {
//         method: req.method,
//         url: req.path,
//         userAgent: req.userAgent,
//         ip: req.ip
//       });
//
//       // 监听响应完成
//       res.onFinish((statusCode, responseSize) => {
//         const responseTime = Date.now() - startTime;
//
//         // 记录详细的请求日志
//         const logRecord: LogRecord = {
//           id: this.nextLogId++,
//           timestamp: new Date(),
//           level: statusCode >= 400 ? 'error' : statusCode >= 300 ? 'warn' : 'info',
//           method: req.method,
//           url: req.url,
//           statusCode,
//           responseTime,
//           userAgent: req.userAgent,
//           ip: req.ip,
//           message: this.formatLogMessage(req, statusCode, responseTime, responseSize)
//         };
//
//         this.logRecords.push(logRecord);
//
//         // 限制日志记录数量
//         if (this.logRecords.length > 1000) {
//           this.logRecords = this.logRecords.slice(-1000);
//         }
//
//         // 写入文件日志
//         if (this.config.logToFile) {
//           this.writeToFile(logRecord);
//         }
//
//         console.log(`📝 ${logRecord.message}`);
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
//    * 格式化日志消息
//    */
//   private formatLogMessage(req: HttpRequest, statusCode: number, responseTime: number, responseSize: number): string {
//     const timestamp = new Date().toISOString();
//
//     switch (this.config.logFormat) {
//       case 'combined':
//         return `${req.ip} - - [${timestamp}] "${req.method} ${req.url} HTTP/1.1" ${statusCode} ${responseSize} "${req.referer}" "${req.userAgent}"`;
//
//       case 'common':
//         return `${req.ip} - - [${timestamp}] "${req.method} ${req.url} HTTP/1.1" ${statusCode} ${responseSize}`;
//
//       case 'short':
//         return `${req.ip} ${req.method} ${req.url} HTTP/1.1 ${statusCode} ${responseSize} - ${responseTime}ms`;
//
//       case 'tiny':
//         return `${req.method} ${req.url} ${statusCode} ${responseSize} - ${responseTime}ms`;
//
//       case 'dev':
//       default:
//         const statusColor = statusCode >= 400 ? '🔴' : statusCode >= 300 ? '🟡' : '🟢';
//         return `${statusColor} ${req.method} ${req.url} ${statusCode} ${responseTime}ms - ${responseSize}b`;
//     }
//   }
//
//   /**
//    * 写入日志
//    */
//   private writeLog(level: 'debug' | 'info' | 'warn' | 'error', message: string, data?: ESObject): void {
//     const logLevels = {
//       'debug': 0,
//       'info': 1,
//       'warn': 2,
//       'error': 3
//     } as Record<string, number>
//     const configLevel = logLevels[this.config.logLevel];
//     const messageLevel = logLevels[level];
//
//     if (messageLevel >= configLevel) {
//       const timestamp = new Date().toISOString();
//       const logMessage = `[${timestamp}] [${level.toUpperCase()}] ${message}`;
//
//       if (data) {
//         console.log(logMessage, data);
//       } else {
//         console.log(logMessage);
//       }
//
//       if (this.config.logToFile) {
//         this.writeToFile({
//           id: this.nextLogId++,
//           timestamp: new Date(),
//           level,
//           method: '',
//           url: '',
//           statusCode: 0,
//           responseTime: 0,
//           userAgent: '',
//           ip: '',
//           message: logMessage
//         });
//       }
//     }
//   }
//
//   /**
//    * 写入文件日志
//    */
//   private async writeToFile(logRecord: LogRecord): Promise<void> {
//     try {
//       const logLine = `${logRecord.message}\n`;
//       const file = await fileIo.open(this.config.logFilePath,
//         fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.APPEND);
//       await fileIo.write(file.fd, new util.TextEncoder().encode(logLine).buffer);
//       await fileIo.close(file.fd);
//     } catch (error) {
//       console.error('写入日志文件失败:', error);
//     }
//   }
//
//   /**
//    * 配置路由
//    */
//   private setupRoutes(): void {
//     this.setupLogRoutes();
//     this.setupConfigRoutes();
//     this.setupTestRoutes();
//   }
//
//   /**
//    * 日志查询路由
//    */
//   private setupLogRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 获取日志记录
//     this.server.get('/api/logs', (req: HttpRequest, res: HttpResponse) => {
//       const limit = parseInt(req.query.get('limit') || '50');
//       const offset = parseInt(req.query.get('offset') || '0');
//       const level = req.query.get('level');
//       const method = req.query.get('method');
//
//       let filteredLogs = this.logRecords;
//
//       if (level) {
//         filteredLogs = filteredLogs.filter(log => log.level === level);
//       }
//
//       if (method) {
//         filteredLogs = filteredLogs.filter(log => log.method === method);
//       }
//
//       const logs = filteredLogs
//         .slice(offset, offset + limit)
//         .reverse();
//
//       res.json({
//         logs,
//         total: filteredLogs.length,
//         limit,
//         offset,
//         filters: { level, method } as ESObject
//       });
//     });
//
//     // 获取日志统计
//     this.server.get('/api/logs/stats', (req: HttpRequest, res: HttpResponse) => {
//       const stats = this.analyzeLogStats();
//
//       res.json({
//         totalLogs: this.logRecords.length,
//         byLevel: stats.byLevel,
//         byMethod: stats.byMethod,
//         byStatusCode: stats.byStatusCode,
//         averageResponseTime: stats.averageResponseTime,
//         errorRate: stats.errorRate
//       });
//     });
//
//     // 清除日志记录
//     this.server.delete('/api/logs', (req: HttpRequest, res: HttpResponse) => {
//       const count = this.logRecords.length;
//       this.logRecords = [];
//       this.nextLogId = 1;
//
//       res.json({
//         message: 'Log records cleared',
//         clearedCount: count
//       });
//     });
//   }
//
//   /**
//    * 配置管理路由
//    */
//   private setupConfigRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 获取日志配置
//     this.server.get('/api/logs/config', (req: HttpRequest, res: HttpResponse) => {
//       res.json({
//         config: this.config,
//         availableFormats: ['dev', 'combined', 'common', 'short', 'tiny'],
//         availableLevels: ['debug', 'info', 'warn', 'error']
//       });
//     });
//
//     // 更新日志配置
//     this.server.post('/api/logs/config', (req: HttpRequest, res: HttpResponse) => {
//       const data = req.body as Record<string, string>;
//
//       // if (data.logFormat) {
//       //   this.config.logFormat = data.logFormat;
//       // }
//       // if (data.logLevel) {
//       //   this.config.logLevel = data.logLevel;
//       // }
//       // if (data.logToFile !== undefined) {
//       //   this.config.logToFile = data.logToFile;
//       // }
//       //
//       // this.writeLog('info', '日志配置已更新', {
//       //   newFormat: this.config.logFormat,
//       //   newLevel: this.config.logLevel,
//       //   fileLogging: this.config.logToFile
//       // });
//
//       res.json({
//         message: 'Logger configuration updated',
//         config: this.config
//       });
//     });
//   }
//
//   /**
//    * 测试路由
//    */
//   private setupTestRoutes(): void {
//     if (!this.server) {
//       return;
//     }
//
//     // 测试不同级别的日志
//     this.server.post('/api/logs/test/:level', (req: HttpRequest, res: HttpResponse) => {
//       const level = req.params['level'] as 'debug' | 'info' | 'warn' | 'error';
//       const message = `测试${level}级别日志`;
//
//       this.writeLog(level, message, {
//         testData: req.body,
//         triggeredBy: 'api'
//       });
//
//       res.json({
//         message: `${level} log generated`,
//         logLevel: level,
//         timestamp: new Date().toISOString()
//       });
//     });
//
//     // 模拟慢请求
//     this.server.get('/api/test/slow', (req: HttpRequest, res: HttpResponse) => {
//       const delay = parseInt(req.query.get('delay') || '1000');
//
//       setTimeout(() => {
//         res.json({
//           message: 'Slow request completed',
//           delay,
//           timestamp: new Date().toISOString()
//         });
//       }, delay);
//     });
//
//     // 模拟错误请求
//     this.server.get('/api/test/error/:code', (req: HttpRequest, res: HttpResponse) => {
//       const statusCode = parseInt(req.params['code']);
//
//       res.status(statusCode).json({
//         error: `Simulated ${statusCode} error`,
//         timestamp: new Date().toISOString()
//       });
//     });
//   }
//
//   /**
//    * 分析日志统计
//    */
//   private analyzeLogStats(): ESObject {
//     const byLevel: Record<string, number> = {};
//     const byMethod: Record<string, number> = {};
//     const byStatusCode: Record<string, number> = {};
//     let totalResponseTime = 0;
//     let errorCount = 0;
//
//     this.logRecords.forEach(log => {
//       byLevel[log.level] = (byLevel[log.level] || 0) + 1;
//       byMethod[log.method] = (byMethod[log.method] || 0) + 1;
//       byStatusCode[log.statusCode] = (byStatusCode[log.statusCode] || 0) + 1;
//
//       totalResponseTime += log.responseTime;
//
//       if (log.statusCode >= 400) {
//         errorCount++;
//       }
//     });
//
//     return {
//       byLevel,
//       byMethod,
//       byStatusCode,
//       averageResponseTime: this.logRecords.length > 0 ? totalResponseTime / this.logRecords.length : 0,
//       errorRate: this.logRecords.length > 0 ? (errorCount / this.logRecords.length) * 100 : 0
//     } as ESObject;
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
//       this.writeLog('error', `全局错误处理: ${error.message}`, {
//         path: req.path,
//         method: req.method,
//         error: error.message
//       });
//
//       if (res.isHeadersSent()) {
//         return next(error);
//       }
//
//       res.status(500).json({
//         error: 'Logger Server Error',
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
//     console.log('\n📝 Logger API端点:');
//     console.log('='.repeat(50));
//
//     console.log('📄 演示页面:');
//     console.log(`   GET  ${baseUrl}/logger-demo.html       - Logger演示页面`);
//     console.log(`   GET  ${baseUrl}/log-viewer.html        - 日志查看器`);
//
//     console.log('\n📊 日志查询:');
//     console.log(`   GET    ${baseUrl}/api/logs             - 获取日志记录`);
//     console.log(`   GET    ${baseUrl}/api/logs/stats       - 获取日志统计`);
//     console.log(`   DELETE ${baseUrl}/api/logs             - 清除日志记录`);
//
//     console.log('\n⚙️  日志配置:');
//     console.log(`   GET    ${baseUrl}/api/logs/config      - 获取日志配置`);
//     console.log(`   POST   ${baseUrl}/api/logs/config      - 更新日志配置`);
//
//     console.log('\n🧪 日志测试:');
//     console.log(`   POST   ${baseUrl}/api/logs/test/:level - 测试日志级别`);
//     console.log(`   GET    ${baseUrl}/api/test/slow        - 慢请求测试`);
//     console.log(`   GET    ${baseUrl}/api/test/error/:code - 错误请求测试`);
//
//     console.log('='.repeat(50));
//   }
// }