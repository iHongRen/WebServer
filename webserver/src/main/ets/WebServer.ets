/**
 * @fileName : WebServer.ets
 * @author : @cxy
 * @date : 2025/8/15
 * @description : web 服务器
 */

import { wifiManager } from '@kit.ConnectivityKit';
import { ServerInfo } from './ServerInfo';
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Utils } from './Utils';
import { HttpRequest } from './HttpRequest';
import { HttpResponse } from './HttpResponse';
import { fileIo } from '@kit.CoreFileKit';

// 更新请求处理函数类型以支持 next 回调
export type RequestHandler = (req: HttpRequest, res: HttpResponse, next: () => void) => void;

interface Route {
  method: string;
  path: string;
  handler: RequestHandler;
}

interface Cors {
  origin?: string | string[]
}


export class WebServer {
  private tcpServer: socket.TCPSocketServer | null = null;
  private clients: socket.TCPSocketConnection[] = [];
  private routes: Route[] = [];

  constructor() {
    // 默认404处理，作为最后一个中间件
    this.use((req, res, next) => {
      if (!res.isHeadersSent()) { // 检查头部是否已发送，避免重复响应
        res.status(404).json({ error: 'Not Found', path: req.path });
      }
    });
  }

  // 注册中间件
  public use(handler: RequestHandler) {
    this.addRoute('ANY', '*', handler);
  }

  public get(path: string, handler: RequestHandler) {
    this.addRoute('GET', path, handler);
  }

  public post(path: string, handler: RequestHandler) {
    this.addRoute('POST', path, handler);
  }

  /**
   * 内置的JSON请求体解析中间件
   * @description
   * 解析 content-type 为 'application/json' 的请求体,
   * 并将解析后的JS对象赋值给 req.body。
   * 如果解析失败，会自动响应400错误。
   *
   * @example
   * server.json(); // 在定义路由前调用
   * server.post('/api/data', (req, res) => {
   *   console.log(req.body); // 已经是一个JS对象
   *   res.json({ received: true });
   * });
   */
  public json() {
    const jsonParser: RequestHandler = (req, res, next) => {
      const contentType = req.headers.get('content-type');
      // 检查 content-type 是否为 application/json 并且请求体存在
      if (contentType && contentType.includes('application/json') && req.body) {
        try {
          // 此刻 req.body 是一个 ArrayBuffer，我们将其解析
          const bodyStr = Utils.arrayBufferToStr(req.body);
          // 然后用解析后的对象替换 req.body
          req.body = JSON.parse(bodyStr);
        } catch (error) {
          // 如果JSON格式错误，发送400错误并停止处理
          console.error('Failed to parse JSON body:', error);
          res.status(400).json({ error: 'Bad Request', message: 'Invalid JSON format.' });
          // 请求已处理（虽然是错误处理），所以不调用 next()
          return;
        }
      }
      // 如果不是JSON请求或没有请求体，直接进入下一个处理器
      next();
    };
    this.use(jsonParser);
  }

  /**
   * CORS (Cross-Origin Resource Sharing) 中间件
   * @description
   * 为服务器启用CORS支持，可以灵活配置。
   *
   * @param {object} [options] - CORS 配置选项
   * @param {string|string[]} [options.origin='*'] - 配置允许的来源。可以是'*', 单个域名, 或一个域名数组。
   * @example
   * // 允许所有来源
   * server.cors();
   *
   * // 只允许特定来源
   * server.cors({ origin: 'https://my-app.com' });
   *
   * // 支持多个来源
   * server.cors({ origin: ['https://app1.com', 'https://app2.com'] });
   */
  public cors(options?: Cors) {
    const corsMiddleware: RequestHandler = (req, res, next) => {
      const requestOrigin = req.headers.get('origin');
      // 如果请求没有Origin头，则不是一个CORS请求，直接跳过
      if (!requestOrigin) {
        return next();
      }

      const configuredOrigin = options?.origin || '*';
      let allowedOrigin: string | null = null;

      // 检查配置的origin类型
      if (typeof configuredOrigin === 'string') {
        allowedOrigin = configuredOrigin; // e.g., '*' or 'https://my-app.com'
      } else if (Array.isArray(configuredOrigin)) {
        // 如果是数组，检查请求的origin是否在白名单内
        if (configuredOrigin.includes(requestOrigin)) {
          allowedOrigin = requestOrigin; // 动态反射请求的origin
        }
      }

      // 如果origin有效，则设置CORS头
      if (allowedOrigin) {
        res.setHeader('Access-Control-Allow-Origin', allowedOrigin);
        // 当动态设置ACAO时，建议添加Vary头
        res.setHeader('Vary', 'Origin');
      }

      res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

      // 专门处理 "预检" 请求 (preflight request)
      if (req.method === 'OPTIONS') {
        res.status(204).send(); // 204 No Content
        return; // 终止请求链
      }

      next();
    };
    this.use(corsMiddleware);
  }

