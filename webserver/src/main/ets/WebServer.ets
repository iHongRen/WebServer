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
  path: string; // The original path string, e.g., /users/:id
  handler: RequestHandler | ErrorHandler;
  pathRegex: RegExp | null; // Regex for path matching
  paramNames: string[]; // Names of the params, e.g., ['id']
}

interface CorsOptions {
  origin?: string | string[]
}

interface CacheOptions {
  maxAge?: number
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
    this.addRoute('ANY', '*', handler, false);
  }

  public get(path: string, handler: RequestHandler) {
    this.addRoute('GET', path, handler, false);
  }

  public post(path: string, handler: RequestHandler) {
    this.addRoute('POST', path, handler, false);
  }

  public json() {
    this.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      req.parseBody();
      next();
    });
  }

  public urlencoded() {
    this.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      req.parseBody();
      next();
    });
  }

  public multipart() {
    this.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      req.parseBody();
      next();
    });
  }

  public cors(options?: CorsOptions) {
    this.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
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
    });
  }

  public serveStatic(directoryPath: string, options?: CacheOptions) {
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
        let stat = await fileIo.stat(fullPath);
        if (stat.isDirectory()) {
          fullPath = Utils.joinPath(fullPath, 'index.html');
          stat = await fileIo.stat(fullPath); // Get stats for index.html
        }

        // --- Caching Logic ---
        const maxAge = options?.maxAge ?? 3600; // Default to 1 hour
        // Generate a weak ETag based on file size and modification time
        const etag = `W/"${stat.size}-${stat.mtime}"`;

        // Check if the client's cached version is still fresh
        const ifNoneMatch = req.headers.get('if-none-match');
        if (ifNoneMatch === etag) {
          return res.status(304).send(); // Not Modified
        }
        // --- End Caching Logic ---

        // Set caching headers for the new response
        res.setHeader('Cache-Control', `public, max-age=${maxAge}`);
        res.setHeader('ETag', etag);

        const mimeType = Utils.getMimeType(fullPath);
        res.setHeader('Content-Type', mimeType);
        const buf = new ArrayBuffer(stat.size);
        const file = fileIo.openSync(fullPath, fileIo.OpenMode.READ_WRITE);
        fileIo.readSync(file.fd, buf);
        fileIo.closeSync(file.fd);
        res.send(buf);
      } catch (e) {
        // If file doesn't exist or other error, pass to the next handler (e.g., 404)
        next();
      }
    };
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
      this.tcpServer = null;
      console.log('服务器已停止');
    }
  }

  private addRoute(method: string, path: string, handler: RequestHandler | ErrorHandler, isStatic: boolean = false) {
    let pathRegex: RegExp | null = null;
    const paramNames: string[] = [];

    if (path !== '*' && path.includes(':')) {
      const regexString = path.replace(/:(\w+)/g, (_, name: string) => {
        paramNames.push(name);
        return '([^/]+)';
      });
      pathRegex = new RegExp(`^${regexString}/?$`);
    }

    const route: Route = {
      method,
      path,
      handler,
      pathRegex,
      paramNames
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
    clientSocket.on('message', async (data) => {
      const req = new HttpRequest(data.message);
      const res = new HttpResponse(clientSocket);
      let routeIndex = -1;

      const next: NextFunction = (err?: Error) => {
        routeIndex++;
        if (routeIndex >= this.routes.length) {
          if (err && !res.isHeadersSent()) {
            res.status(500).json({ error: 'Internal Server Error' });
          }
          return;
        }

        const route = this.routes[routeIndex];

        try {
          if (err) {
            if (route.handler.length === 4) {
              (route.handler as ErrorHandler)(err, req, res, next);
            } else {
              next(err);
            }
          } else {
            if (route.handler.length !== 4) {
              let match: RegExpExecArray | null = null;
              const simpleMatch = (route.method === req.method || route.method === 'ANY') && (route.path === req.path || route.path === '*');
              const regexMatch = route.pathRegex && (match = route.pathRegex.exec(req.path));

              if ((route.method === req.method || route.method === 'ANY') && (simpleMatch || regexMatch)) {
                if (regexMatch && match) {
                  req.params = {}; // Clear old params
                  route.paramNames.forEach((name, index) => {
                    if (match) {
                      req.params[name] = match[index + 1];
                    }
                  });
                }
                (route.handler as RequestHandler)(req, res, next);
              } else {
                next();
              }
            } else {
              next();
            }
          }
        } catch (e) {
          next(e);
        }
      };

      next();
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