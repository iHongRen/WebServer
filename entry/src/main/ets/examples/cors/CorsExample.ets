/**
 * @fileName : CorsExample.ets
 * @author : @cxy
 * @date : 2025/8/20
 * @description : CORS中间件使用示例
 */
import { HttpServer, Cors } from "@cxy/webserver";

/**
 * CORS中间件使用示例
 */
export class CorsExample {
  // 示例1: 启用所有来源的CORS
  static example1() {
    console.log('=== 示例1: 启用所有来源的CORS ===');
    const server = new HttpServer();
    server.use(Cors.create());

    server.get('/cors-all', (req, res) => {
      res.json({ message: '允许所有来源访问' });
    });

    server.startServer(8080)
  }

  // 示例2: 配置特定来源
  static example2() {
    console.log('=== 示例2: 配置特定来源 ===');
    const server = new HttpServer();
    server.use(Cors.create({
      origin: 'https://example.com'
    }));

    server.get('/cors-specific-origin', (req, res) => {
      res.json({ message: '只允许 https://example.com 访问' });
    });

    server.startServer(8080)
  }

  // 示例3: 配置多种来源
  static example3() {
    console.log('=== 示例3: 配置多种来源 ===');
    const server = new HttpServer();
    server.use(Cors.create({
      origin: ['https://example.com', 'https://another.com']
    }));

    server.get('/cors-multiple-origins', (req, res) => {
      res.json({ message: '允许多个特定来源访问' });
    });

    server.startServer(8080)
  }

  // 示例4: 配置允许的HTTP方法
  static example4() {
    console.log('=== 示例4: 配置允许的HTTP方法 ===');
    const server = new HttpServer();
    server.use(Cors.create({
      methods: ['GET', 'POST']
    }));

    server.put('/cors-methods', (req, res) => {
      res.json({ message: '此请求将被CORS策略阻止' });
    });

    server.startServer(8080)
  }

  // 示例5: 配置允许的HTTP头
  static example5() {
    console.log('=== 示例5: 配置允许的HTTP头 ===');
    const server = new HttpServer();
    server.use(Cors.create({
      allowedHeaders: ['Content-Type', 'Authorization']
    }));

    server.get('/cors-headers', (req, res) => {
      res.json({ message: '允许特定的HTTP头' });
    });

    server.startServer(8080)
  }
}
