/**
 * @fileName : RouterExample.ets
 * @author : @cxy
 * @date : 2025/8/20
 * @description : 路由使用示例
 */
import { WebServer } from "@cxy/webserver";

/**
 * 路由使用示例
 */
export class RouterExample {
  // 示例1: 基本路由
  static example1() {
    console.log('=== 示例1: 基本路由 ===');
    const server = new WebServer();

    server.get('/', (req, res) => {
      res.status(200).send('Hello World!');
    });

    server.post('/users', (req, res) => {
      res.status(200).json({ message: 'User created' });
    });

    server.put('/users/:id', (req, res) => {
      res.status(200).json({ message: `User ${req.params.id} updated` });
    });

    server.delete('/users/:id', (req, res) => {
      res.status(200).json({ message: `User ${req.params.id} deleted` });
    });

    server.startServer(8080)
  }
}
