/**
 * @fileName : TEST_EXAMPLE.ets
 * @author : @cxy
 * @date : 2025/4/11
 * @description : 优化功能测试示例
 */

import { 
  HttpServer, 
  HttpRequest, 
  HttpResponse,
  RateLimit, 
  Compression, 
  Security, 
  Performance 
} from '@cxy/webserver';

/**
 * 测试新增的优化功能
 */
export async function testOptimizations() {
  console.log('========================================');
  console.log('WebServer 优化功能测试');
  console.log('========================================\n');

  // 1. 测试连接池配置
  console.log('1. 测试连接池配置...');
  const server = new HttpServer(
    {
      maxConnections: 100,
      connectionTimeout: 30000,
      idleTimeout: 60000,
      cleanupInterval: 10000
    },
    {
      maxSize: 50 * 1024 * 1024,
      maxAge: 3600000,
      maxEntries: 500
    }
  );
  console.log('✅ 连接池配置成功\n');

  // 2. 测试安全中间件
  console.log('2. 测试安全中间件...');
  server.use(Security.create({
    enableXssProtection: true,
    enableFrameGuard: true,
    maxRequestSize: 10 * 1024 * 1024
  }));
  console.log('✅ 安全中间件已启用\n');

  // 3. 测试限流中间件
  console.log('3. 测试限流中间件...');
  server.use(RateLimit.create({
    windowMs: 60000,
    max: 10,
    message: '测试限流'
  }));
  console.log('✅ 限流中间件已启用\n');

  // 4. 测试压缩中间件
  console.log('4. 测试压缩中间件...');
  server.use(Compression.create({
    threshold: 1024,
    level: 6
  }));
  console.log('✅ 压缩中间件已启用\n');

  // 5. 测试性能监控
  console.log('5. 测试性能监控...');
  server.use(Performance.create({
    sampleRate: 1.0,
    slowThreshold: 1000,
    onSlowRequest: (req: HttpRequest, duration: number) => {
      console.log(`⚠️  慢请求: ${req.method} ${req.path} - ${duration}ms`);
    }
  }));
  console.log('✅ 性能监控已启用\n');

  // 6. 测试路由
  console.log('6. 配置测试路由...');
  
  // 健康检查
  server.get('/health', (req: HttpRequest, res: HttpResponse) => {
    const stats = server.getCacheStats();
    res.json({
      status: 'healthy',
      connections: server.getClientCount(),
      cache: {
        entries: stats.entries,
        size: `${(stats.size / 1024 / 1024).toFixed(2)}MB`,
        hitRate: `${(stats.hitRate * 100).toFixed(2)}%`
      }
    } as ESObject);
  });

  // 性能指标
  server.get('/metrics', (req: HttpRequest, res: HttpResponse) => {
    res.setHeader('Content-Type', 'text/plain');
    res.send(Performance.getReport());
  });

  // 测试限流
  server.get('/test-rate-limit', (req: HttpRequest, res: HttpResponse) => {
    res.json({ message: '限流测试' } as ESObject);
  });

  // 测试压缩
  server.get('/test-compression', (req: HttpRequest, res: HttpResponse) => {
    const largeData = 'x'.repeat(10000); // 10KB数据
    res.json({ data: largeData } as ESObject);
  });

  // 测试安全防护
  server.get('/test-security', (req: HttpRequest, res: HttpResponse) => {
    res.json({ 
      message: '检查响应头中的安全标识',
      headers: {
        'X-XSS-Protection': res.getHeader('X-XSS-Protection'),
        'X-Frame-Options': res.getHeader('X-Frame-Options'),
        'X-Content-Type-Options': res.getHeader('X-Content-Type-Options')
      }
    } as ESObject);
  });

  console.log('✅ 测试路由配置完成\n');

  // 7. 启动服务器
  console.log('7. 启动测试服务器...');
  try {
    const info = await server.startServer(8888);
    console.log(`✅ 服务器已启动: http://${info.address}:${info.port}\n`);

    // 8. 输出测试说明
    console.log('========================================');
    console.log('测试端点:');
    console.log('========================================');
    console.log(`健康检查: http://${info.address}:${info.port}/health`);
    console.log(`性能指标: http://${info.address}:${info.port}/metrics`);
    console.log(`限流测试: http://${info.address}:${info.port}/test-rate-limit`);
    console.log(`压缩测试: http://${info.address}:${info.port}/test-compression`);
    console.log(`安全测试: http://${info.address}:${info.port}/test-security`);
    console.log('========================================\n');

    // 9. 测试命令
    console.log('测试命令:');
    console.log('========================================');
    console.log(`# 健康检查`);
    console.log(`curl http://${info.address}:${info.port}/health\n`);
    
    console.log(`# 性能指标`);
    console.log(`curl http://${info.address}:${info.port}/metrics\n`);
    
    console.log(`# 限流测试（快速发送多个请求）`);
    console.log(`for i in {1..15}; do curl http://${info.address}:${info.port}/test-rate-limit; done\n`);
    
    console.log(`# 压缩测试（检查响应头）`);
    console.log(`curl -H "Accept-Encoding: gzip" -i http://${info.address}:${info.port}/test-compression\n`);
    
    console.log(`# 安全测试（检查安全响应头）`);
    console.log(`curl -i http://${info.address}:${info.port}/test-security\n`);
    console.log('========================================\n');

    // 10. 定期输出统计
    setInterval(() => {
      console.log('\n--- 服务器统计 ---');
      console.log(Performance.getReport());
      
      const cacheStats = server.getCacheStats();
      console.log('\n缓存统计:');
      console.log(`  条目数: ${cacheStats.entries}`);
      console.log(`  大小: ${(cacheStats.size / 1024 / 1024).toFixed(2)}MB`);
      console.log(`  命中率: ${(cacheStats.hitRate * 100).toFixed(2)}%`);
      console.log(`  连接数: ${server.getClientCount()}`);
      console.log('-------------------\n');
    }, 30000); // 每30秒输出一次

    return server;
  } catch (error) {
    console.error('❌ 服务器启动失败:', error);
    throw error;
  }
}

/**
 * 运行测试
 */
export async function runTest() {
  try {
    const server = await testOptimizations();
    
    console.log('✅ 所有测试配置完成！');
    console.log('💡 提示: 使用上面的curl命令测试各项功能\n');

    // 优雅关闭
    const shutdown = async () => {
      console.log('\n正在关闭测试服务器...');
      await server.stopServer();
      console.log('✅ 测试服务器已关闭');
      process.exit(0);
    };

    if (process.on) {
      process.on('SIGINT', shutdown);
      process.on('SIGTERM', shutdown);
    }

  } catch (error) {
    console.error('❌ 测试失败:', error);
    process.exit(1);
  }
}

// 如果直接运行此文件
// runTest();
