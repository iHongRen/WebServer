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

// 定义请求处理函数类型
export type RequestHandler = (req: HttpRequest, res: HttpResponse) => void;

interface Route {
  method: string;
  path: string;
  handler: RequestHandler;
}

export class WebServer {
  private tcpServer: socket.TCPSocketServer | null = null;
  private clients: socket.TCPSocketConnection[] = [];
  private routes: Route[] = [];

  constructor() {
    // 默认404处理
    this.use((req, res) => {
      res.status(404).json({ error: 'Not Found', path: req.path });
    });
  }

  // 注册中间件或最终处理
  public use(handler: RequestHandler) {
    this.routes.push({ method: 'ANY', path: '*', handler });
  }

  public get(path: string, handler: RequestHandler) {
    this.addRoute('GET', path, handler);
  }

  public post(path: string, handler: RequestHandler) {
    this.addRoute('POST', path, handler);
  }

  public async startServer(port: number): Promise<ServerInfo> {
    try {
      this.tcpServer = socket.constructTCPSocketServerInstance();

      this.tcpServer.on('connect', (clientSocket: socket.TCPSocketConnection) => {
        this.clients.push(clientSocket);
        this.handleClient(clientSocket);
      });

      this.tcpServer.on('error', (error: BusinessError) => {
        console.error('服务器错误:', error);
      });

      const bindAddress: socket.NetAddress = { address: '0.0.0.0', port: port };
      await this.tcpServer.listen(bindAddress);

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

  private addRoute(method: string, path: string, handler: RequestHandler) {
    // 插入到默认404处理之前
    this.routes.splice(this.routes.length - 1, 0, { method, path, handler });
  }

  private handleClient(clientSocket: socket.TCPSocketConnection) {
    let receivedData = new ArrayBuffer(0);

    clientSocket.on('message', async (data: socket.SocketMessageInfo) => {
      receivedData = Utils.mergeArrayBuffers(receivedData, data.message);

      // 简单的HTTP请求完整性检查 (查找\r\n\r\n)
      // 注意：这仍然无法完美处理所有分块情况，但对多数请求有效
      const requestStr = Utils.arrayBufferToStr(receivedData);
      if (requestStr.includes('\r\n\r\n')) {
        const req = new HttpRequest(receivedData);
        const res = new HttpResponse(clientSocket);

        // 查找匹配的路由
        const route = this.routes.find(r =>
        (r.method === 'ANY' || r.method === req.method) &&
          (r.path === '*' || r.path === req.path)
        );

        if (route) {
          route.handler(req, res);
        } else {
          // 理论上不会执行到这里，因为有默认的404
          res.status(500).send('No handler found and no default 404.');
        }

        // 重置缓冲区以接收下一个请求 (在keep-alive连接中)
        receivedData = new ArrayBuffer(0);
      }
    });

    clientSocket.on('error', (error: BusinessError) => {
      console.error('客户端连接错误:', error);
      this.removeClient(clientSocket);
    });

    clientSocket.on('close', () => {
      console.log('客户端连接已关闭');
      this.removeClient(clientSocket);
    });
  }

  private removeClient(clientSocket: socket.TCPSocketConnection) {
    const index = this.clients.indexOf(clientSocket);
    if (index > -1) {
      this.clients.splice(index, 1);
    }
  }

  private getLocalIP(): string {
    try {
      const ipAddress = wifiManager.getIpInfo().ipAddress;
      const ip =
        (ipAddress >>> 24) + "." + (ipAddress >> 16 & 0xFF) + "." + (ipAddress >> 8 & 0xFF) + "." + (ipAddress & 0xFF);
      return ip
    } catch (e) {
      console.error("Get local IP failed", e);
      return '127.0.0.1';
    }
  }
}
