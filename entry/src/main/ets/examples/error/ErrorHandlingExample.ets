/**
 * @fileName : ErrorHandlingExample.ets
 * @author : @cxy
 * @date : 2025/10/29
 * @description : 服务器错误处理示例
 */


import {
  ServerError,
  ServerEvent,
  ServerErrorType,
  ServerEventType,
  HttpServer,
  HttpRequest,
  HttpResponse
} from '@cxy/webserver';
import { socket } from '@kit.NetworkKit';

/**
 * 错误处理示例类
 */
export class ErrorHandlingExample {
  /**
   * 创建带有完整错误处理的HTTP服务器
   */
  public static async createServerWithErrorHandling(): Promise<HttpServer> {
    const server = new HttpServer();

    // 配置基本中间件
    server.logger();
    server.cors();
    server.json();

    // ==================== 错误事件监听 ====================

    // 监听所有错误事件
    server.onError((error: ServerError) => {
      console.error(`🚨 服务器错误 [${error.type}]:`, JSON.stringify(error.error));

      // 根据错误类型进行不同处理
      switch (error.type) {
        case ServerErrorType.STARTUP_FAILED:
          console.error('💥 服务器启动失败，请检查端口是否被占用');
          // 可以在这里实现重试逻辑或通知管理员
          break;

        case ServerErrorType.LISTEN_ERROR:
          console.error('🔌 端口监听失败，可能端口已被占用');
          // 可以尝试其他端口
          break;

        case ServerErrorType.CONNECTION_ERROR:
          console.error('🔗 连接错误，客户端连接异常');
          break;

        case ServerErrorType.CLIENT_ERROR:
          console.error('👤 客户端错误');
          break;

        case ServerErrorType.SOCKET_ERROR:
          console.error('🔌 Socket错误');
          break;

        default:
          console.error('❓ 未知错误类型');
      }
    });

    // ==================== 服务器事件监听 ====================

    // 监听服务器启动事件
    server.on(ServerEventType.SERVER_STARTED, (event: ServerEvent) => {
      console.log('🚀 服务器启动成功!');
      console.log('启动信息:', event.data);
      // 可以在这里发送启动通知、记录日志等
    });

    // 监听服务器停止事件
    server.on(ServerEventType.SERVER_STOPPED, (event: ServerEvent) => {
      console.log('🛑 服务器已停止');
      // 可以在这里进行清理工作、保存状态等
    });

    // 监听请求接收事件
    server.on(ServerEventType.REQUEST_RECEIVED, (event: ServerEvent) => {
      console.log(`📨 收到请求: ${event.type}`);
      // 可以在这里进行请求统计、限流等
    });

    // 监听响应发送事件
    server.on(ServerEventType.RESPONSE_SENT, (event: ServerEvent) => {
      console.log(`📤 响应已发送: ${JSON.stringify(event.data)}`);
      // 可以在这里进行响应统计、性能监控等
    });

    // ==================== 客户端连接事件监听 ====================

    // 监听客户端连接
    server.onClientConnect(async (client: socket.TCPSocketConnection | socket.TLSSocketConnection) => {
      const address = await client.getRemoteAddress()
      console.log(`👤 新客户端连接: ${client.clientId} ${address}`);
      console.log(`当前连接数: ${server.getClientCount()}`);

      // 可以在这里进行连接限制、IP白名单检查等
      if (server.getClientCount() > 100) {
        console.warn('⚠️  连接数过多，考虑限制新连接');
      }
    });

    // 监听客户端断开连接
    server.onClientDisconnect(async (client: socket.TCPSocketConnection | socket.TLSSocketConnection) => {
      const address = await client.getRemoteAddress()
      console.log(`👋 客户端断开连接: ${client.clientId} ${address}`);
      console.log(`当前连接数: ${server.getClientCount()}`);
    });

    // ==================== 配置路由 ====================
    ErrorHandlingExample.setupRoutes(server);

    return server;
  }

  /**
   * 启动带有错误处理的服务器示例
   */
  public static async startExample(): Promise<void> {
    try {
      const server = await ErrorHandlingExample.createServerWithErrorHandling();

      // 启动服务器
      const serverInfo = await server.startServer(8080);

      if (serverInfo.address) {
        console.log('✅ 服务器启动成功，错误处理系统已激活');
        console.log(`📋 测试端点:`);
        console.log(`   - GET  http://${serverInfo.address}:${serverInfo.port}/`);
        console.log(`   - GET  http://${serverInfo.address}:${serverInfo.port}/status`);
        console.log(`   - GET  http://${serverInfo.address}:${serverInfo.port}/error`);
        console.log(`   - POST http://${serverInfo.address}:${serverInfo.port}/disconnect/:clientId`);

        // 演示错误处理
        console.log('\n🧪 测试错误处理...');

        // 尝试在同一端口再次启动服务器（应该失败）
        setTimeout(async () => {
          console.log('尝试在同一端口再次启动服务器...');
          await server.startServer(8080);
        }, 2000);

      } else {
        console.error('❌ 服务器启动失败');
      }

    } catch (error) {
      console.error('创建服务器时发生错误:', error);
    }
  }

  /**
   * 演示高级错误处理功能
   */
  public static async demonstrateAdvancedErrorHandling(): Promise<void> {
    const server = new HttpServer();

    // 创建自定义错误处理器
    const errorHandler = (error: ServerError) => {
      // 记录到文件或发送到监控系统
      console.log('📝 记录错误日志:', JSON.stringify(error.error, null, 2));

      // 根据错误严重程度进行不同处理
      if (error.type === ServerErrorType.STARTUP_FAILED) {
        console.log('🔄 尝试自动恢复...');
        // 实现自动重启逻辑
      }
    };

    server.onError(errorHandler);

    // 演示移除监听器
    setTimeout(() => {
      console.log('🗑️  移除错误监听器');
      server.removeErrorListener(errorHandler);
    }, 10000);

    await server.startServer(8081);
  }

  /**
   * 配置测试路由
   */
  private static setupRoutes(server: HttpServer): void {
    // 首页
    server.get('/', (req: HttpRequest, res: HttpResponse) => {
      res.json({
        message: 'HTTP服务器运行正常',
        timestamp: new Date().toISOString(),
        clientCount: server.getClientCount(),
        serverRunning: server.isServerRunning()
      });
    });

    // 服务器状态端点
    server.get('/status', async (req: HttpRequest, res: HttpResponse) => {
      const clients = server.getClients().map(async client => {
        return {
          'id': client.clientId,
          'address': await client.getRemoteAddress(),
        } as Record<string, Object>
      });

      res.json({
        status: 'running',
        clientCount: server.getClientCount(),
        clients: clients,
        timestamp: new Date().toISOString()
      });
    });

    // 模拟错误的端点
    server.get('/error', (req: HttpRequest, res: HttpResponse) => {
      // 故意抛出错误来测试错误处理
      throw new Error('这是一个测试错误');
    });

    // 断开指定客户端连接
    server.post('/disconnect/:clientId', async (req: HttpRequest, res: HttpResponse) => {
      const clientId = Number(req.params['clientId']);
      const success = await server.disconnectClient(clientId);

      res.json({
        success,
        message: success ? `客户端 ${clientId} 已断开连接` : `客户端 ${clientId} 不存在或断开失败`
      });
    });
  }
}