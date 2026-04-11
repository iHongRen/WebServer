/**
 * @fileName : HttpServer.ets
 * @author : @cxy
 * @date : 2025/8/15
 * @description : Http服务器
 */

import { connection, socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Utils } from './Utils';
import { HttpRequest } from './HttpRequest';
import { HttpResponse } from './HttpResponse';
import { Router } from './Router';
import { LoggerOptions } from './middleware/logger';
import { deviceInfo } from '@kit.BasicServicesKit';
import { ConnectionPool, PoolConfig } from './ConnectionPool';
import { RequestParser } from './RequestParser';
import { ResponseCache, CacheConfig, CacheStats } from './ResponseCache';

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
import {
  ServerEventEmitter,
  ServerEvent,
  ServerErrorType,
  ServerEventType,
  ErrorEventListener,
  ServerEventListener
} from './ServerEvents';

/**
 * Http 服务器类
 * 提供HTTP服务器功能，支持路由、中间件等特性
 */
export class HttpServer {
  protected router: Router = new Router(); // 路由管理器
  protected configs: Map<string, Object> = new Map(); // 配置存储
  protected clients: Map<number, socket.TCPSocketConnection | socket.TLSSocketConnection> = new Map(); // 客户端连接映射
  protected tcpServer: socket.TCPSocketServer | null = null; // TCP服务器实例
  protected eventEmitter: ServerEventEmitter = new ServerEventEmitter(); // 事件发射器
  protected connectionPool: ConnectionPool; // 连接池
  protected responseCache: ResponseCache; // 响应缓存
  protected requestBuffers: Map<number, ArrayBuffer> = new Map(); // 请求缓冲区

