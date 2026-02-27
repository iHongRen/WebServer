/**
 * @fileName : StreamExample.ets
 * @author : @cxy
 * @date : 2025/12/31
 * @description : 流式传输示例 - 展示WebServer的流式传输功能
 */

import { HttpServer, HttpRequest, HttpResponse } from '@cxy/webserver';
import { socket } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

/**
 * 流式传输示例类
 */
export class StreamExample {
  private server: HttpServer | null = null;
  private context?: common.UIAbilityContext;

  init(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * 初始化服务器
   */
  public async initializeServer(): Promise<void> {
    this.server = new HttpServer();
    this.setupMiddleware();
    this.setupRoutes();
  }

  /**
   * 启动服务器
   */
  public async start(port: number): Promise<socket.NetAddress | null> {
    if (!this.server) {
      await this.initializeServer();
    }

    const info = await this.server?.startServer(port);
    if (info) {
      console.log('✅ 流式传输服务器启动成功!');
      console.log(`🌐 访问地址: http://${info.address}:${info.port}`);
      this.printApiEndpoints(info);
      return info;
    } else {
      console.error('❌ 启动服务器失败');
      return null;
    }
  }

  /**
   * 停止服务器
   */
  public async stop(): Promise<void> {
    if (this.server) {
      await this.server.stopServer();
    }
  }

  /**
   * 配置中间件
   */
  private setupMiddleware(): void {
    if (!this.server) {
      return;
    }

    // 日志中间件
    this.server.logger({
      format: 'dev',
      stream: (log: string) => {
        console.log(`📝 ${log}`);
      }
    });

    // CORS中间件
    this.server.cors();
  }

  /**
   * 配置路由
   */
  private setupRoutes(): void {
    if (!this.server) {
      return;
    }

    // 示例1：流式发送文本数据
    this.server.get('/api/stream/text', async (req: HttpRequest, res: HttpResponse) => {
      res.setHeader('Content-Type', 'text/plain; charset=utf-8');
      res.setHeader('Transfer-Encoding', 'chunked');

      // 模拟流式发送数据
      for (let i = 1; i <= 10; i++) {
        await res.write(`数据块 ${i}\n`);
        // 模拟延迟
        await this.sleep(500);
      }

      await res.end('流式传输完成\n');
    });

    // 示例2：流式发送JSON数据（Server-Sent Events风格）
    this.server.get('/api/stream/events', async (req: HttpRequest, res: HttpResponse) => {
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');

      // 发送事件流
      for (let i = 1; i <= 5; i++) {
        const eventData: Record<string, Object> = {
          'id': i,
          'message': `事件 ${i}`,
          'timestamp': Date.now()
        };
        const event = `data: ${JSON.stringify(eventData)}\n\n`;
        await res.write(event);
        await this.sleep(1000);
      }

      await res.end();
    });

    // 示例3：流式发送大量数据
    this.server.get('/api/stream/large', async (req: HttpRequest, res: HttpResponse) => {
      res.setHeader('Content-Type', 'text/plain; charset=utf-8');

      const chunkSize = 1024; // 1KB per chunk
      const totalChunks = 100; // 总共100KB

      for (let i = 0; i < totalChunks; i++) {
        // 生成1KB的数据
        const data = 'A'.repeat(chunkSize);
        await res.write(data);
        
        // 每10个块打印一次进度
        if ((i + 1) % 10 === 0) {
          console.log(`已发送: ${(i + 1) * chunkSize / 1024}KB`);
        }
      }

      await res.end('\n流式传输完成\n');
    });

    // 示例4：流式读取并发送文件
    this.server.get('/api/stream/file', async (req: HttpRequest, res: HttpResponse, next) => {
      try {
        // 这里使用一个示例文件路径，实际应用中应该从请求参数获取
        const filePath = `${this.context?.filesDir}/test-stream.txt`;

        // 检查文件是否存在
        const exists = await fileIo.access(filePath);
        if (!exists) {
          // 创建一个测试文件
          await this.createTestFile(filePath);
        }

        // 获取文件大小
        const stat = await fileIo.stat(filePath);
        
        res.setHeader('Content-Type', 'text/plain; charset=utf-8');
        res.setHeader('Content-Length', stat.size.toString());

        // 打开文件
        const file = await fileIo.open(filePath, fileIo.OpenMode.READ_ONLY);

        try {
          // 分块读取并发送文件
          const chunkSize = 4096; // 4KB per chunk
          let offset = 0;

          while (offset < stat.size) {
            const readSize = Math.min(chunkSize, stat.size - offset);
            const buffer = new ArrayBuffer(readSize);
            
            await fileIo.read(file.fd, buffer, { offset: offset });
            await res.write(buffer);
            
            offset += readSize;
          }

          await res.end();
        } finally {
          await fileIo.close(file.fd);
        }
      } catch (error) {
        console.error('流式文件传输失败:', error);
        next(error);
      }
    });

    // 示例5：实时日志流
    this.server.get('/api/stream/logs', async (req: HttpRequest, res: HttpResponse) => {
      res.setHeader('Content-Type', 'text/plain; charset=utf-8');
      res.setHeader('Transfer-Encoding', 'chunked');

      const logMessages = [
        '[INFO] 服务器启动',
        '[INFO] 加载配置文件',
        '[INFO] 连接数据库',
        '[WARN] 数据库连接缓慢',
        '[INFO] 数据库连接成功',
        '[INFO] 初始化路由',
        '[INFO] 启动HTTP服务器',
        '[INFO] 服务器就绪，监听端口 8080',
      ];

      for (const log of logMessages) {
        const timestamp = new Date().toISOString();
        await res.write(`[${timestamp}] ${log}\n`);
        await this.sleep(800);
      }

      await res.end('[INFO] 日志流结束\n');
    });

    // 示例6：进度报告
    this.server.get('/api/stream/progress', async (req: HttpRequest, res: HttpResponse) => {
      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Transfer-Encoding', 'chunked');

      const totalSteps = 10;
      
      for (let step = 1; step <= totalSteps; step++) {
        const progress: Record<string, Object> = {
          'step': step,
          'total': totalSteps,
          'percentage': (step / totalSteps * 100).toFixed(2),
          'message': `处理步骤 ${step}/${totalSteps}`,
          'timestamp': Date.now()
        };
        
        await res.write(JSON.stringify(progress) + '\n');
        await this.sleep(1000);
      }

      await res.end();
    });

    // 首页
    this.server.get('/', (req: HttpRequest, res: HttpResponse) => {
      res.json({
        message: '流式传输示例服务器',
        endpoints: [
          '/api/stream/text - 流式文本数据',
          '/api/stream/events - Server-Sent Events',
          '/api/stream/large - 大数据流',
          '/api/stream/file - 文件流',
          '/api/stream/logs - 实时日志流',
          '/api/stream/progress - 进度报告'
        ]
      } as ESObject);
    });
  }

  /**
   * 创建测试文件
   */
  private async createTestFile(filePath: string): Promise<void> {
    const content = '这是一个测试文件，用于演示流式文件传输。\n'.repeat(100);
    const file = await fileIo.open(filePath,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
    await fileIo.write(file.fd, content);
    await fileIo.close(file.fd);
  }

  /**
   * 延迟函数
   */
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * 打印API端点信息
   */
  private printApiEndpoints(info: socket.NetAddress): void {
    const baseUrl = `http://${info.address}:${info.port}`;

    console.log('\n📋 流式传输API端点:');
    console.log('='.repeat(50));

    console.log('\n🌊 流式传输示例:');
    console.log(`   GET    ${baseUrl}/                      - 首页`);
    console.log(`   GET    ${baseUrl}/api/stream/text       - 流式文本数据`);
    console.log(`   GET    ${baseUrl}/api/stream/events     - Server-Sent Events`);
    console.log(`   GET    ${baseUrl}/api/stream/large      - 大数据流`);
    console.log(`   GET    ${baseUrl}/api/stream/file       - 文件流`);
    console.log(`   GET    ${baseUrl}/api/stream/logs       - 实时日志流`);
    console.log(`   GET    ${baseUrl}/api/stream/progress   - 进度报告`);

    console.log('\n🚀 测试命令:');
    console.log(`   curl ${baseUrl}/api/stream/text`);
    console.log(`   curl ${baseUrl}/api/stream/events`);
    console.log('='.repeat(50));
  }
}
