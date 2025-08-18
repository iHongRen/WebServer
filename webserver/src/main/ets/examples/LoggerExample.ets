/**
 * @fileName : LoggerExample.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : 日志中间件使用示例
 */

import { WebServer } from '../WebServer';
import { Logger, LogFormat } from '../middleware';
import { HttpRequest } from '../HttpRequest';
import { HttpResponse } from '../HttpResponse';

/**
 * 日志中间件使用示例
 */
export function setupLoggerExamples() {
  const app = new WebServer();

  // 示例1: 使用默认开发环境日志格式
  console.log('=== 示例1: 默认开发环境日志 ===');
  const app1 = new WebServer();
  app1.logger(); // 等同于 app1.use(Logger.dev())
  
  app1.get('/dev-log', (req: HttpRequest, res: HttpResponse) => {
    res.json({ message: '开发环境日志示例', timestamp: Date.now() });
  });

  // 示例2: 使用不同的预定义格式
  console.log('=== 示例2: 不同的日志格式 ===');
  const app2 = new WebServer();
  
  // Combined格式（生产环境推荐）
  app2.use(Logger.combined());
  
  app2.get('/combined-log', (req: HttpRequest, res: HttpResponse) => {
    res.json({ message: 'Combined格式日志示例' });
  });

  // 示例3: 自定义日志格式
  console.log('=== 示例3: 自定义日志格式 ===');
  const app3 = new WebServer();
  
  app3.use(Logger.create({
    format: ':method :url :status :response-time ms - :res[content-length]'
  }));
  
  app3.get('/custom-log', (req: HttpRequest, res: HttpResponse) => {
    res.json({ message: '自定义格式日志示例' });
  });

  // 示例4: 条件性日志记录
  console.log('=== 示例4: 条件性日志记录 ===');
  const app4 = new WebServer();
  
  app4.use(Logger.create({
    format: LogFormat.DEV,
    skip: (req: HttpRequest, res: HttpResponse) => {
      // 跳过静态资源请求的日志
      return req.path.includes('/static/') || req.path.endsWith('.css') || req.path.endsWith('.js');
    }
  }));
  
  app4.get('/skip-test', (req: HttpRequest, res: HttpResponse) => {
    res.json({ message: '这个请求会被记录' });
  });
  
  app4.get('/static/style.css', (req: HttpRequest, res: HttpResponse) => {
    res.send('/* CSS content */');
  });

  // 示例5: 自定义输出流
  console.log('=== 示例5: 自定义输出流 ===');
  const app5 = new WebServer();
  
  // 创建自定义日志输出
  const customStream = {
    write: (message: string) => {
      // 可以写入文件、发送到远程日志服务等
      console.log(`[CUSTOM LOG] ${message.trim()}`);
    }
  };
  
  app5.use(Logger.create({
    format: LogFormat.COMBINED,
    stream: customStream
  }));
  
  app5.get('/custom-stream', (req: HttpRequest, res: HttpResponse) => {
    res.json({ message: '自定义输出流示例' });
  });

  // 示例6: 多种格式组合使用
  console.log('=== 示例6: 多种格式组合 ===');
  const app6 = new WebServer();
  
  // 开发环境：详细日志
  if (process.env.NODE_ENV === 'development') {
    app6.use(Logger.dev());
  } else {
    // 生产环境：标准日志
    app6.use(Logger.combined());
  }
  
  app6.get('/env-log', (req: HttpRequest, res: HttpResponse) => {
    res.json({ 
      message: '环境相关日志示例',
      env: process.env.NODE_ENV || 'development'
    });
  });

  // 示例7: 错误请求日志
  console.log('=== 示例7: 错误请求日志 ===');
  const app7 = new WebServer();
  
  app7.use(Logger.create({
    format: ':method :url :status :response-time ms - :res[content-length]'
  }));
  
  app7.get('/error-test', (req: HttpRequest, res: HttpResponse) => {
    res.status(500).json({ error: '服务器内部错误' });
  });
  
  app7.get('/not-found-test', (req: HttpRequest, res: HttpResponse) => {
    res.status(404).json({ error: '页面未找到' });
  });

  return {
    app1, app2, app3, app4, app5, app6, app7
  };
}

/**
 * 日志格式对比示例
 */
export function logFormatComparison() {
  console.log('=== 日志格式对比 ===');
  
  const formats = [
    { name: 'DEV', format: LogFormat.DEV },
    { name: 'TINY', format: LogFormat.TINY },
    { name: 'SHORT', format: LogFormat.SHORT },
    { name: 'COMMON', format: LogFormat.COMMON },
    { name: 'COMBINED', format: LogFormat.COMBINED }
  ];

  formats.forEach(({ name, format }) => {
    console.log(`\n${name} 格式示例:`);
    const app = new WebServer();
    app.use(Logger.create({ format }));
    
    app.get(`/${name.toLowerCase()}-format`, (req: HttpRequest, res: HttpResponse) => {
      res.json({ format: name, message: `${name}格式日志示例` });
    });
  });
}

/**
 * 性能测试示例
 */
export function performanceTest() {
  console.log('=== 性能测试 ===');
  
  const app = new WebServer();
  
  // 使用最简格式以减少日志开销
  app.use(Logger.tiny());
  
  app.get('/performance-test', (req: HttpRequest, res: HttpResponse) => {
    // 模拟一些处理时间
    setTimeout(() => {
      res.json({ 
        message: '性能测试',
        timestamp: Date.now(),
        data: new Array(100).fill('test data')
      });
    }, Math.random() * 100);
  });
  
  return app;
}