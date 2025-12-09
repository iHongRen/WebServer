/**
 * @fileName : CorsExample.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : CORS示例 - 展示跨域资源共享功能
 */

import {
  HttpServer, HttpRequest, HttpResponse, NextFunction,
} from '@cxy/webserver';
import { socket } from '@kit.NetworkKit';

/**
 * CORS配置接口，用于定义服务器的CORS策略和行为
 */
interface CorsConfig {
  corsOrigins: string[]; // 允许的来源
  corsMethods: string[]; // 允许的HTTP方法
  corsHeaders: string[]; // 允许的请求头
  corsCredentials: boolean; // 是否支持凭证
}

interface CorsRequests {
  id: number;
  origin: string;
  method: string;
  headers: string[];
  allowed: boolean;
  timestamp: Date;
}

/**
 * CORS示例类
 * 封装了用于演示CORS功能的HttpServer实例
 */
export class CorsExample {
  private server: HttpServer | null = null;
  private config: CorsConfig;
  // 用于存储和统计CORS请求
  private corsRequests: Array<CorsRequests> = [];
  private nextId: number = 1;

  constructor() {
    this.config = {
      corsOrigins: ['*'],
      corsMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      corsHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
      corsCredentials: true,
    };
  }


  /**
   * 初始化服务器，设置事件监听、中间件和路由
   */
  public initializeServer(): void {
    this.server = new HttpServer();

    this.setupMiddleware();
    this.setupRoutes();
  }

  /**
   * 启动服务器
   */
  public async start(port: number): Promise<socket.NetAddress | null> {
    try {
      if (!this.server) {
        this.initializeServer();
      }

      if (!this.server) {
        throw new Error('CORS服务器初始化失败');
      }

      const info = await this.server.startServer(port);

      if (info.address) {
        console.log('✅ CORS服务器启动成功!');
        console.log(`🌐 访问地址: http://${info.address}:${info.port}`);
        this.printApiEndpoints(info);

        return info;
      } else {
        throw new Error('未能获取服务器地址');
      }
    } catch (error) {
      console.error('❌ 启动CORS服务器失败:', error);
      return null;
    }
  }

  /**
   * 停止服务器
   */
  public async stop(): Promise<void> {
    if (this.server) {
      await this.server.stopServer();
      console.log('🛑 CORS服务器已停止');
    }
  }


  public getCorsRequestCount(): number {
    return this.corsRequests.length;
  }


