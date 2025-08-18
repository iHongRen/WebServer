/**
 * @fileName : SimpleLoggerTest.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : 简单的日志中间件测试
 */

import { WebServer } from '../WebServer';
import { Logger, LogFormat } from '../middleware';

/**
 * 简单的日志中间件测试
 */
export async function testLogger() {
  const app = new WebServer();

  // 启用开发环境日志
  app.logger();

  // 或者使用更详细的配置
  // app.use(Logger.create({
  //   format: LogFormat.COMBINED,
  //   skip: (req, res) => req.path.startsWith('/health')
  // }));

  // 测试路由
  app.get('/', (req, res) => {
    res.json({ message: 'Hello World!', timestamp: new Date().toISOString() });
  });

  app.get('/api/users/:id', (req, res) => {
    const userId = req.params.id;
    res.json({ 
      user: { id: userId, name: `User ${userId}` },
      timestamp: new Date().toISOString()
    });
  });

  app.post('/api/data', (req, res) => {
    res.status(201).json({ 
      message: 'Data created successfully',
      data: req.body,
      timestamp: new Date().toISOString()
    });
  });

  app.get('/error', (req, res) => {
    res.status(500).json({ error: 'Internal Server Error' });
  });

  // 启动服务器
  try {
    const serverInfo = await app.startServer(3000);
    console.log(`测试服务器启动成功: http://${serverInfo.address}:${serverInfo.port}`);
    console.log('访问以下URL来测试日志功能:');
    console.log('- GET  http://localhost:3000/');
    console.log('- GET  http://localhost:3000/api/users/123');
    console.log('- POST http://localhost:3000/api/data');
    console.log('- GET  http://localhost:3000/error');
    
    return app;
  } catch (error) {
    console.error('服务器启动失败:', error);
    throw error;
  }
}

// 如果直接运行此文件，则启动测试服务器
if (require.main === module) {
  testLogger().catch(console.error);
}