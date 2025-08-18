/**
 * @fileName : LoggerTestSimple.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : 简化的日志中间件测试
 */

import { WebServer } from '../WebServer';
import { Logger, LogFormat } from '../middleware';

/**
 * 测试新的回调式日志中间件
 */
export async function testCallbackLogger() {
  console.log('=== 测试回调式日志中间件 ===');
  
  const app = new WebServer();

  // 测试不同的日志格式
  console.log('\n1. 开发环境格式测试:');
  app.use(Logger.dev());

  // 基本路由
  app.get('/', (req, res) => {
    res.json({ 
      message: 'Hello World!', 
      timestamp: new Date().toISOString(),
      method: req.method,
      path: req.path
    });
  });

  app.get('/users/:id', (req, res) => {
    const userId = req.params.id;
    res.json({ 
      user: { id: userId, name: `User ${userId}` },
      timestamp: new Date().toISOString()
    });
  });

  app.post('/api/data', (req, res) => {
    res.status(201).json({ 
      message: 'Data created',
      received: req.body,
      timestamp: new Date().toISOString()
    });
  });

  // 错误测试
  app.get('/error', (req, res) => {
    res.status(500).json({ error: 'Test error' });
  });

  app.get('/not-found', (req, res) => {
    res.status(404).json({ error: 'Not found' });
  });

  try {
    const serverInfo = await app.startServer(3001);
    console.log(`\n测试服务器启动: http://${serverInfo.address}:${serverInfo.port}`);
    console.log('测试URL:');
    console.log('- GET  http://localhost:3001/');
    console.log('- GET  http://localhost:3001/users/123');
    console.log('- POST http://localhost:3001/api/data');
    console.log('- GET  http://localhost:3001/error');
    console.log('- GET  http://localhost:3001/not-found');
    
    return app;
  } catch (error) {
    console.error('服务器启动失败:', error);
    throw error;
  }
}

/**
 * 测试不同日志格式
 */
export async function testDifferentFormats() {
  console.log('\n=== 测试不同日志格式 ===');
  
  const formats = [
    { name: 'TINY', logger: Logger.tiny() },
    { name: 'SHORT', logger: Logger.short() },
    { name: 'COMMON', logger: Logger.common() },
    { name: 'COMBINED', logger: Logger.combined() }
  ];

  const apps: WebServer[] = [];
  let port = 3010;

  for (const { name, logger } of formats) {
    console.log(`\n${name} 格式测试 (端口 ${port}):`);
    
    const app = new WebServer();
    app.use(logger);
    
    app.get('/', (req, res) => {
      res.json({ format: name, message: `${name} format test` });
    });

    try {
      await app.startServer(port);
      console.log(`${name} 服务器启动: http://localhost:${port}/`);
      apps.push(app);
      port++;
    } catch (error) {
      console.error(`${name} 服务器启动失败:`, error);
    }
  }

  return apps;
}

/**
 * 测试自定义日志配置
 */
export async function testCustomLogger() {
  console.log('\n=== 测试自定义日志配置 ===');
  
  const app = new WebServer();

  // 自定义格式
  app.use(Logger.create({
    format: ':method :url :status :response-time ms - :res[content-length] bytes',
    skip: (req, res) => {
      // 跳过健康检查
      return req.path === '/health';
    },
    stream: {
      write: (message) => {
        console.log(`[CUSTOM] ${message.trim()}`);
      }
    }
  }));

  app.get('/', (req, res) => {
    res.json({ message: 'Custom logger test' });
  });

  app.get('/health', (req, res) => {
    res.json({ status: 'ok' }); // 这个不会被记录
  });

  try {
    const serverInfo = await app.startServer(3020);
    console.log(`自定义日志服务器启动: http://${serverInfo.address}:${serverInfo.port}`);
    console.log('测试URL:');
    console.log('- GET http://localhost:3020/ (会记录日志)');
    console.log('- GET http://localhost:3020/health (不会记录日志)');
    
    return app;
  } catch (error) {
    console.error('自定义日志服务器启动失败:', error);
    throw error;
  }
}

// 如果直接运行此文件
if (require.main === module) {
  Promise.all([
    testCallbackLogger(),
    testDifferentFormats(),
    testCustomLogger()
  ]).then(() => {
    console.log('\n所有测试服务器启动完成！');
  }).catch(console.error);
}