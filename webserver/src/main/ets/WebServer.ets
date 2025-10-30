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
  StaticFiles,
  Logger,
} from './middleware';
import { LoggerOptions } from './middleware/logger';

/**
 * Web服务器类
 * 提供HTTP服务器功能，支持路由、中间件等特性
 */
export class WebServer {
  protected router: Router = new Router(); // 路由管理器
  protected configs: Map<string, Object> = new Map(); // 配置存储
  private clients: socket.TCPSocketConnection[] = []; // 客户端连接列表
  private tcpServer: socket.TCPSocketServer | null = null; // TCP服务器实例

  /**
   * 构造函数
   * 初始化服务器并设置默认404处理
   */
  constructor() {
    // 默认404处理，作为最后一个中间件
    this.use((req: HttpRequest, res: HttpResponse, next: NextFunction) => {
      if (!res.isHeadersSent()) {
        res.status(404).json({ error: 'Not Found', path: req.path });
      }
    });
  }

  /**
   * 设置配置项
   * @param key 配置键
   * @param value 配置值
   */
  public setConfig(key: string, value: Object) {
    this.configs.set(key, value);
  }

  /**
   * 获取配置项
   * @param key 配置键
   * @returns 配置值
   */
  public getConfig(key: string): Object | undefined {
    return this.configs.get(key);
  }

  /**
   * 注册中间件或错误处理中间件
   * @param handler 处理函数
   */
  public use(handler: RequestHandler | ErrorHandler) {
    this.router.addRoute('ANY', '*', handler);
  }

  /**
   * 注册GET路由
   * @param path 路由路径
   * @param handler 处理函数
   */
  public get(path: string, handler: RequestHandler) {
    this.router.addRoute('GET', path, handler);
  }

  /**
   * 注册POST路由
   * @param path 路由路径
   * @param handler 处理函数
   */
  public post(path: string, handler: RequestHandler) {
    this.router.addRoute('POST', path, handler);
  }

  /**
   * 注册PUT路由
   * @param path 路由路径
   * @param handler 处理函数
   */
  public put(path: string, handler: RequestHandler) {
    this.router.addRoute('PUT', path, handler);
  }

  /**
   * 注册DELETE路由
   * @param path 路由路径
   * @param handler 处理函数
   */
  public delete(path: string, handler: RequestHandler) {
    this.router.addRoute('DELETE', path, handler);
  }

  /**
   * 启用自动请求体解析中间件
   */
  public auto() {
    this.use(BodyParser.auto());
  }

  /**
   * 启用JSON请求体解析中间件
   */
  public json() {
    this.use(BodyParser.json());
  }

  /**
   * 启用URL编码请求体解析中间件
   */
  public urlencoded() {
    this.use(BodyParser.urlencoded());
  }

  /**
   * 启用多部分表单解析中间件
   */
  public multipart() {
    this.use(BodyParser.multipart());
  }

  /**
   * 启用文本请求体解析中间件
   */
  public plain() {
    this.use(BodyParser.plain());
  }

  /**
   * 启用静态文件服务
   * @param directoryPath 静态文件目录路径
   * @param options 缓存选项
   */
  public serveStatic(directoryPath: string, options?: CacheOptions) {
    this.router.addRoute('GET', '*', StaticFiles.serve(directoryPath, options));
  }

  /**
   * 启用CORS跨域支持
   * @param options CORS配置选项
   */
  public cors(options?: CorsOptions) {
    this.use(Cors.create(options));
  }

  /**
   * 启用日志中间件（开发环境格式）
   */
  public logger(options?: LoggerOptions) {
    this.use(Logger.create(options));
  }

  /**
   * 启动服务器
   * @param port 监听端口
   * @returns 服务器信息
   */
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

  /**
   * 停止服务器
   */
  public async stopServer(): Promise<void> {
    if (this.tcpServer) {
      for (const client of this.clients) {
        await client.close();
      }
      this.clients = [];
      const state = await this.tcpServer.getState()
      if (state.isConnected) {
        this.tcpServer.off('connect')
      }
      this.tcpServer = null;
    }
  }

  /**
   * 获取本地IP地址
   * @returns IP地址字符串
   */
  protected getLocalIP(): string {
    try {
      const ipAddress = wifiManager.getIpInfo().ipAddress;
      return (ipAddress >>> 24) + "." + (ipAddress >> 16 & 0xFF) + "." + (ipAddress >> 8 & 0xFF) + "." +
        (ipAddress & 0xFF);
    } catch (e) {
      console.error("Get local IP failed", e);
      return '127.0.0.1';
    }
  }

  /**
   * 检查HTTP请求是否完整
   * @param buffer 缓冲区数据
   * @returns 是否为完整请求
   */
  protected isRequestComplete(buffer: ArrayBuffer): boolean {
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

  /**
   * 移除客户端连接
   * @param clientSocket 客户端Socket连接
   * @param error 错误信息（可选）
   */
  protected removeClient(clientSocket: socket.TCPSocketConnection, error?: BusinessError) {
    if (error) {
      console.error('客户端连接错误:', error);
    }
    const index = this.clients.indexOf(clientSocket);
    if (index > -1) {
      this.clients.splice(index, 1);
    }
  }

  /**
   * 处理客户端连接
   * @param clientSocket 客户端Socket连接
   */
  private handleClient(clientSocket: socket.TCPSocketConnection) {
    this.clients.push(clientSocket)
    let buffer = new ArrayBuffer(0);
    clientSocket.on('message', async (data) => {
      // 将新数据追加到缓冲区
      buffer = Utils.mergeArrayBuffers(buffer, data.message);

      // 检查是否有完整的HTTP请求
      const completeRequest = this.isRequestComplete(buffer);
      if (completeRequest) {
        // 处理请求
        const req = new HttpRequest(data);
        const res = new HttpResponse(clientSocket);
        this.router.handle(req, res);

        // 清空缓冲区
        buffer = new ArrayBuffer(0);
      }
    });

    clientSocket.on('error', (err) => this.removeClient(clientSocket, err));
    clientSocket.on('close', () => this.removeClient(clientSocket));
  }
}