  // 静态文件服务中间件
  public serveStatic(directoryPath: string) {
    const staticFileHandler: RequestHandler = async (req, res, next) => {
      if (req.method !== 'GET') {
        return next(); // 非GET请求，交给下一个处理器
      }

      // 解码URL路径中的特殊字符（如 %20 -> ' '）
      const decodedPath = decodeURIComponent(req.path);

      // 安全性：规范化路径并防止目录遍历
      const requestedPath = Utils.normalizePath(decodedPath);
      if (requestedPath.includes('..')) {
        return res.status(400).send('Invalid Path');
      }

      let fullPath = directoryPath + (requestedPath === '/' ? '/index.html' : requestedPath);

      try {
        const stat = await fileIo.stat(fullPath);
        if (stat.isDirectory()) {
          // 如果路径是目录，尝试服务该目录下的 index.html
          fullPath = Utils.joinPath(fullPath, 'index.html');
          await fileIo.stat(fullPath); // 检查 index.html 是否存在
        }

        const mimeType = Utils.getMimeType(fullPath);
        res.setHeader('Content-Type', mimeType);


        const buf = new ArrayBuffer(stat.size)
        const file = fileIo.openSync(fullPath, fileIo.OpenMode.READ_WRITE)
        fileIo.readSync(file.fd, buf)
        fileIo.closeSync(file.fd); // 关闭文件描述符，避免资源泄漏
        res.send(buf);

      } catch (e) {
        // 文件不存在或读取错误，交给下一个处理器
        next();
      }
    };
    // 静态文件处理器应有较高优先级，但需放在精确API路由之后，此处简化处理，放在前面
    this.addRoute('GET', '*', staticFileHandler, true);
  }

  public async startServer(port: number): Promise<ServerInfo> {
    try {
      this.tcpServer = socket.constructTCPSocketServerInstance();
      this.tcpServer.on('connect', (clientSocket) => this.handleClient(clientSocket));
      this.tcpServer.on('error', (error) => console.error('服务器错误:', error));
      await this.tcpServer.listen({ address: '0.0.0.0', port: port });
      const ip = this.getLocalIP();
      console.log(`Server running at http://${ip}:${port}/`);
      return { address: ip, port: port };
    } catch (error) {
      console.error('服务器启动失败:', error);
      return { address: '', port: 0 };
    }
  }

  public async stopServer(): Promise<void> {
    if (this.tcpServer) {
      for (const client of this.clients) {
        await client.close();
      }
      this.clients = [];
      // await this.tcpServer.close();
      this.tcpServer = null;
      console.log('服务器已停止');
    }
  }

  private addRoute(method: string, path: string, handler: RequestHandler, isStatic: boolean = false) {
    const route: Route = { method, path, handler };
    if (isStatic) {
      // 静态处理器插入到API路由之前，但在更精确的API路由之后
      // 一个简单的策略是找到第一个通用路由（'*')然后插入它之前
      const firstWildcardIndex = this.routes.findIndex(r => r.path === '*');
      this.routes.splice(firstWildcardIndex, 0, route);
    } else {
      // API路由插入到所有中间件和静态处理器之后，但在404处理器之前
      this.routes.splice(this.routes.length - 1, 0, route);
    }
  }

  private handleClient(clientSocket: socket.TCPSocketConnection) {
    let receivedData = new ArrayBuffer(0);
    clientSocket.on('message', async (data) => {
      receivedData = Utils.mergeArrayBuffers(receivedData, data.message);
      const requestStr = Utils.arrayBufferToStr(receivedData);
      if (requestStr.includes('\r\n\r\n')) {
        const req = new HttpRequest(receivedData);
        const res = new HttpResponse(clientSocket);

        let routeIndex = -1;
        const next = () => {
          routeIndex++;
          const route = this.routes[routeIndex];
          if (route) {
            // 检查路由是否匹配
            if ((route.method === req.method || route.method === 'ANY') &&
              (route.path === req.path || route.path === '*')) {
              route.handler(req, res, next);
            } else {
              next(); // 不匹配，检查下一个路由
            }
          }
        };

        next(); // 开始处理路由链
        receivedData = new ArrayBuffer(0);
      }
    });
    clientSocket.on('error', (err) => this.removeClient(clientSocket, err));
    clientSocket.on('close', () => this.removeClient(clientSocket));
  }

  private removeClient(clientSocket: socket.TCPSocketConnection, error?: BusinessError) {
    if (error) {
      console.error('客户端连接错误:', error);
    }
    const index = this.clients.indexOf(clientSocket);
    if (index > -1) {
      this.clients.splice(index, 1);
    }
  }

  private getLocalIP(): string {
    try {
      const ipAddress = wifiManager.getIpInfo().ipAddress;
      return (ipAddress >>> 24) + "." + (ipAddress >> 16 & 0xFF) + "." + (ipAddress >> 8 & 0xFF) + "." +
        (ipAddress & 0xFF);
    } catch (e) {
      console.error("Get local IP failed", e);
      return '127.0.0.1';
    }
  }
}
