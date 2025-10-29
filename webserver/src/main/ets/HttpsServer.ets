/**
 * @fileName : HttpsServer.ets
 * @author : @cxy
 * @date : 2025/10/24
 * @description : HTTPS 服务器实现
 */

import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { WebServer } from './WebServer';
import { ServerInfo } from './ServerInfo';
import { HttpRequest } from './HttpRequest';
import { HttpResponse } from './HttpResponse';
import { Utils } from './Utils';


/**
 * HTTPS服务器类
 * 继承WebServer，提供TLS加密的HTTP服务
 */
export class HttpsServer extends WebServer {
  private tlsClients: socket.TLSSocketConnection[] = []; // 客户端连接列表
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
   * 启动HTTPS服务器
   * @param port 监听端口
   * @returns 服务器信息
   */
  public async startServer(port: number): Promise<ServerInfo> {
    try {
      // 创建TLS服务器实例
      this.tlsServer = socket.constructTLSSocketServerInstance();

      // 配置TLS选项
      const tlsConnectOptions: socket.TLSConnectOptions = {
        address: {
          address: '0.0.0.0',
          port: port,
          family: 1
        },
        secureOptions: this.tlsOptions
      };

      // 设置事件监听
      this.tlsServer.on('connect', (clientSocket) => this.handleTLSClient(clientSocket));
      this.tlsServer.on('error', (error) => console.error('HTTPS服务器错误:', error));

      // 启动监听
      await this.tlsServer.listen(tlsConnectOptions)
      
      const ip = this.getLocalIP();
      console.log(`HTTPS Server running at https://${ip}:${port}/`);
      return { address: ip, port: port };
    } catch (error) {
      console.error('HTTPS服务器启动失败:', error);
      return { address: '', port: 0 };
    }
  }

  /**
   * 停止HTTPS服务器
   */
  public async stopServer(): Promise<void> {
    if (this.tlsServer) {
      // 关闭所有客户端连接
      for (const client of this.tlsClients) {
        await client.close();
      }
      this.tlsClients = [];
      this.tlsServer = null;
      console.log('HTTPS服务器已停止');
    }
  }

  /**
   * 移除客户端连接
   * @param clientSocket 客户端Socket连接
   * @param error 错误信息（可选）
   */
  protected removeTLSClient(clientSocket: socket.TLSSocketConnection, error?: BusinessError) {
    if (error) {
      console.error('客户端连接错误:', error);
    }
    const index = this.tlsClients.indexOf(clientSocket);
    if (index > -1) {
      this.tlsClients.splice(index, 1);
    }
  }

  /**
   * 处理TLS客户端连接
   * @param clientSocket TLS客户端连接
   */
  private handleTLSClient(clientSocket: socket.TLSSocketConnection) {
    this.tlsClients.push(clientSocket)
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

    clientSocket.on('error', (err) => this.removeTLSClient(clientSocket, err));
    clientSocket.on('close', () => this.removeTLSClient(clientSocket));
  }
}