/**
 * @fileName : BodyParserExample.ets
 * @author : @cxy
 * @date : 2025/8/20
 * @description : Body-Parser中间件使用示例
 */
import { WebServer, BodyParser } from "@cxy/webserver";

/**
 * Body-Parser中间件使用示例
 */
export class BodyParserExample {
  // 示例1: 解析JSON格式的请求体
  static example1() {
    console.log('=== 示例1: 解析JSON请求体 ===');
    const server = new WebServer();
    server.use(BodyParser.json());

    server.post('/json-test', (req, res) => {
      res.json({
        message: '收到JSON数据',
        data: req.body
      });
    });

    server.startServer(8080)
  }

  // 示例2: 解析URL编码的请求体
  static example2() {
    console.log('=== 示例2: 解析URL编码请求体 ===');
    const server = new WebServer();
    server.use(BodyParser.urlencoded());

    server.post('/urlencoded-test', (req, res) => {
      res.json({
        message: '收到URL编码数据',
        data: req.body
      });
    });

    server.startServer(8080)
  }

  // 示例3: 解析文本格式的请求体
  static example3() {
    console.log('=== 示例3: 解析文本请求体 ===');
    const server = new WebServer();
    server.use(BodyParser.plain());

    server.post('/text-test', (req, res) => {
      res.send(`收到文本数据: ${req.body}`);
    });

    server.startServer(8080)
  }

  // 示例4: 解析文本格式的请求体
  static example4() {
    console.log('=== 示例3: 解析多部分表单请求体 ===');
    const server = new WebServer();
    server.use(BodyParser.multipart());

    server.post('/upload', (req, res) => {
      console.log(JSON.stringify(req.files))
      res.send(`收到数据: ${req.body}`);
    });

    server.startServer(8080)
  }

  // 示例5: 自动解析
  static example5() {
    console.log('=== 示例3: 解析文本请求体 ===');
    const server = new WebServer();
    server.use(BodyParser.auto());

    server.post('/auto-test', (req, res) => {
      res.send(`收到数据: ${req.body}`);
    });

    server.startServer(8080)
  }
}
