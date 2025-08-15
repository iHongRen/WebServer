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

// 定义核心函数类型
export type NextFunction = (error?: Error) => void;

export type RequestHandler = (req: HttpRequest, res: HttpResponse, next: NextFunction) => void;

export type ErrorHandler = (error: Error, req: HttpRequest, res: HttpResponse, next: NextFunction) => void;

interface Route {
  method: string;
  path: string;
  handler: RequestHandler | ErrorHandler;
  isErrorHandler: boolean;
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
    this.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      if (!res.isHeadersSent()) { // 检查头部是否已发送，避免重复响应
        res.status(404).json({ error: 'Not Found', path: req.path });
      }
    });
  }

  // 注册中间件或错误处理中间件
  public use(handler: RequestHandler | ErrorHandler): void {
    const isErrorHandler = handler.length === 4;
    this.addRoute('ANY', '*', handler, false, isErrorHandler);
  }

  public get(path: string, handler: RequestHandler) {
    this.addRoute('GET', path, handler, false, false);
  }

  public post(path: string, handler: RequestHandler) {
    this.addRoute('POST', path, handler, false, false);
  }

  /**
   * 内置的JSON请求体解析中间件
   */
  public json() {
    const jsonParser: RequestHandler = (req, res, next) => {
      const contentType = req.headers.get('content-type');
      if (contentType && contentType.includes('application/json') && req.body) {
        try {
          const bodyStr = Utils.arrayBufferToStr(req.body);
          req.body = JSON.parse(bodyStr);
        } catch (error) {
          // 将解析错误传递给错误处理链
          return next(error);
        }
      }
      next();
    };
    this.use(jsonParser);
  }

  /**
   * CORS (Cross-Origin Resource Sharing) 中间件
   */
  public cors(options?: Cors) {
    const corsMiddleware: RequestHandler = (req, res, next) => {
      const requestOrigin = req.headers.get('origin');
      if (!requestOrigin) {
        return next();
      }
      const configuredOrigin = options?.origin || '*';
      let allowedOrigin: string | null = null;

      if (typeof configuredOrigin === 'string') {
        allowedOrigin = configuredOrigin;
      } else if (Array.isArray(configuredOrigin)) {
        if (configuredOrigin.includes(requestOrigin)) {
          allowedOrigin = requestOrigin;
        }
      }

      if (allowedOrigin) {
        res.setHeader('Access-Control-Allow-Origin', allowedOrigin);
        res.setHeader('Vary', 'Origin');
      }
      res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

      if (req.method === 'OPTIONS') {
        res.status(204).send();
        return;
      }
      next();
    };
    this.use(corsMiddleware);
  }

  // 静态文件服务中间件
  public serveStatic(directoryPath: string) {
    const staticFileHandler: RequestHandler = async (req, res, next) => {
      if (req.method !== 'GET') {
        return next();
      }
      const decodedPath = decodeURIComponent(req.path);
      const requestedPath = Utils.normalizePath(decodedPath);
      if (requestedPath.includes('..')) {
        return res.status(400).send('Invalid Path');
      }
      let fullPath = directoryPath + (requestedPath === '/' ? '/index.html' : requestedPath);

      try {
        const stat = await fileIo.stat(fullPath);
        if (stat.isDirectory()) {
          fullPath = Utils.joinPath(fullPath, 'index.html');
          await fileIo.stat(fullPath);
        }
        const mimeType = Utils.getMimeType(fullPath);
        res.setHeader('Content-Type', mimeType);
        const buf = new ArrayBuffer(stat.size);
        const file = fileIo.openSync(fullPath, fileIo.OpenMode.READ_WRITE);
        fileIo.readSync(file.fd, buf);
        fileIo.closeSync(file.fd);
        res.send(buf);
      } catch (e) {
        next();
      }
    };
    this.addRoute('GET', '*', staticFileHandler, true, false);
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
      this.tcpServer = null;
      console.log('服务器已停止');
    }
  }

  private addRoute(method: string, path: string, handler: RequestHandler | ErrorHandler, isStatic: boolean = false,
    isErrorHandler: boolean = false) {
    const route: Route = {
      method,
      path,
      handler,
      isErrorHandler
    };
    const insertIndex = this.routes.length > 0 ? this.routes.length - 1 : 0;
    if (isStatic) {
      const firstWildcardIndex = this.routes.findIndex(r => r.path === '*');
      this.routes.splice(firstWildcardIndex, 0, route);
    } else {
      this.routes.splice(insertIndex, 0, route);
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

        const next: NextFunction = (err?: Error) => {
          routeIndex++;
          // 如果路由已处理完毕
          if (routeIndex >= this.routes.length) {
            if (err && !res.isHeadersSent()) {
              // 如果链条末端还有未处理的错误，发送500
              res.status(500).json({ error: 'Internal Server Error' });
            }
            return;
          }

          const route = this.routes[routeIndex];

          try {
            if (err) {
              // --- 错误处理模式 ---
              if (route.isErrorHandler) {
                (route.handler as ErrorHandler)(err, req, res, next);
              } else {
                // 非错误处理器，继续在错误模式下寻找下一个
                next(err);
              }
            } else {
              // --- 常规请求处理模式 ---
              if (!route.isErrorHandler) {
                if ((route.method === req.method || route.method === 'ANY') &&
                  (route.path === req.path || route.path === '*')) {
                  (route.handler as RequestHandler)(req, res, next);
                } else {
                  // 路由不匹配，继续寻找下一个
                  next();
                }
              } else {
                // 是错误处理器，在常规模式下跳过
                next();
              }
            }
          } catch (e) {
            // 捕获所有同步错误，并转入错误处理模式
            next(e);
          }
        };

        next(); // 启动路由处理链
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