  /**
   * 构造函数
   * 初始化服务器并设置默认404处理
   */
  constructor(poolConfig?: PoolConfig, cacheConfig?: CacheConfig) {
    this.connectionPool = new ConnectionPool(poolConfig);
    this.responseCache = new ResponseCache(cacheConfig);
    this.use404();
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
   *  默认404处理，需作为最后一个中间件
   */
  public use404() {
    this.use((req: HttpRequest, res: HttpResponse, _: NextFunction) => {
      if (!res.isHeadersSent()) {
        res.status(404).json({ error: 'Not Found', path: req.path });
      }
    });
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

  // ==================== 事件监听方法 ====================

  /**
   * 监听服务器错误事件
   * @param listener 错误事件监听器
   */
  public onError(listener: ErrorEventListener): void {
    this.eventEmitter.onError(listener);
  }

  /**
   * 监听服务器事件
   * @param eventType 事件类型
   * @param listener 事件监听器
   */
  public on(eventType: ServerEventType, listener: ServerEventListener): void {
    this.eventEmitter.on(eventType, listener);
  }

  /**
   * 移除错误监听器
   * @param listener 要移除的监听器
   */
  public removeErrorListener(listener: ErrorEventListener): void {
    this.eventEmitter.removeErrorListener(listener);
  }

  /**
   * 移除事件监听器
   * @param eventType 事件类型
   * @param listener 要移除的监听器
   */
  public removeListener(eventType: ServerEventType, listener: ServerEventListener): void {
    this.eventEmitter.removeListener(eventType, listener);
  }

  /**
   * 清除所有事件监听器
   */
  public removeAllListeners(): void {
    this.eventEmitter.removeAllListeners();
  }

  // ==================== 服务器状态查询方法 ====================

  /**
   * 获取服务器运行状态
   * @returns 运行状态
   */
  public async getState(): Promise<socket.SocketStateBase | undefined> {
    return await this.tcpServer?.getState()
  }

  /**
   * 获取当前连接的客户端数量
   * @returns 客户端数量
   */
  public getClientCount(): number {
    return this.connectionPool.size();
  }

  /**
   * 获取所有客户端信息
   * @returns 客户端信息数组
   */
  public getClients(): (socket.TCPSocketConnection | socket.TLSSocketConnection)[] {
    return this.connectionPool.getAll().map(info => info.socket);
  }

  /**
   * 根据ID获取客户端信息
   * @param clientId 客户端ID
   * @returns 客户端信息或undefined
   */
  public getClient(clientId: number): socket.TCPSocketConnection | socket.TLSSocketConnection | undefined {
    const info = this.connectionPool.get(clientId);
    return info?.socket;
  }

  /**
   * 断开指定客户端连接
   * @param clientId 客户端ID
   */
  public async disconnectClient(clientId: number): Promise<boolean> {
    const info = this.connectionPool.get(clientId);
    if (info) {
      try {
        await info.socket.close();
        this.connectionPool.remove(clientId);
        return true;
      } catch (error) {
        this.eventEmitter.emitError(error, ServerErrorType.CLIENT_ERROR);
        return false;
      }
    }
    return false;
  }

  /**
   * 获取缓存统计信息
   */
  public getCacheStats(): CacheStats {
    return this.responseCache.getStats();
  }

  /**
   * 清空响应缓存
   */
  public clearCache(): void {
    this.responseCache.clear();
  }

  /**
   * 启动服务器
   * @param port 监听端口
   * @param address 地址
   * @returns 服务器信息
   */
  public async startServer(port: number, address: string = ''): Promise<socket.NetAddress> {
    try {
      this.tcpServer = socket.constructTCPSocketServerInstance();
      try {
        // 尝试监听端口
        await this.tcpServer.listen({
          address: address || this.getLocalIP(),
          port: port
        });
      } catch (listenError) {
        this.eventEmitter.emitError(listenError, ServerErrorType.LISTEN_ERROR);
        return { address: '', port: 0 };
      }

      const info = await this.tcpServer.getLocalAddress()

      // 设置客户端连接监听
      this.tcpServer.on('connect', (clientSocket) => this.handleClient(clientSocket));
      // 设置服务器错误监听
      this.tcpServer.on('error', (error) => {
        this.eventEmitter.emitError(error, ServerErrorType.SOCKET_ERROR);
      });

      // 发射服务器启动事件
      const startEvent: ServerEvent = {
        type: ServerEventType.SERVER_STARTED,
        data: info
      };
      this.eventEmitter.emit(startEvent);
      return info
    } catch (error) {
      this.eventEmitter.emitError(new Error('服务器启动失败'), ServerErrorType.STARTUP_FAILED);
      return { address: '', port: 0 };
    }
  }

  /**
   * 停止服务器
   */
  public async stopServer(): Promise<void> {
    if (this.tcpServer) {
      try {
        // 清理连接池
        await this.connectionPool.destroy();
        
        this.clients.clear();
        this.requestBuffers.clear();
        this.tcpServer.off('connect');
        this.tcpServer.off('error');

        if (deviceInfo.sdkApiVersion >= 20) {
          await this.tcpServer.close()
        }
        this.tcpServer = null;
        this.eventEmitter.emit({ type: ServerEventType.SERVER_STOPPED });
      } catch (error) {
        this.tcpServer = null;
        this.eventEmitter.emitError(error, ServerErrorType.UNKNOWN_ERROR);
      }
    }
  }

  /**
   * 检查HTTP请求是否完整
   * @param buffer 缓冲区数据
   * @returns 是否为完整请求
   */
  protected isRequestComplete(buffer: ArrayBuffer): boolean {
    return RequestParser.isComplete(buffer);
  }

  /**
   * 移除客户端连接
   * @param clientSocket 客户端Socket连接
   * @param error 错误信息（可选）
   */
  protected removeClient(clientSocket: socket.TCPSocketConnection | socket.TLSSocketConnection, error?: BusinessError) {
    this.connectionPool.remove(clientSocket.clientId);
    this.clients.delete(clientSocket.clientId);
    this.requestBuffers.delete(clientSocket.clientId);
    
    if (error) {
      this.eventEmitter.emitError(error, ServerErrorType.CLIENT_ERROR);
    }
  }

  /**
   * 处理客户端连接
   * @param clientSocket 客户端Socket连接
   */
  protected handleClient(clientSocket: socket.TCPSocketConnection | socket.TLSSocketConnection) {
    // 检查连接池是否已满
    if (!this.connectionPool.add(clientSocket)) {
      console.warn('Connection pool full, rejecting connection');
      clientSocket.close();
      return;
    }

    this.clients.set(clientSocket.clientId, clientSocket);
    const clientId = clientSocket.clientId;

    clientSocket.on('message', async (data) => {
      try {
        // 更新连接活动时间
        this.connectionPool.updateActivity(clientId);

        // 获取或创建缓冲区
        let buffer = this.requestBuffers.get(clientId) || new ArrayBuffer(0);
        
        // 将新数据追加到缓冲区
        buffer = Utils.mergeArrayBuffers(buffer, data.message);
        this.requestBuffers.set(clientId, buffer);

        // 检查是否有完整的HTTP请求
        if (this.isRequestComplete(buffer)) {
          // 处理请求
          data.message = buffer;

          // 发射请求接收事件
          this.eventEmitter.emit({
            type: ServerEventType.REQUEST_RECEIVED,
            data: { clientSocket, data }
          });

          // 异步处理请求，避免阻塞
          this.processRequest(clientSocket, data).catch((error: Error) => {
            this.eventEmitter.emitError(error, ServerErrorType.CLIENT_ERROR);
          });

          // 清空缓冲区
          this.requestBuffers.delete(clientId);
        }
      } catch (error) {
        this.eventEmitter.emitError(error, ServerErrorType.CLIENT_ERROR);
        this.requestBuffers.delete(clientId);
      }
    });

    clientSocket.on('error', (err) => this.removeClient(clientSocket, err));
    clientSocket.on('close', () => this.removeClient(clientSocket));
  }

  /**
   * 异步处理单个请求
   */
  private async processRequest(
    clientSocket: socket.TCPSocketConnection | socket.TLSSocketConnection,
    data: socket.SocketMessageInfo
  ): Promise<void> {
    const req = new HttpRequest(data);
    const res = new HttpResponse(clientSocket);

    // 添加响应完成回调
    res.onFinish((statusCode, responseSize) => {
      this.eventEmitter.emit({
        type: ServerEventType.RESPONSE_SENT,
        data: { clientSocket, statusCode, responseSize }
      });
    });

    // 执行路由处理
    this.router.handle(req, res);
  }

  /**
   * 获取本地IP地址
   * @returns IP地址字符串
   */
  protected getLocalIP(): string {
    const localIP = '127-0-0-1'.replaceAll('-', '.')
    // 模拟器直接返回固定的
    if (deviceInfo.productModel === 'emulator') {
      return localIP;
    }

    try {
      const netHandle = connection.getDefaultNetSync();
      if (netHandle.netId === 0) {
        // 当前没有已连接的网络时，获取的netHandler的netid为0
        return localIP;
      }
      const connectionproperties = connection.getConnectionPropertiesSync(netHandle);
      return connectionproperties.linkAddresses[0].address.address;
    } catch (e) {
      return localIP;
    }
  }
}