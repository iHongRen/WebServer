/**
 * @fileName : PRODUCTION_EXAMPLE.ets
 * @author : @cxy
 * @date : 2025/4/11
 * @description : 生产级服务器配置示例
 */

import { 
  HttpServer, 
  HttpRequest, 
  HttpResponse,
  RateLimit, 
  Compression, 
  Security, 
  Performance,
  Logger,
  LogFormat
} from '@cxy/webserver';
import { ServerEventType, ServerErrorType } from '@cxy/webserver';

/**
 * 创建生产级HTTP服务器
 */
export function createProductionServer(): HttpServer {
  // 创建服务器实例，配置连接池和缓存
  const server = new HttpServer(
    // 连接池配置
    {
      maxConnections: 2000,      // 最大2000个并发连接
      connectionTimeout: 30000,  // 连接超时30秒
      idleTimeout: 60000,        // 空闲超时60秒
      cleanupInterval: 10000     // 每10秒清理一次
    },
    // 响应缓存配置
    {
      maxSize: 200 * 1024 * 1024,  // 200MB缓存
      maxAge: 3600000,              // 1小时过期
      maxEntries: 2000              // 最多2000个缓存条目
    }
  );

  // ==================== 安全防护 ====================
  
  // 基础安全头部
  server.use(Security.create({
    enableXssProtection: true,
    enableFrameGuard: true,
    enableContentTypeNoSniff: true,
    enableHsts: true,
    hstsMaxAge: 31536000,  // 1年
    enableCsp: true,
    cspDirectives: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'",
    maxRequestSize: 10 * 1024 * 1024,  // 10MB
    maxUrlLength: 2048,
    maxHeaderSize: 8192
  }));

  // XSS过滤
  server.use(Security.xssFilter());

  // SQL注入防护
  server.use(Security.sqlInjectionProtection());

  // ==================== 限流保护 ====================
  
  // 全局限流：每分钟100个请求
  server.use(RateLimit.create({
    windowMs: 60000,
    max: 100,
    message: '请求过于频繁，请稍后再试',
    statusCode: 429
  }));

  // ==================== 性能优化 ====================
  
  // 启用Gzip压缩
  server.use(Compression.create({
    threshold: 1024,  // 1KB以上才压缩
    level: 6,         // 压缩级别
    filter: (req: HttpRequest, res: HttpResponse) => {
      const contentType = res.getHeader('content-type') || '';
      return /text|json|javascript|xml|svg/.test(contentType);
    }
  }));

  // 性能监控
  server.use(Performance.create({
    sampleRate: 0.1,  // 10%采样率
    slowThreshold: 1000,  // 1秒为慢请求
    onSlowRequest: (req: HttpRequest, duration: number) => {
      console.warn(`[慢请求] ${req.method} ${req.path} - ${duration}ms`);
    }
  }));

  // ==================== 日志记录 ====================
  
  // 生产环境使用combined格式
  server.use(Logger.create({
    format: LogFormat.COMBINED,
    skip: (req: HttpRequest, res: HttpResponse) => {
      // 跳过健康检查请求
      return req.path === '/health';
    }
  }));

  // ==================== 请求处理 ====================
  
  // 自动解析请求体
  server.auto();

  // CORS配置
  server.cors({
    origin: ['https://example.com', 'https://app.example.com'],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
  });

  // ==================== 路由定义 ====================
  
  // 健康检查
  server.get('/health', (req: HttpRequest, res: HttpResponse) => {
    const stats = server.getCacheStats();
    const perfMetrics = Performance.getMetrics();
    
    res.json({
      status: 'healthy',
      timestamp: Date.now(),
      uptime: process.uptime ? process.uptime() : 0,
      connections: server.getClientCount(),
      cache: {
        entries: stats.entries,
        size: `${(stats.size / 1024 / 1024).toFixed(2)}MB`,
        hitRate: `${(stats.hitRate * 100).toFixed(2)}%`
      },
      performance: {
        totalRequests: perfMetrics.totalRequests,
        successRate: `${((perfMetrics.successfulRequests / perfMetrics.totalRequests) * 100).toFixed(2)}%`,
        avgResponseTime: `${perfMetrics.averageResponseTime.toFixed(2)}ms`,
        rps: perfMetrics.requestsPerSecond.toFixed(2)
      }
    } as ESObject);
  });

  // 性能报告
  server.get('/metrics', (req: HttpRequest, res: HttpResponse) => {
    res.setHeader('Content-Type', 'text/plain');
    res.send(Performance.getReport());
  });

  // API示例 - 带限流
  server.post('/api/data',
    RateLimit.create({ windowMs: 60000, max: 10 }),  // API限流更严格
    (req: HttpRequest, res: HttpResponse) => {
      // 处理数据
      res.json({
        success: true,
        data: req.body
      } as ESObject);
    }
  );

  // 静态文件服务
  server.serveStatic('/data/storage/el2/base/haps/entry/files/public', {
    maxAge: 86400  // 1天缓存
  });

  // ==================== 错误处理 ====================
  
  // 监听服务器错误
  server.onError((error) => {
    console.error(`[服务器错误] 类型: ${error.type}`);
    if (error.error) {
      console.error(`[服务器错误] 详情: ${error.error.message}`);
    }

    // 根据错误类型采取措施
    switch (error.type) {
      case ServerErrorType.STARTUP_FAILED:
        console.error('[致命错误] 服务器启动失败');
        break;
      case ServerErrorType.LISTEN_ERROR:
        console.error('[致命错误] 端口监听失败');
        break;
      case ServerErrorType.CLIENT_ERROR:
        // 客户端错误，记录但不影响服务器
        break;
      case ServerErrorType.SOCKET_ERROR:
        console.error('[警告] Socket错误');
        break;
    }
  });

  // 监听服务器事件
  server.on(ServerEventType.SERVER_STARTED, (event) => {
    console.log(`[服务器] 已启动在 ${event.data?.address}:${event.data?.port}`);
  });

  server.on(ServerEventType.SERVER_STOPPED, () => {
    console.log('[服务器] 已停止');
  });

  // ==================== 定期维护 ====================
  
  // 每分钟输出性能报告
  setInterval(() => {
    console.log('\n' + Performance.getReport());
    
    const cacheStats = server.getCacheStats();
    console.log(`\n缓存统计:`);
    console.log(`  条目数: ${cacheStats.entries}`);
    console.log(`  大小: ${(cacheStats.size / 1024 / 1024).toFixed(2)}MB`);
    console.log(`  命中率: ${(cacheStats.hitRate * 100).toFixed(2)}%`);
    console.log(`  连接数: ${server.getClientCount()}\n`);
  }, 60000);

  // 每小时检查缓存命中率
  setInterval(() => {
    const stats = server.getCacheStats();
    if (stats.hitRate < 0.3) {
      console.warn('[警告] 缓存命中率过低，考虑调整缓存策略');
    }
  }, 3600000);

  return server;
}

/**
 * 启动生产服务器
 */
export async function startProductionServer(port: number = 8080, address?: string): Promise<void> {
  const server = createProductionServer();

  try {
    const info = await server.startServer(port, address);
    console.log(`\n========================================`);
    console.log(`🚀 生产服务器已启动`);
    console.log(`📍 地址: ${info.address}:${info.port}`);
    console.log(`🔒 安全防护: 已启用`);
    console.log(`⚡ 性能优化: 已启用`);
    console.log(`📊 监控: 已启用`);
    console.log(`========================================\n`);

    // 优雅关闭
    const shutdown = async () => {
      console.log('\n正在关闭服务器...');
      await server.stopServer();
      console.log('服务器已关闭');
      process.exit(0);
    };

    // 注册关闭信号处理
    if (process.on) {
      process.on('SIGINT', shutdown);
      process.on('SIGTERM', shutdown);
    }

  } catch (error) {
    console.error('服务器启动失败:', error);
    process.exit(1);
  }
}

// 使用示例
// startProductionServer(8080);
