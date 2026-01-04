/**
 * @fileName : TLSServer.ets
 * @author : @cxy
 * @date : 2025/10/24
 * @description : HTTPS 服务器实现
 */

import { socket } from '@kit.NetworkKit';
import { HttpServer } from './HttpServer';
import { deviceInfo } from '@kit.BasicServicesKit';
import { ServerErrorType, ServerEventType } from './ServerEvents';


/**
 * HTTPS服务器类
 * HttpServer，提供TLS加密的HTTP服务
 */
export class TLSServer extends HttpServer {
  private tlsServer: socket.TLSSocketServer | null = null;
  private tlsOptions: socket.TLSSecureOptions;

  /**
   * 构造函数
   * @param options TLS配置选项
   */
  constructor(options: socket.TLSSecureOptions) {
    super();
    this.tlsOptions = options;
  }

  /**
   * 启动服务器
   * @param port 监听端口
   * @param address 地址
   * @returns 服务器信息
   */
  public async startServer(port: number, address: string = ''): Promise<socket.NetAddress> {
    try {
      // 创建TLS服务器实例
      this.tlsServer = socket.constructTLSSocketServerInstance();

      // 配置TLS选项
      const tlsConnectOptions: socket.TLSConnectOptions = {
        address: {
          address: address || this.getLocalIP(),
          port: port
        },
        secureOptions: this.tlsOptions
      };

      // 启动监听
      await this.tlsServer.listen(tlsConnectOptions)
      // 设置事件监听
      this.tlsServer.on('connect', (clientSocket) => this.handleClient(clientSocket));
      // 设置服务器错误监听
      this.tlsServer.on('error', (error) => {
        this.eventEmitter.emitError(error, ServerErrorType.SOCKET_ERROR);
      });

      const info = await this.tlsServer.getLocalAddress()
      return info;
    } catch (error) {
      this.eventEmitter.emitError(new Error('服务器启动失败'), ServerErrorType.STARTUP_FAILED);
      return { address: '', port: 0 };
    }
  }

  /**
   * 停止HTTPS服务器
   */
  /**
   * 停止服务器
   */
  public async stopServer(): Promise<void> {
    if (this.tlsServer) {
      try {
        this.clients.forEach(async (client, _) => {
          client.close();
        })
        this.clients.clear();
        this.tlsServer.off('connect');
        this.tlsServer.off('error');

        if (deviceInfo.sdkApiVersion >= 20) {
          await this.tlsServer.close()
        }
        this.tlsServer = null;
        this.eventEmitter.emit({ type: ServerEventType.SERVER_STOPPED });
      } catch (error) {
        this.tlsServer = null;
        this.eventEmitter.emitError(error, ServerErrorType.UNKNOWN_ERROR);
      }
    }
  }

  /**
   * 获取服务器运行状态
   * @returns 运行状态
   */
  public async getState(): Promise<socket.SocketStateBase | undefined> {
    return await this.tlsServer?.getState()
  }
}