  /**
   * 配置中间件
   */
  private setupMiddleware(): void {
    if (!this.server) {
      return;
    }

    // 1. 日志中间件
    this.server.logger({
      format: 'dev',
      stream: (log: string) => console.log(`🌐 ${log}`)
    });

    // 2. 自定义中间件，用于在CORS处理前记录所有传入的跨域请求
    this.server.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      const origin = req.get('origin') || req.get('referer') || 'unknown';
      const method = req.method;
      const requestedHeaders = req.get('access-control-request-headers')?.split(',') || [];

      // 记录CORS请求，用于统计和分析
      const corsRequest: CorsRequests = {
        id: this.nextId++,
        origin,
        method,
        headers: requestedHeaders,
        allowed: this.isOriginAllowed(origin), // 检查来源是否在白名单中
        timestamp: new Date()
      };
      this.corsRequests.push(corsRequest);

      console.log(`🌐 CORS请求: ${method} from ${origin} - ${corsRequest.allowed ? '✅ 允许' : '❌ 拒绝'}`);

      next(); // 将请求传递给下一个中间件
    });

    // 3. 核心CORS中间件
    this.server.cors({
      origin: this.config.corsOrigins,
      methods: this.config.corsMethods,
      allowedHeaders: this.config.corsHeaders
    });

    // 4. 其他中间件
    this.server.auto(); // 自动解析请求体
  }

  /**
   * 检查给定的 origin 是否在允许的列表中
   */
  private isOriginAllowed(origin: string): boolean {
    if (this.config.corsOrigins.includes('*')) {
      return true;
    }
    return this.config.corsOrigins.some(allowed =>
    origin.includes(allowed) || allowed.includes(origin)
    );
  }

  /**
   * 集中配置所有路由
   */
  private setupRoutes(): void {
    this.setupCorsTestRoutes();
    this.setupCorsConfigRoutes();
  }

  /**
   * CORS测试路由，用于演示不同类型的CORS请求
   */
  private setupCorsTestRoutes(): void {
    if (!this.server) {
      return;
    }

    // 用于测试简单请求 (e.g., GET)
    this.server.get('/api/cors/simple', (req: HttpRequest, res: HttpResponse) => {
      const origin = req.get('origin') || 'unknown';

      res.json({
        message: 'CORS简单请求测试成功',
        origin,
        method: req.method,
        timestamp: new Date().toISOString(),
        corsType: 'Simple Request'
      });
    });

    // 用于测试需要预检的请求 (e.g., POST with custom headers)
    this.server.post('/api/cors/preflight', (req: HttpRequest, res: HttpResponse) => {
      const origin = req.get('origin') || 'unknown';

      res.json({
        message: 'CORS预检请求测试成功',
        origin,
        method: req.method,
        body: req.body,
        timestamp: new Date().toISOString(),
        corsType: 'Preflight Request'
      });
    });

    // 用于测试带凭证的请求 (e.g., with cookies)
    this.server.post('/api/cors/credentials', (req: HttpRequest, res: HttpResponse) => {
      const origin = req.get('origin') || 'unknown';
      const cookies = req.get('cookie') || 'none';

      // 设置一个测试cookie以供客户端接收
      res.setHeader('Set-Cookie', 'cors-test=success; Path=/; HttpOnly');

      res.json({
        message: 'CORS凭证请求测试成功',
        origin,
        cookies,
        credentialsSupported: this.config.corsCredentials,
        timestamp: new Date().toISOString(),
        corsType: 'Credentialed Request'
      });
    });

    // 用于测试带自定义请求头的请求
    this.server.put('/api/cors/custom-headers', (req: HttpRequest, res: HttpResponse) => {
      const origin = req.get('origin') || 'unknown';
      const customHeader = req.get('x-custom-header') || 'none';
      const authorization = req.get('authorization') || 'none';

      res.json({
        message: 'CORS自定义头部测试成功',
        origin,
        customHeader,
        authorization,
        allowedHeaders: this.config.corsHeaders,
        timestamp: new Date().toISOString(),
        corsType: 'Custom Headers Request'
      });
    });
  }

  /**
   * CORS配置管理路由
   */
  private setupCorsConfigRoutes(): void {
    if (!this.server) {
      return;
    }


    // 获取当前CORS配置
    this.server.get('/api/cors/config', (req: HttpRequest, res: HttpResponse) => {
      res.json({
        corsConfig: {
          'origins': this.config.corsOrigins,
          'methods': this.config.corsMethods,
          'headers': this.config.corsHeaders,
          'credentials': this.config.corsCredentials
        } as Record<string, Object>,
        description: {
          'origins': 'Allowed origins for CORS requests',
          'methods': 'Allowed HTTP methods',
          'headers': 'Allowed request headers',
          'credentials': 'Whether credentials are supported'
        } as Record<string, Object>
      });
    });


    // 测试特定来源是否被允许
    this.server.post('/api/cors/test-origin', (req: HttpRequest, res: HttpResponse) => {
      const body = req.body as Record<string, string>;
      const allowed = this.isOriginAllowed(body.testOrigin);

      res.json({
        origin: body.testOrigin,
        allowed,
        reason: allowed ? 'Origin is in allowed list' : 'Origin not in allowed list',
        allowedOrigins: this.config.corsOrigins
      });
    });
  }


  /**
   * 在控制台打印所有可用的API端点和测试信息
   */
  private printApiEndpoints(info: socket.NetAddress): void {
    const baseUrl = `http://${info.address}:${info.port}`;

    console.log('\n🌐 CORS API端点:');
    console.log('='.repeat(60));

    console.log('\n🧪 CORS测试 API:');
    console.log(`   GET    ${baseUrl}/api/cors/simple       (简单请求)`);
    console.log(`   POST   ${baseUrl}/api/cors/preflight    (预检请求)`);
    console.log(`   POST   ${baseUrl}/api/cors/credentials  (凭证请求)`);
    console.log(`   PUT    ${baseUrl}/api/cors/custom-headers (自定义头部)`);

    console.log('\n⚙️  CORS配置 API:');
    console.log(`   GET    ${baseUrl}/api/cors/config       (获取配置)`);
    console.log(`   POST   ${baseUrl}/api/cors/test-origin  (测试来源)`);

    console.log('\n🚀 测试命令:');
    console.log(`   sh ./test-cors.sh`);
    console.log('='.repeat(60));
  }
}