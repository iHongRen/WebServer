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
import { Router } from './Router';
import {
  NextFunction,
  RequestHandler,
  ErrorHandler,
  CorsOptions,
  CacheOptions,
  BodyParser,
  Cors,
  StaticFiles
} from './middleware';

export class WebServer {
  private tcpServer: socket.TCPSocketServer | null = null;
  private clients: socket.TCPSocketConnection[] = [];
  private router: Router = new Router();
  private configs: Map<string, Object> = new Map();

  constructor() {
    // 默认404处理，作为最后一个中间件
    this.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      if (!res.isHeadersSent()) {
        res.status(404).json({ error: 'Not Found', path: req.path });
      }
    });
  }

  public setConfig(key: string, value: Object) {
    this.configs.set(key, value);
  }

  public getConfig(key: string): Object | undefined {
    return this.configs.get(key);
  }

  // 注册中间件或错误处理中间件
  public use(handler: RequestHandler | ErrorHandler) {
    this.router.addRoute('ANY', '*', handler);
  }

  public get(path: string, handler: RequestHandler) {
    this.router.addRoute('GET', path, handler);
  }

  public post(path: string, handler: RequestHandler) {
    this.router.addRoute('POST', path, handler);
  }

  public json() {
    this.use(BodyParser.json());
  }

  public urlencoded() {
    this.use(BodyParser.urlencoded());
  }

  public multipart() {
    this.use(BodyParser.multipart());
  }

  public serveStatic(directoryPath: string, options?: CacheOptions) {
    this.router.addRoute('GET', '*', StaticFiles.serve(directoryPath, options));
  }

  public cors(options?: CorsOptions) {
    this.use(Cors.create(options));
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

  private handleClient(clientSocket: socket.TCPSocketConnection) {
    let buffer = new ArrayBuffer(0);

    clientSocket.on('message', async (data) => {
      // 将新数据追加到缓冲区
      buffer = Utils.mergeArrayBuffers(buffer, data.message);

      // 检查是否有完整的HTTP请求
      const completeRequest = this.isRequestComplete(buffer);
      if (completeRequest) {
        // 处理请求
        const req = new HttpRequest(this, buffer);
        const res = new HttpResponse(clientSocket);
        this.router.handle(req, res)

        // 清空缓冲区
        buffer = new ArrayBuffer(0);
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

  private isRequestComplete(buffer: ArrayBuffer): boolean {
    const bufferStr = Utils.arrayBufferToStr(buffer);
    const headerEndIndex = bufferStr.indexOf('\r\n\r\n');

    if (headerEndIndex === -1) {
      return false; // 头部不完整
    }

    // 解析Content-Length
    const headerStr = bufferStr.substring(0, headerEndIndex);
    const contentLengthMatch = headerStr.match(/Content-Length:\s*(\d+)/i);
    const contentLength = contentLengthMatch ? parseInt(contentLengthMatch[1]) : 0;

    // 计算完整请求的总长度
    const headerLength = headerEndIndex + 4; // 包括 \r\n\r\n
    const totalRequestLength = headerLength + contentLength;

    return buffer.byteLength >= totalRequestLength;
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