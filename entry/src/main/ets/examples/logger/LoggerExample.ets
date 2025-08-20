/**
 * @fileName : LoggerExample.ets
 * @author : @cxy
 * @date : 2025/8/18
 * @description : 日志中间件使用示例
 */
import { LogFormat, Logger, WebServer } from "@cxy/webserver";

interface LogFormatItem {
  name: string,
  format: LogFormat
}

/**
 * 日志中间件使用示例
 */
export class LoggerExample {
  // 示例1: 使用默认开发环境日志格式
  static example1() {
    console.log('=== 示例1: 默认开发环境日志 ===');
    const server = new WebServer();
    server.logger(); // 等同于 app1.use(Logger.dev())

    server.get('/dev-log', (req, res) => {
      res.json({ message: '开发环境日志示例', timestamp: Date.now() });
    });

    server.startServer(8080)
  }


  // 示例2: 使用不同的预定义格式
  static example2() {
    console.log('=== 示例2: 不同的日志格式 ===');
    // Combined格式（生产环境推荐）
    const server = new WebServer();
    server.use(Logger.combined());

    server.get('/combined-log', (req, res) => {
      res.json({ message: 'Combined格式日志示例' });
    });

    server.startServer(8080)
  }

  // 示例3: 自定义日志格式
  static example3() {
    console.log('=== 示例3: 自定义日志格式 ===');
    const server = new WebServer();
    server.use(Logger.create({
      format: ':method :url :status :response-time ms - :content-length'
    }));

    server.get('/custom-log', (req, res) => {
      res.json({ message: '自定义格式日志示例' });
    });

    server.startServer(8080)
  }

  // 示例4: 条件性日志记录
  static example4() {
    console.log('=== 示例4: 条件性日志记录 ===');
    const server = new WebServer();
    server.use(Logger.create({
      format: LogFormat.DEV,
      skip: (req, res) => {
        // 跳过静态资源请求的日志
        return req.path.includes('/static/') || req.path.endsWith('.css') || req.path.endsWith('.js');
      }
    }));

    server.get('/skip-test', (req, res) => {
      res.json({ message: '这个请求会被记录' });
    });

    server.get('/static/style.css', (req, res) => {
      res.send('/* CSS content */');
    });

    server.startServer(8080)
  }

  // 示例5: 自定义输出流
  static example5() {
    console.log('=== 示例5: 自定义输出流 ===');
    const server = new WebServer();
    // 创建自定义日志输出
    const customStream = (message: string) => {
      // 可以写入文件、发送到远程日志服务等
      console.log(`[CUSTOM LOG] ${message.trim()}`);
    };

    server.use(Logger.create({
      format: LogFormat.COMBINED,
      stream: customStream
    }));

    server.get('/custom-stream', (req, res) => {
      res.json({ message: '自定义输出流示例' });
    });

    server.startServer(8080)
  }

  // 示例6: 多种格式组合使用
  static example6() {
    console.log('=== 示例6: 多种格式组合 ===');
    const server = new WebServer();
    // 开发环境：详细日志
    const isDev = true
    if (isDev) {
      server.use(Logger.dev());
    } else {
      // 生产环境：标准日志
      server.use(Logger.combined());
    }

    server.get('/env-log', (req, res) => {
      res.json({
        message: '环境相关日志示例',
        env: isDev ? 'dev' : 'prod'
      });
    });

    server.startServer(8080)
  }

  // 示例7: 错误请求日志
  static example7() {
    console.log('=== 示例7: 错误请求日志 ===');
    const server = new WebServer();
    server.use(Logger.create({
      format: ':method :url :status :response-time ms - :content-length'
    }));

    server.get('/error-test', (req, res) => {
      res.status(500).json({ error: '服务器内部错误' });
    });

    server.get('/not-found-test', (req, res) => {
      res.status(404).json({ error: '页面未找到' });
    });

    server.startServer(8080)
  }

  /**
   * 日志格式对比示例
   */
  static logFormatComparison() {
    console.log('=== 日志格式对比 ===');
    const formats: LogFormatItem[] = [
      { name: 'DEV', format: LogFormat.DEV },
      { name: 'TINY', format: LogFormat.TINY },
      { name: 'SHORT', format: LogFormat.SHORT },
      { name: 'COMMON', format: LogFormat.COMMON },
      { name: 'COMBINED', format: LogFormat.COMBINED }
    ];

    formats.forEach((item, index) => {
      const name = item.name
      console.log(`\n${name} 格式示例:`);
      const server = new WebServer();
      server.use(Logger.create({ format: item.format }));

      server.get(`/${name.toLowerCase()}-format`, (req, res) => {
        res.json({ format: name, message: `${name}格式日志示例` });
      });

      server.startServer(8080 + index)
    });
  }

  /**
   * 性能测试示例
   */
  static performanceTest() {
    console.log('=== 性能测试 ===');
    const server = new WebServer();
    // 使用最简格式以减少日志开销
    server.use(Logger.tiny());

    server.get('/performance-test', (req, res) => {
      // 模拟一些处理时间
      setTimeout(() => {
        res.json({
          message: '性能测试',
          timestamp: Date.now(),
          data: new Array(100).fill('test data')
        });
      }, Math.random() * 100);
    });

    server.startServer(8080)
  }
}


